#!/bin/bash

# --- 配置路径 ---
# NPU
NPU_LOAD_FILE="/sys/kernel/debug/rknpu/load"
NPU_FREQ_FILE="/sys/class/devfreq/fdab0000.npu/cur_freq"

# GPU
GPU_FILE="/sys/class/devfreq/fb000000.gpu/load"

# RGA (视频处理)
RGA_LOAD_FILE="/sys/kernel/debug/rkrga/load"
CLK_SUMMARY_FILE="/sys/kernel/debug/clk/clk_summary"

# CPU
PROC_STAT_FILE="/proc/stat"
CPU_FREQ_BASE_PATH="/sys/devices/system/cpu"


# --- 全局变量定义 (用于存储各设备状态) ---
# NPU
NPU_CORE0_LOAD=0
NPU_CORE1_LOAD=0
NPU_CORE2_LOAD=0
NPU_FREQ="N/A"
NPU_TEMP=0

# GPU
GPU_LOAD=0
GPU_FREQ="N/A"
GPU_TEMP=0

# RGA
RGA_LOAD0=0
RGA_LOAD1=0
RGA_LOAD2=0
RGA_FREQ0="N/A"
RGA_FREQ1="N/A"
RGA_FREQ2="N/A"

# CPU (使用数组以支持动态核心数，但放置位置模仿原始脚本全局变量区)
declare -a CPU_LOAD
declare -a CPU_FREQ
declare -a CPU_PREV_TOTAL
declare -a CPU_PREV_IDLE
CPU_CORE_COUNT=0
CPU_FIRST_RUN=1
SOC_TEMP=0
LITTLE_CORE_TEMP=0
BIG_CORE0_TEMP=0
BIG_CORE1_TEMP=0

# --- 权限检查与自动提权 ---
# 如果脚本不是以 root 身份运行，则使用 sudo 重新执行自身
if [ "$(id -u)" -ne 0 ]; then
    echo "此脚本需要 root 权限来读取 debugfs 信息。正在请求权限..."
    # exec 命令会替换当前 shell 进程，这样在 sudo 完成后脚本就不会继续执行
    exec sudo "$0" "$@"
fi



# ---文件检查 ---
if [[ ! -f "$NPU_LOAD_FILE" ]]; then echo "警告：找不到 NPU load 文件"; fi
if [[ ! -f "$NPU_FREQ_FILE" ]]; then echo "警告：找不到 NPU freq 文件"; fi

if [[ ! -f "$GPU_FILE" ]]; then echo "警告：找不到 GPU load 文件"; fi

if [[ ! -f "$RGA_LOAD_FILE" ]]; then echo "警告：找不到 RGA load 文件"; fi
if [[ ! -f "$CLK_SUMMARY_FILE" ]]; then echo "警告：找不到 RGA clk_summary 文件"; fi

if [[ ! -f "$PROC_STAT_FILE" ]]; then echo "警告：找不到 $PROC_STAT_FILE 文件"; fi



# === 自适应配置 ===
# 进度条最小宽度（终端过窄时的保底值）
BAR_WIDTH_BASE=5
# 进度条最大宽度（避免窗口过大时进度条太长）
BAR_WIDTH_MAX=40
# 预留边距：标签+分隔符+百分比+频率等约需30字符
LAYOUT_MARGIN=65
# 刷新时间 (秒)
REFRESH_TIME=0.5


# 动态计算 BAR_WIDTH
calc_bar_width() {
    local term_width=80
    local cols

    # 获取终端宽度
    if cols=$(tput cols 2>/dev/null); then
        term_width=$cols
    elif [[ -n "$COLUMNS" ]]; then
        term_width=$COLUMNS
    fi


    # 双列布局时，每列可用宽度 = (总宽 - 边距) / 2
    local available=$(( (term_width - LAYOUT_MARGIN) / 2 ))
    # 限制范围
    if (( available < BAR_WIDTH_BASE )); then
        BAR_WIDTH=$BAR_WIDTH_BASE
    elif (( available > BAR_WIDTH_MAX )); then
        BAR_WIDTH=$BAR_WIDTH_MAX
    else
        BAR_WIDTH=$available
    fi
}


