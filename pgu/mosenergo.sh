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

. `dirname $0`/lib.sh
checkConfig
. `dirname $0`/config.sh

init
loginPgu

if [ "$1" = "get" ]; then
    getMosenergoData
    printMosenergoLastValues
elif [ "$1" = "set" -a "$#" -ge 2 ]; then
    shift
    getMosenergoData
    parseMosenergoVars
    setMosenergoIndications $@
    getMosenergoData
    printMosenergoLastValues
else
    usage
fi
cleanup
