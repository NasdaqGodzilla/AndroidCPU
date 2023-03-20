#!/bin/bash

# stats: Multiple stats from /proc/stat
# stat: One of the line of stats
# cpustat: The CPU line of /proc/stat
# cpuNstat: The number N of CPU core from /proc/stat

[[ "" == "$CPU_STAT_USER" ]] && \
    readonly CPU_STAT_USER=2

[[ "" == "$CPU_STAT_NICE" ]] && \
    readonly CPU_STAT_NICE=3

[[ "" == "$CPU_STAT_SYS" ]] && \
    readonly CPU_STAT_SYS=4

[[ "" == "$CPU_STAT_IDLE" ]] && \
    readonly CPU_STAT_IDLE=5

[[ "" == "$CPU_STAT_IOW" ]] && \
    readonly CPU_STAT_IOW=6

[[ "" == "$CPU_STAT_IRQ" ]] && \
    readonly CPU_STAT_IRQ=7

[[ "" == "$CPU_STAT_SIRQ" ]] && \
    readonly CPU_STAT_SIRQ=8

[[ "" == "$CPU_STAT_STEAL" ]] && \
    readonly CPU_STAT_STEAL=9

[[ "" == "$CPU_STAT_GUEST" ]] && \
    readonly CPU_STAT_GUEST=10

[[ "" == "$CPU_STAT_GUESTNICE" ]] && \
    readonly CPU_STAT_GUESTNICE=11

export CPU_STAT_PREVTOTAL
export CPU_STAT_PREVUSR
export CPU_STAT_PREVSYS
export CPU_STAT_PREVOTHER
export CPU_STAT_PREVIDLE

export CPU_STAT_DIFFTOTAL
export CPU_STAT_DIFFUSR
export CPU_STAT_DIFFSYS
export CPU_STAT_DIFFOTHER
export CPU_STAT_DIFFIDLE

export CPU_USAGE
export CPU_USR
export CPU_SYS
export CPU_OTHER
export CPU_IDLE

function cpu_recorder_getafterstat() {
    cpu_recorder_statstep
    cpu_recorder_get
}

function cpu_recorder_get() {
    echo `cpu_recorder_getusage` `cpu_recorder_getusr` `cpu_recorder_getsys` `cpu_recorder_getother` `cpu_recorder_getidle`
}

function cpu_recorder_getusage() {
    echo "$CPU_USAGE"
}

function cpu_recorder_getusr() {
    echo "$CPU_USR"
}

function cpu_recorder_getsys() {
    echo "$CPU_SYS"
}

function cpu_recorder_getother() {
    echo "$CPU_OTHER"
}

function cpu_recorder_getidle() {
    echo "$CPU_IDLE"
}

function cpu_recorder_statgetuser() {
    cpu_recorder_statgetbycolumn "$1" "$CPU_STAT_USER"
}

function cpu_recorder_statgetsystem() {
    cpu_recorder_statgetbycolumn "$1" "$CPU_STAT_SYS"
}

function cpu_recorder_statgetidle() {
    cpu_recorder_statgetbycolumn "$1" "$CPU_STAT_IDLE"
}

function cpu_recorder_statgetothers() {
    local cpustat="$1"
    local sum=

    local i=
    for i in \
        "$CPU_STAT_NICE" \
        "$CPU_STAT_IOW" \
        "$CPU_STAT_IRQ" \
        "$CPU_STAT_SIRQ" \
        "$CPU_STAT_STEAL" \
        "$CPU_STAT_GUEST" \
        "$CPU_STAT_GUESTNICE" \
        ; do
        local value=`cpu_recorder_statgetbycolumn "$cpustat" $i`
        let sum+=value
    done

    echo $sum
}

function cpu_recorder_statgetjiffies() {
    local cpustat="$1"
    echo -e "$cpustat" | tr ' ' '\n' | \
        awk '{sum+=$0} END{print sum}'
}

function cpu_recorder_statgetbycolumn() {
    local stat="$1"
    local type="$2"

    echo -e "$stat" | eval "awk '{print $"$type"}'"
}

function cpu_recorder_getcpustat() {
    local stats="$1"
    local core="$2"
    local cpu="cpu"

    [[ "" != "$core" ]] && cpu="$cpu$core"

    echo -e "$stats" | eval "awk '/^$cpu /{print}'"
}

function cpu_recorder_printeachcorestat() {
    local stats="$1"

    local result=

    local numbercores=`cpu_recorder_getnumberofcores`
    local cpu="cpu"

    local END=
    local i=
    let END=$numbercores i=0
    while ((i<END)); do
        echo -e "$(cpu_recorder_getcpustat "$stats" $i)"
        let i++
    done
}

function cpu_recorder_getnumberofcores() {
    echo `cat /proc/cpuinfo | grep ^processor | wc -l`
}

