#!/bin/sh

usage() {
    me=`basename $0`
    cat >&2 << EOF
$me - command line tool to send water counter values to https://my.mos.ru
Usage:
   $me get - get counter values
   $me set <hot_counter> <cold_counter> - set counter values for current month
   $me remove - remove last values for both cold and hot counter
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
