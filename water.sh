#!/bin/sh

usage() {
    me=`basename $0`
    cat >&2 << EOF
$me - command line tool to send water counter values to https://my.mos.ru
Usage:
   $me get - get counter values
   $me set <value list> - set counter values for current month
   $me remove - remove last values for all counters
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
elif [ "$1" = "set" ]; then
    shift
    setWaterIndications $@
    printWaterLastValues
elif [ "$1" = "remove" ]; then
    removeWaterIndication
else
    usage
fi
