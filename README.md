# AndroidCPU

A adb shell script that collect Android CPU usage

# Feature

Collect CPU Usage(usage/idle/other/user/sys) via /proc/stat

Output example:

```
17:36:48
%Usage %USR %SYS %Other %Idle
13.25 4.59 4.14 4.50 86.75
17:36:48
17:36:49
%Usage %USR %SYS %Other %Idle
31.69 15.15 14.06 2.46 68.31
```

# Usage

```
adb push * /data/local/tmp
source cpu_recorder.sh
cpu_recorder_test
```

