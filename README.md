# rktop
一个轻量级的 Bash Shell 脚本，即下载即用，用于实时监控基于 Rockchip 芯片（特别是 RK3588 系列）的开发板硬件状态喵。<br>
是叶姐姐🍃在Rockchip平台调试Focus-Finder项目时用氛围编程写的。

## ✨ 功能特性

- **实时监控**：刷新率可配置，默认 0.5 秒。
- **多维度数据**：
  - **CPU**: 每核心的负载率、频率及大小核温度。
  - **NPU**: 多核心负载、频率及温度。
  - **GPU**: 负载率、频率及温度。
  - **RGA**: 视频处理单元负载及频率。
- **可视化进度条**：根据负载率自动变色（绿/黄/红）。
- **自动提权**：脚本会自动请求 `sudo` 权限以读取底层硬件信息。
- **纯净界面**：基于 TUI (Text User Interface)，无图形界面依赖。

## 📸 效果预览
  ```text
  Rockchip Monitor (Refresh: 0.5s)             Time: 11:45:14
  --------------------
  CPU Status:
  CPU0  : [||||||||||||            ]  45% @ 1.800 GHz    CPU4  : [||||||||||              ]  38% @ 2.200 GHz
  CPU1  : [||||||||||              ]  38% @ 1.800 GHz    CPU5  : [||||||||||              ]  38% @ 2.200 GHz
  CPU2  : [||||||||||||||          ]  52% @ 1.800 GHz    CPU6  : [|||||                   ]  20% @ 2.200 GHz
  CPU3  : [|||||                   ]  20% @ 1.800 GHz    CPU7  : [||||||||||||            ]  45% @ 2.200 GHz
  SOC temperature: +42.0°C 
  Little cores temperature: +40.0°C 
  Big core0 temperature: +45.0°C    Big core1 temperature: +46.0°C 
  
  NPU Status:
  Core0: [|||||||||||||||||||||||| ]  92% @ 1.00 GHz
  Core1: [||||||||                 ]  30% @ 1.00 GHz
  Core2: [                         ]   0% @ 0.00 GHz
  NPU temperature: +48.0°C 
  
  GPU Status:
  Util : [||||||||                 ]  28% @ 0.30 GHz
  GPU temperature: +44.0°C

  RGA Status:
  RGA3_0: [                         ]   0% @ 0.75 GHz
  RGA3_1: [                         ]   0% @ 0.75 GHz
  RGA2:   [                         ]   0% @ 0.75 GHz
  --------------------
  ```

## 📋 系统要求

- **硬件**: 基于 Rockchip SoC 的开发板或设备 (如 Orange Pi 5, Radxa Rock 5 等)。
- **系统**: Linux (ARM64 架构)。
- **权限**: 需要 Root 权限 (脚本会自动请求)。
- **依赖**:
  - `bash`
  - `lm-sensors` (用于读取温度信息，请确保已安装并配置)

## 🚀 使用方法

1. **下载脚本以及安装传感器库**
   ```bash
   wget https://github.com/YeWenxuan64/rktop/blob/main/rktop.sh

   sudo apt update
   sudo apt install lm-sensors
   ```

2. **赋予执行权限**
   ```bash
   chmod +x rktop.sh
   ```
   或在桌面环境里对文件右键，查看“属性”，再在“权限”里设置可执行
   
4. **运行脚本**
   ```bash
   ./rktop.sh
   # 或 sudo ./rktop.sh
   ```
   
5. **输入root密码**<br>
  由于查询使用率/频率时，需要查询部分系统的文件，所以不得不以sudo运行捏~

6. **退出**<br>
  按 Ctrl + C 退出

## ⚙️ 配置说明
  你可以直接修改脚本头部的变量来调整显示效果：
  ```bash
  # 进度条宽度
  BAR_WIDTH=25
  
  # 刷新时间 (秒)
  REFRESH_TIME=0.5
  ```
## ⚠️ 已知缺陷与待办
  项目目前处于初期版本，存在以下局限，欢迎贡献代码：
  
  内存监控缺失：<br>
  目前尚未加入内存使用率（RAM）的实时监控功能，计划在未来版本中添加。<br>
  
  错误处理机制简单：<br>
  对于非标准系统环境或文件路径缺失的情况，错误提示较为基础。<br>
  当解析内核调试文件失败时，可能会出现显示错位，尚未做完善的异常捕获。<br>
  
  兼容性有限：<br>
  硬编码了部分 RK3588 的寄存器路径 (如fdab0000.npu, fb000000.gpu 等)，可能在其他 Rockchip 芯片（如 RK3566/RK3576）上无法直接运行。

