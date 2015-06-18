#!/bin/sh

usage() {
    cat >&2 << EOF
$0 - commandline tool to send electric counter values to pgu.mos.ru
Usage:
   $0 get - get last sent values
   $0 set <T1_value> [T2_value] [T3_value] - set counter value(s)
EOF
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

. `dirname $0`/config.sh
. `dirname $0`/lib.sh

init
loginPgu

if [ "$1" = "get" ]; then
    printMosenergoLastValue
elif [ "$1" = "set" -a "$#" -lt 2 ]; then
    setMosenergoIndications "$2" "$3" "$4"
    printMosenergoLastValue
else
    usage
fi
cleanup