# --- 功能函数 ---

# 绘制进度条函数
draw_bar() {
    local percent=$1
    if ! [[ "$percent" =~ ^[0-9]+$ ]]; then
        percent=0;
    fi

    local filled=$((percent * BAR_WIDTH / 100))

    # 如果百分比 > 2 但计算结果为 0，则强制显示 1 格
    if (( percent > 0 && filled == 0 )); then
        filled=1
    fi

    local empty=$((BAR_WIDTH - filled))

    # 颜色定义
    local GREEN='\033[32m'
    local YELLOW='\033[33m'
    local RED='\033[31m'
    local CYAN='\033[36m'
    local NC='\033[0m'

    if (( percent > 80 )); then 
        COLOR=$RED
    elif (( percent > 50 )); then 
        COLOR=$YELLOW
    else 
        COLOR=$GREEN
    fi

    local i

    printf "${CYAN}[${COLOR}"
    for ((i=0; i<filled; i++)); do
        printf "|";
    done

    for ((i=0; i<empty; i++)); do
        printf " ";
    done

    printf "${CYAN}]${NC}"
}


# --- 设备查询函数 ---

# 1. 查询 NPU 状态 (负载与频率)
query_npu_status() {
    if [[ -f "$NPU_LOAD_FILE" ]]; then
        # 解析负载 (Core0, Core1, Core2)
        read -r NPU_CORE0_LOAD NPU_CORE1_LOAD NPU_CORE2_LOAD <<< $(awk '{gsub(/%|,/,""); print $4, $6, $8}' "$NPU_LOAD_FILE" 2>/dev/null)
    else
        NPU_CORE0_LOAD=0; NPU_CORE1_LOAD=0; NPU_CORE2_LOAD=0
    fi

    # 解析频率
    if [[ -f "$NPU_FREQ_FILE" ]]; then
        NPU_FREQ=$(awk '{printf "%.2f", $1/1000000000}' "$NPU_FREQ_FILE" 2>/dev/null)
    else
        NPU_FREQ="N/A"
    fi
}

# 2. 查询 GPU 状态 (负载与频率)
query_gpu_status() {
    if [[ -f "$GPU_FILE" ]]; then
        # GPU 文件格式通常为 "Load@FreqHz"，例如 "120@800000000"
        read -r GPU_LOAD GPU_FREQ <<< $(cat "$GPU_FILE" | awk -F'@' '{gsub(/Hz/, "", $2); printf "%d %.2f", $1, $2/1000000000}')
    else
        GPU_LOAD=0
        GPU_FREQ="N/A"
    fi
}

# 3. 查询 RGA 状态 (负载与频率)
query_rga_status() {
    # 3.1 解析负载
    if [[ -f "$RGA_LOAD_FILE" ]]; then
        # 匹配 load = 后面是数字的行, 使用数组 () 接收多行输出：
        local rga_loads=( $(cat "$RGA_LOAD_FILE" | awk '/load = [0-9]/ {print $3}' | tr -d '%') )

        # 【修复点】安全取值，带默认值
        RGA_LOAD0=${rga_loads[0]:-0}
        RGA_LOAD1=${rga_loads[1]:-0}
        RGA_LOAD2=${rga_loads[2]:-0}
    else
        RGA_LOAD0=0; RGA_LOAD1=0; RGA_LOAD2=0
    fi

    # 【修复点】二次校验确保是纯数字
    [[ "$RGA_LOAD0" =~ ^[0-9]+$ ]] || RGA_LOAD0=0
    [[ "$RGA_LOAD1" =~ ^[0-9]+$ ]] || RGA_LOAD1=0
    [[ "$RGA_LOAD2" =~ ^[0-9]+$ ]] || RGA_LOAD2=0

    # 3.2 解析频率
    local clk_data=$(cat /sys/kernel/debug/clk/clk_summary | grep rga)

    RGA_FREQ0=$(echo "$clk_data" | awk '$1 == "clk_rga3_0_core" {printf "%.2f", $5/1000000000}')
    RGA_FREQ1=$(echo "$clk_data" | awk '$1 == "clk_rga3_1_core" {printf "%.2f", $5/1000000000}')
    RGA_FREQ2=$(echo "$clk_data" | awk '$1 == "clk_rga2_core" {printf "%.2f", $5/1000000000}')
}

