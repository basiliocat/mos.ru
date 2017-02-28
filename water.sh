#!/bin/sh

usage() {
    cat >&2 << EOF
$0 - commandline tool to send water counter values to pgu.mos.ru
Usage:
   $0 get - get counter values
   $0 set <hot_counter> <cold_counter> - set counter values for current month
   $0 remove - remove last values for both cold and hot counter
EOF
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

. `dirname $0`/lib.sh
checkConfig
. `dirname $0`/config.sh

init
loginPgu
getLastDayOfMonth
getWaterIndications > $resp
getWaterCounterIds

if [ "$1" = "get" ]; then
    printWaterHistory
elif [ "$1" = "set" -a "$#" -eq 3 ]; then
    setWaterIndications "$2" "$3"
    printWaterLastValues
elif [ "$1" = "remove" ]; then
    removeWaterIndication $type_1
    removeWaterIndication $type_2
else
    usage
fi
