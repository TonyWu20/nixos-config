#! /bin/bash

memory_usage=$(nu -c "nvidia-smi -q -d Memory |rg --pcre2 '(Total|Used)\\s+:\\s+(\\d+ MiB)' -or '\$2' | lines | select 0 1 | [(\$in.1|str replace ' MiB' ''), \$in.0] | str join '/'")
gpu_usage=$(nvidia-smi -q -d utilization | rg -i 'Gpu\s+:\s+(\d+)' -or '$1')
temp=$(nvidia-smi -q -d Temperature | rg 'GPU Current Temp\s+:\s+(\d+)' -or '$1')
fanspeed=$(nvidia-smi -q | rg 'Fan Speed\s+:\s+(\d+)' -or '$1')

echo "GPU : $gpu_usage % Memory : $memory_usage % Temp: $temp C Fan: $fanspeed"