# 4. 查询 CPU 状态 (负载与频率)
query_cpu_status() {
    # 4.1 检测核心数量
    CPU_CORE_COUNT=$(grep -c "^cpu[0-9]" "$PROC_STAT_FILE")

    # 4.2 读取当前统计信息
    local idx=0
    while read -r line; do
        # 跳过聚合行 "cpu " (注意 cpu 后面有空格)
        if [[ "$line" =~ ^cpu[0-9]+ ]]; then
            # 解析字段：user nice system idle iowait irq softirq steal ...
            read -r _ user nice system idle iowait irq softirq steal _ <<< "$line"

            # 计算 Total 和 Idle
            local curr_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
            local curr_idle=$((idle + iowait))

            # 计算使用率 (需要上一次的数据)
            if [[ $CPU_FIRST_RUN -eq 1 ]]; then
                CPU_LOAD[$idx]=0
            else
                local diff_total=$((curr_total - CPU_PREV_TOTAL[$idx]))
                local diff_idle=$((curr_idle - CPU_PREV_IDLE[$idx]))

                if [[ $diff_total -gt 0 ]]; then
                    CPU_LOAD[$idx]=$(( (diff_total - diff_idle) * 100 / diff_total ))
                else
                    CPU_LOAD[$idx]=0
                fi
            fi

            # 保存当前状态为下一次做准备
            CPU_PREV_TOTAL[$idx]=$curr_total
            CPU_PREV_IDLE[$idx]=$curr_idle

            # 4.3 读取频率
            local freq_file="$CPU_FREQ_BASE_PATH/cpu${idx}/cpufreq/scaling_cur_freq"
            if [[ -f "$freq_file" ]]; then
                local freq_khz=$(cat "$freq_file" 2>/dev/null)
                CPU_FREQ[$idx]=$(awk "BEGIN {printf \"%.4f\", $freq_khz/1000000}")
            else
                CPU_FREQ[$idx]="N/A"
            fi

            ((idx++))
        fi
    done < "$PROC_STAT_FILE"

    CPU_FIRST_RUN=0
}

display_cpu_status() {
    if [[ $CPU_CORE_COUNT -gt 0 ]]; then
        # 计算分列点，左半部分和右半部分
        half=$(( (CPU_CORE_COUNT + 1) / 2 ))

        for ((i=0; i<half; i++)); do
            left_idx=$i
            right_idx=$((i + half))

            # 构建左侧字符串
            left_load=${CPU_LOAD[$left_idx]:-0}
            left_freq=${CPU_FREQ[$left_idx]:-"N/A"}
            printf "  CPU%-2d: " "$left_idx"
            draw_bar "$left_load"
            printf " %3d%% @ %s GHz" "$left_load" "$left_freq"

            # 制表符间隔
            printf "\t"

            # 构建右侧字符串 (如果存在)
            if [[ $right_idx -lt $CPU_CORE_COUNT ]]; then
                right_load=${CPU_LOAD[$right_idx]:-0}
                right_freq=${CPU_FREQ[$right_idx]:-"N/A"}
                printf "CPU%-2d: " "$right_idx"
                draw_bar "$right_load"
                printf " %3d%% @ %s GHz" "$right_load" "$right_freq"
            fi
            printf "\n"

        done
    fi
}

