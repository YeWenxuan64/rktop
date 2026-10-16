# rktop
![madewithlove](https://img.shields.io/badge/made_with-%E2%9D%A4-red?style=for-the-badge&labelColor=pink)

[![No Compile](https://img.shields.io/badge/build-no%20compile-brightgreen)](https://github.com/YeWenxuan64/rktop)
[![Language](https://img.shields.io/badge/language-Bash-brightgreen)](https://github.com/YeWenxuan64/rktop)
[![Zero Dependencies](https://img.shields.io/badge/dependencies-zero-brightgreen)](https://github.com/YeWenxuan64/rktop)
[![Platform](https://img.shields.io/badge/platform-Linux%20ARM64-orange)](https://github.com/YeWenxuan64/rktop)
[![Code Size](https://img.shields.io/github/size/YeWenxuan64/rktop/rktop.sh?color=violet)](https://github.com/YeWenxuan64/rktop/blob/main/rktop.sh)
[![License](https://img.shields.io/badge/license-MIT-blue)](https://github.com/YeWenxuan64/rktop/blob/main/LICENSE)

[Readme_CN](./README.md)

A lightweight Bash shell script that works right out of the box — download and run — for real-time monitoring of the hardware status of development boards based on Rockchip chips (especially the RK3588 series)~<br>
It was vibe-coded by Miss Ye🍃 while debugging the [Focus-Finder](https://github.com/YeWenxuan64/Focus-Finder) project on the Rockchip platform.

## ✨ Features

- **Real-time monitoring**: Configurable refresh rate, defaulting to 0.5 seconds.
- **Multi-dimensional data**:
  - **CPU**: Per-core load, frequency, and big/little core temperatures.
  - **MEM**: Memory and swap partition usage.
  - **NPU**: Multi-core load, frequency, and temperature.
  - **GPU**: Load, frequency, and temperature.
  - **RGA**: Video processing unit load and frequency.
- **Visual progress bars**: Automatically change color based on load (green/yellow/red).
- **Automatic privilege escalation**: The script automatically requests `sudo` privileges to read low-level hardware information.
- **No compilation required**: A pure Bash script that runs without any compilation.
- **Clean interface**: Based on a TUI (Text User Interface), with no GUI dependencies.

## 📸 Preview
```text
Rockchip Monitor (Refresh: 0.5s)             Time: 11:45:14
--------------------
CPU Status:
   0[||||||||||||            ] 45% 1800MHz  4[||||||||||              ] 38% 2200MHz
   1[||||||||||              ] 38% 1800MHz  5[||||||||||              ] 38% 2200MHz
   2[||||||||||||||          ] 52% 1800MHz  6[|||||                   ] 20% 2200MHz
   3[|||||                   ] 20% 1800MHz  7[||||||||||||            ] 45% 2200MHz
SOC temperature: +42.0°C 
Little cores temperature: +40.0°C 
Big core0 temperature: +45.0°C    Big core1 temperature: +46.0°C 

Memory Status:
 Ram[||||||||||||||||||||||||||||||||||            ]  75%  2.8G/3.8G
 Swp[|||||||                                       ]  16%  0.3G/2.0G

NPU Status:
   0[|||||||||||||||||||||||| ]  92% @ 1.00 GHz
   1[||||||||                 ]  30% @ 1.00 GHz
   2[                         ]   0% @ 0.00 GHz
 NPU temperature: +48.0°C 

GPU Status:
 Gpu[||||||||                 ]  28% @ 0.30 GHz
GPU temperature: +44.0°C

RGA Status:
 3_0[                         ]   0% @ 0.75 GHz
 3_1[                         ]   0% @ 0.75 GHz
   2[                         ]   0% @ 0.75 GHz
--------------------
```

## 📋 System Requirements
- **Hardware**: A development board or device based on a Rockchip SoC (e.g. Orange Pi 5, Radxa Rock 5, etc.).
- **System**: Linux (ARM64 architecture).
- **Privileges**: Root privileges are required (the script will request them automatically).
- **Dependencies**:
  - `bash`
  - `lm-sensors` (used to read temperature information, optional)

## 🚀 Usage

1. **Download the script and install the sensor library**
```bash
wget https://github.com/YeWenxuan64/rktop/blob/main/rktop.sh

sudo apt update
sudo apt install lm-sensors
```

2. **Grant execute permission**
```bash
chmod +x rktop.sh
```
Or, in a desktop environment, right-click the file, open "Properties", and set it as executable under "Permissions"
   
4. **Run the script**
```bash
./rktop.sh # then enter your sudo password
# or sudo ./rktop.sh
```
   
5. **Enter the root password**<br>
Since querying usage/frequency requires reading some system files, the script has no choice but to run with sudo~

6. **Exit**<br>
Press Ctrl + C to exit

## ⚙️ Configuration
You can directly modify the variables at the top of the script to adjust the display:
```bash
# Progress bar width
BAR_WIDTH=25

# Refresh time (seconds)
REFRESH_TIME=0.5
```

You can also modify the file path variables at the top of the script to fit your chip/system environment:
```bash
# NPU
NPU_LOAD_FILE="/sys/kernel/debug/rknpu/load"
NPU_FREQ_FILE="/sys/class/devfreq/fdab0000.npu/cur_freq"

# GPU
GPU_FILE="/sys/class/devfreq/fb000000.gpu/load"

# RGA
...

# CPU
...
```
## 🛠️ Error Handling

On startup, the script checks whether all hardware information files exist. If any are missing, it prints a warning and pauses for 1 second, but it **will not prevent the script from running**. The corresponding module for a missing file will display `[ N/A ]` for its usage and `N/A` for its frequency, as follows:

- **Missing file warning**: On startup, the terminal prints a message such as `Warning: NPU load file: /sys/kernel/debug/rknpu/load not found`.
- **Usage is N/A**: The progress bar position for the corresponding module shows `[ N/A ]` instead of a normal progress bar.
- **Frequency is N/A**: The frequency value for the corresponding module shows `N/A`.
- **Missing temperature**: Temperature data depends on `lm-sensors`. If it is not installed, the sensor is unavailable, or the keyword cannot be read, the temperature line will not be displayed.

> Common causes: different Rockchip chips have different paths, the corresponding kernel driver names differ, `debugfs` is not mounted, `lm-sensors` is not installed, and so on.

## ⚠️ Known Limitations and TODO
The project is currently in its early version and has the following limitations. Feel free to open issues or contribute code:

### Todo
- [x] **Missing memory monitoring**: Added real-time monitoring of memory usage (RAM).<br>
  > ✅ Done — RAM and Swap usage display is now supported.

- [ ] **Simple error handling mechanism**:<br>
  For non-standard system environments or missing file paths, the error messages are rather basic.

- [x] **Limited compatibility**:<br>
  Some RK3588 register paths are hardcoded (e.g. `fdab0000.npu`, `fb000000.gpu`, etc.), which may not be directly readable on other Rockchip chips (such as RK3566/RK3576).
  > ✅ Done — searching for `*.npu` and `*.gpu` files is now supported.

---

## 🔧 Key Query Commands
```bash
# CPU load (needs to be calculated over time)
$ cat /proc/stat

# The output is roughly system-level statistics such as CPU usage, interrupts, and context switches
cpu  7850 0 2276 29032 524 0 54 0 0 0
cpu0 891 0 382 3570 41 0 46 0 0 0
cpu1 920 0 280 3726 34 0 2 0 0 0
cpu2 948 0 269 3702 43 0 2 0 0 0
cpu3 948 0 237 3746 30 0 1 0 0 0
cpu4 966 0 316 3624 77 0 0 0 0 0
cpu5 1046 0 361 3442 131 0 0 0 0 0
cpu6 1125 0 189 3569 87 0 0 0 0 0
cpu7 1002 0 238 3649 78 0 0 0 0 0
intr 266997 0 19407 152304 0 0 1901 1224 0 0 0 0 0 0 46113 1758 0 0 0 0 0 0 0 0 0 0 1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1824 0 0 0 0 1221 628 0 0 0 0 0 0 96 145 12948 1 0 0 1194 58 262 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 15 13 0 8943 16940
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

# The output is the frequency of the specified logical CPU core, in khz
1800000
```

```bash
# MEM usage
$ free

# The output is the memory usage
               total        used        free      shared  buff/cache   available
Mem:         4013664     1678136     1685028      318996     1035700     2335528
Swap:        2006828           0     2006828

```

```bash
# GPU load
$ cat /sys/class/devfreq/fb000000.gpu/load

# The output is the GPU usage and frequency under the Panfrost/Panthor driver
22@300000000Hz
```

```bash
# GPU freq
$ cat /sys/class/devfreq/fb000000.gpu/cur_freq

# The output is the GPU frequency under the Panfrost/Panthor driver, in hz
300000000
```

```bash
# NPU load
$ sudo cat /sys/kernel/debug/rknpu/load

# The output is the usage of the three NPUs (rk3588)
NPU load:  Core0:  0%, Core1:  0%, Core2:  0%,
```

```bash
# NPU freq
$ cat /sys/class/devfreq/fdab0000.npu/cur_freq

# The output is the frequency shared by the three NPUs (rk3588)
1000000000
```

```bash
# RGA load
$ sudo cat /sys/kernel/debug/rkrga/load

# The output is the number of rga schedulers and the usage of each scheduler
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
# RGA freq (needs to be picked out (although this humble maiden doesn't know which one to pick either, so she just picked three at random))
$ sudo cat /sys/kernel/debug/clk/clk_summary | grep rga

# The output is the rga-related clocks
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

# The output is the device names and temperatures that lm-sensors can read
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

---

## 📝 License
This project is licensed under the [MIT](./LICENSE) License.<br>
Issues and Pull Requests are welcome.