function cpu_recorder_statstep() {
    local stats="`cpu_recorder_getstat`"
    local cpustat="$(cpu_recorder_getcpustat "$stats")"

    local utime="`cpu_recorder_statgetuser "$cpustat"`"
    local stime="`cpu_recorder_statgetsystem "$cpustat"`"
    local other="`cpu_recorder_statgetothers "$cpustat"`"
    local idle="`cpu_recorder_statgetidle "$cpustat"`"
    local total="`cpu_recorder_statgetjiffies "$cpustat"`"

    CPU_STAT_DIFFUSR="`echo "$utime-$CPU_STAT_PREVUSR" | bc`"
    CPU_STAT_DIFFSYS="`echo "$stime-$CPU_STAT_PREVSYS" | bc`"
    CPU_STAT_DIFFOTHER="`echo "$other-$CPU_STAT_PREVOTHER" | bc`"
    CPU_STAT_DIFFIDLE="`echo "$idle-$CPU_STAT_PREVIDLE" | bc`"
    CPU_STAT_DIFFTOTAL="`echo "$total-$CPU_STAT_PREVTOTAL" | bc`"

    CPU_USR="`echo "scale=2; $CPU_STAT_DIFFUSR*100/$CPU_STAT_DIFFTOTAL" | bc | awk '{printf "%.2f", $0}'`"
    CPU_SYS="`echo "scale=2; $CPU_STAT_DIFFSYS*100/$CPU_STAT_DIFFTOTAL" | bc | awk '{printf "%.2f", $0}'`"
    CPU_OTHER="`echo "scale=2; $CPU_STAT_DIFFOTHER*100/$CPU_STAT_DIFFTOTAL" | bc | awk '{printf "%.2f", $0}'`"
    CPU_IDLE="`echo "scale=2; $CPU_STAT_DIFFIDLE*100/$CPU_STAT_DIFFTOTAL" | bc | awk '{printf "%.2f", $0}'`"
    CPU_USAGE="`echo "scale=2; 100-$CPU_IDLE" | bc | awk '{printf "%.2f", $0}'`"

    CPU_STAT_PREVUSR="$utime"
    CPU_STAT_PREVSYS="$stime"
    CPU_STAT_PREVOTHER="$other"
    CPU_STAT_PREVIDLE="$idle"
    CPU_STAT_PREVTOTAL="$total"
}

function cpu_recorder_test() {
    echo cpu_recorder_test

    cpu_recorder_init

    local numbercores=`cpu_recorder_getnumberofcores`
    echo ----- ----- -----
    echo Number of CPU cores: $numbercores

    local stats="`cpu_recorder_getstat`"
    echo ----- ----- -----
    echo -e "$stats"

    local cpustat="$(cpu_recorder_getcpustat "$stats")"
    echo ----- ----- -----
    echo -e "$cpustat"

    echo ----- ----- -----
    cpu_recorder_printeachcorestat "$stats"

    echo ----- ----- -----
    echo CPU: `cpu_recorder_statgetjiffies "$cpustat"`
    echo utime: `cpu_recorder_statgetuser "$cpustat"` stime: `cpu_recorder_statgetsystem "$cpustat"`
    echo idle: `cpu_recorder_statgetidle "$cpustat"` other: `cpu_recorder_statgetothers "$cpustat"`

    echo ----- ----- -----
    while
        echo `date +%H:%M:%S`
        echo %Usage %USR %SYS %Other %Idle
        # cpu_recorder_statstep
        cpu_recorder_getafterstat

        echo `date +%H:%M:%S`
        # echo -e %Usage: `cpu_recorder_getusage` %USR: `cpu_recorder_getusr` %SYS: `cpu_recorder_getsys` %Other: `cpu_recorder_getother` %Idle: `cpu_recorder_getidle`
        # echo `cpu_recorder_get`

        sleep 1
    do :; done
}

function cpu_recorder_init() {
    cpu_recorder_finalize
}

function cpu_recorder_finalize() {
    cpu_recorder_reset
}

function cpu_recorder_reset() {
    CPU_STAT_PREVTOTAL=0
    CPU_STAT_PREVUSR=0
    CPU_STAT_PREVSYS=0
    CPU_STAT_PREVOTHER=0
    CPU_STAT_PREVIDLE=0

    CPU_STAT_DIFFTOTAL=0
    CPU_STAT_DIFFUSR=0
    CPU_STAT_DIFFSYS=0
    CPU_STAT_DIFFOTHER=0
    CPU_STAT_DIFFIDLE=0

    CPU_USAGE=0
    CPU_USR=0
    CPU_SYS=0
    CPU_OTHER=0
    CPU_IDLE=0
}

function cpu_recorder_load() {
    echo cpu_recorder_load

    source module.sh
}

function cpu_recorder_exit() {
    echo cpu_recorder_exit
}

function cpu_recorder_getstat() {
    cat /proc/stat
}