## 🔧关键查询命令
  ```bash
  # CPU load (需要根据时间计算)
  $ cat /proc/stat

  # 输出内容大致为 CPU 使用率、中断、上下文切换等系统级别的统计信息
  cpu  7850 0 2276 29032 524 0 54 0 0 0
  cpu0 891 0 382 3570 41 0 46 0 0 0
  cpu1 920 0 280 3726 34 0 2 0 0 0
  cpu2 948 0 269 3702 43 0 2 0 0 0
  cpu3 948 0 237 3746 30 0 1 0 0 0
  cpu4 966 0 316 3624 77 0 0 0 0 0
  cpu5 1046 0 361 3442 131 0 0 0 0 0
  cpu6 1125 0 189 3569 87 0 0 0 0 0
  cpu7 1002 0 238 3649 78 0 0 0 0 0
  intr 266997 0 19407 152304 0 0 1901 1224 0 0 0 0 0 0 46113 1758 0 0 0 0 0 0 0 0 0 0 1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1824 0 0 0 0 1221 628 0 0 0 0 0 0 96 145 12948 1 0 0 1194 58 262 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 15 13 0 8943 16940
  ctxt 471681
  btime 1773649958
  processes 2511
  procs_running 8
  procs_blocked 0
  softirq 113012 98 6695 2 431 16138 0 13198 15300 0 61150
  ```

  ```bash
  # CPU freq
  $ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq (or cpu1, cpu2 etc)

  # 输出内容为指定逻辑cpu核心的频率, 单位为khz
  1800000
  ```

  ```bash
  # GPU load
  $ cat /sys/class/devfreq/fb000000.gpu/load

  # 输出内容为Panfrost/Panthor驱动下的GPU使用率以及频率
  22@300000000Hz
  ```

  ```bash
  # GPU freq
  $ cat /sys/class/devfreq/fb000000.gpu/cur_freq

  # 输出内容为Panfrost/Panthor驱动下的GPU频率, 单位为hz
  300000000
  ```

  ```bash
  # NPU load
  $ sudo cat /sys/kernel/debug/rknpu/load

  # 输出内容为三个NPU的使用率 (rk3588)
  NPU load:  Core0:  0%, Core1:  0%, Core2:  0%,
  ```

  ```bash
  # NPU freq
  $ cat /sys/class/devfreq/fdab0000.npu/cur_freq

  # 输出内容为三个NPU共用的频率 (rk3588)
  1000000000
  ```

  ```bash
  # RGA load
  $ sudo cat /sys/kernel/debug/rkrga/load

  # 输出内容为rag调度器的数量, 和调度器的使用率
  num of scheduler = 3
  ================= load ==================
  scheduler[0]: rga3
           load = 3%
  -----------------------------------
  scheduler[1]: rga3
           load = 0%
  -----------------------------------
  scheduler[2]: rga2
           load = 0%
  -----------------------------------
  =========================================
  <session>  <status>  <tgid>  <process>
  9          active    1186240  ffmpeg -y -init_hw_device rkmpp=hw -filter_hw_device hw -f x11grab -video_size 1920x1080 -framerate 30 -i :0.0 -vf hwupload,scale_rkrga=format=nv12 -c:v hevc_rkmpp -b:v 6144k -maxrate 16384k ./output.mp4
  ```


  ```bash
  # RGA freq (需要挑选(虽然小女子也不知道选哪一个, 就随便选了三个))
  $ sudo cat /sys/kernel/debug/clk/clk_summary | grep rga

  # 输出内容为rag相关的时钟
        hclk_rga3_0           0        4        0   198000000          0     0  50000         N
        hclk_rga2             0        2        0   198000000          0     0  50000         N
     hclk_rga3_root           0        1        0   198000000          0     0  50000         N
        hclk_rga3_1           0        4        0   198000000          0     0  50000         N
  clk_rga3_0_core             0        1        0   750000000          0     0  50000         N
  clk_rga2_core               0        1        0   750000000          0     0  50000         N
     aclk_rga3_0              0        4        0   750000000          0     0  50000         N
     aclk_rga2                0        2        0   750000000          0     0  50000         N
  aclk_rga3_root              0        1        0   750000000          0     0  50000         N
     aclk_rga3_1              0        4        0   750000000          0     0  50000         N
  clk_rga3_1_core             0        1        0   750000000          0     0  50000         N
  ```

  ```bash
  # TEMP
  $ sensors

  # 输出内容为lm-sensors能读取的的设备名称与温度
  npu_thermal-virtual-0
  Adapter: Virtual device
  temp1:        +45.3°C  (crit = +115.0°C)
  
  center_thermal-virtual-0
  Adapter: Virtual device
  temp1:        +46.2°C  (crit = +115.0°C)
  
  bigcore1_thermal-virtual-0
  Adapter: Virtual device
  temp1:        +46.2°C  (crit = +115.0°C)
  
  soc_thermal-virtual-0
  Adapter: Virtual device
  temp1:        +46.2°C  (crit = +115.0°C)
  
  gpu_thermal-virtual-0
  Adapter: Virtual device
  temp1:        +45.3°C  (crit = +115.0°C)
  
  littlecore_thermal-virtual-0
  Adapter: Virtual device
  temp1:        +46.2°C  (crit = +115.0°C)
  
  bigcore0_thermal-virtual-0
  Adapter: Virtual device
  temp1:        +46.2°C  (crit = +115.0°C)
  ```


## 📝 许可证
本项目采用 MIT 许可证。
欢迎 Issue 和 Pull Request。