# 5. 查询温度
query_temperature() {
    local sensors_output
    sensors_output=$(sensors)

    SOC_TEMP=$(echo "$sensors_output" | awk '/^soc_thermal/{getline; getline; print $2}')
    LITTLE_CORE_TEMP=$(echo "$sensors_output" | awk '/^littlecore_thermal/{getline; getline; print $2}')
    BIG_CORE0_TEMP=$(echo "$sensors_output" | awk '/^bigcore0_thermal/{getline; getline; print $2}')
    BIG_CORE1_TEMP=$(echo "$sensors_output" | awk '/^bigcore1_thermal/{getline; getline; print $2}')

    NPU_TEMP=$(echo "$sensors_output" | awk '/^npu_thermal/{getline; getline; print $2}')
    GPU_TEMP=$(echo "$sensors_output" | awk '/^gpu_thermal/{getline; getline; print $2}')
}





# 定义清屏重绘函数
redraw_screen() {
    clear  # 清屏
    tput cup 0 0  # 将光标移回左上角

    calc_bar_width
}

# 捕获 SIGWINCH 信号，窗口大小变化时调用 redraw_screen 函数
trap redraw_screen SIGWINCH

# 初始化终端
tput civis
trap 'tput cnorm; exit' INT EXIT

# --- 主循环 ---
redraw_screen
while true; do
    tput cup 0 0

    # 1. 执行各设备查询函数
    query_npu_status
    query_gpu_status
    query_rga_status
    query_cpu_status

    query_temperature

    # 2. 绘制界面
    echo -e " Rockchip Monitor (Refresh: "$REFRESH_TIME"s)\t\tTime: $(date +"%H:%M:%S")"
    echo -e "--------------------"

    # --- CPU 区域 (平均分成两列，制表符间隔) ---
    echo -e " CPU Status:"
    display_cpu_status
    printf "  SOC temperature: %s \n"  "$SOC_TEMP"
    printf "  Little cores temperature: %s \n"  "$LITTLE_CORE_TEMP"
    printf "  Big core0 temperature: %s \t Big core1 temperature: %s \n"  "$BIG_CORE0_TEMP" "$BIG_CORE1_TEMP"
    echo -e ""

    # --- NPU 区域 ---
    echo -e " NPU Status:"
    printf "  Core0: "; draw_bar "$NPU_CORE0_LOAD"; printf " %3d%% @ %s GHz\n" "$NPU_CORE0_LOAD" "${NPU_FREQ}"
    printf "  Core1: "; draw_bar "$NPU_CORE1_LOAD"; printf " %3d%% @ %s GHz\n" "$NPU_CORE1_LOAD" "${NPU_FREQ}"
    printf "  Core2: "; draw_bar "$NPU_CORE2_LOAD"; printf " %3d%% @ %s GHz\n" "$NPU_CORE2_LOAD" "${NPU_FREQ}"
    printf "  NPU temperature: %s \n"  "$NPU_TEMP"
    echo -e ""

    # --- GPU 区域 ---
    echo -e " GPU Status:"
    printf "  Util : "; draw_bar "$GPU_LOAD"; printf " %3d%% @ %s GHz\n" "$GPU_LOAD" "$GPU_FREQ"
    printf "  GPU temperature: %s \n"  "$GPU_TEMP"
    echo -e ""

    # --- RGA 区域 ---
    echo -e " RGA Status (Video Proc):"
    printf "  RGA3_0: "; draw_bar "$RGA_LOAD0"; printf " %3d%% @ %s GHz\n" "$RGA_LOAD0" "${RGA_FREQ0:-N/A}"
    printf "  RGA3_1: "; draw_bar "$RGA_LOAD1"; printf " %3d%% @ %s GHz\n" "$RGA_LOAD1" "${RGA_FREQ1:-N/A}"
    printf "  RGA2  : "; draw_bar "$RGA_LOAD2"; printf " %3d%% @ %s GHz\n" "$RGA_LOAD2" "${RGA_FREQ2:-N/A}"

    echo -e "--------------------"
    echo -e " Press Ctrl+C to exit..."

    sleep $REFRESH_TIME
done
