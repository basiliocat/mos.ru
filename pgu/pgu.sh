#!/bin/sh

paycode="код_плательщика"
login="user%40domain.ru"
password="пароль"

usage() {
    cat >&2 << EOF
Usage:
   $0 get - get counter values
   $0 set <hot_counter> <cold_counter> - set counter values for current month
   $0 remove - remove last values for both cold and hot counter
EOF
}
getIndications() {
    curl -c $cjar -b $cjar -s -d "getCountersInfo=true&requestParams%5Bpaycode%5D=$paycode" https://pgu.mos.ru/ru/application/guis/1111/
}

removeIndication() {
    curl -c $cjar -b $cjar -s -d "removeCounterIndication=true&values%5Bpaycode%5D=$paycode&values%5BcounterId%5D=$1" https://pgu.mos.ru/ru/application/guis/1111/ > /dev/null
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

cjar=`mktemp /tmp/curl-pgu-cookies.XXXXX`
resp=`mktemp /tmp/curl-pgu-json.XXXXX`
# get cookies
curl -c $cjar -s https://login.mos.ru/eaidit/eaiditweb/openouterlogin.do > /dev/null
# post login data
if ! curl -c $cjar -b $cjar -s -L -d "username=$login&password=$password" https://login.mos.ru/eaidit/eaiditweb/outerlogin.do | grep -q "Your login was successful"; then
    echo "Login failed!" >&2
    exit 1
fi
if [ `uname` = "Linux" ]; then
    dt=`date -d "$(date +'%Y-%m-1') +1 month -1 day" +'%Y-%m-%d'`
else
    dt=`date -v1d -v+1m -v-1d +'%Y-%m-%d'`
fi

getIndications > $resp
eval `cat $resp |  jq -r '.counter | sort_by(.type)[] | "type", .type, .counterId' | paste -sd '_=;' -`

if [ "$1" = "get" ]; then
    echo "History of values"
    echo "Date		Hot	Cold"
    cat $resp | jq -r ".counter | sort_by(.type)[] | .indications[] | .period, .indication"  | paste -sd '	\n' - | sort | paste -sd '	\n' - | cut -f 1,2,4| sed -Ee 's/\+04:00//'
elif [ "$1" = "set" -a "$#" -eq 3 ]; then
    hot="$2"
    cold="$3"
    [ "$hot" -gt "$cold" ] && echo "Error: Hot counter value ($hot) > cold counter value ($cold)!" && exit 1
    curl -c $cjar -b $cjar -s -d "addCounterInfo=true&values%5Bpaycode%5D=$paycode&values%5Bindications%5D%5B0%5D%5BcounterNum%5D=$type_2&values%5Bindications%5D%5B0%5D%5BcounterVal%5D=$hot&values%5Bindications%5D%5B0%5D%5Bperiod%5D=$dt&values%5Bindications%5D%5B0%5D%5Bnum%5D=&values%5Bindications%5D%5B1%5D%5BcounterNum%5D=$type_1&values%5Bindications%5D%5B1%5D%5BcounterVal%5D=$cold&values%5Bindications%5D%5B1%5D%5Bperiod%5D=$dt&values%5Bindications%5D%5B1%5D%5Bnum%5D=" https://pgu.mos.ru/ru/application/guis/1111/  > /dev/null
    echo "Last set values (cold,hot): "
    getIndications | jq -r ".counter | sort_by(.type)[] | .indications[] | select(.period==\"$dt+04:00\").indication" | paste -sd ',' -
elif [ "$1" = "remove" ]; then
    removeIndication $type_1
    removeIndication $type_2
else
    usage
fi
rm $cjar
rm $resp
