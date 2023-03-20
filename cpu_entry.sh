#!/bin/bash

function cpu_entry_load() {
    module_import `realpath utils.sh`
    module_import `realpath cpu/cpu_recorder.sh`
    MODULE_CPU_LOADED=true
}

function cpu_entry_exit() {
    cpu_recorder_exit
    unset MODULE_CPU_LOADED
}

if [[ "$MODULE_CPU_LOADED" != 'true' ]]; then
    echo "Loading cpu"
    cpu_entry_load
fi

