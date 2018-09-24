#!/bin/sh

ua="Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"

video_map_id() {
    cam_id="$1"
}

checkConfig() {
    [ ! -e `dirname $0`/config.sh ] && echo "Error: no config.sh found! Copy config.sh.sample to config.sh and edit it" >&2 && exit 1
}

init() {
    # temp files
    resp=`mktemp /tmp/curl-pgu-json.XXXXX`
    cjar=`mktemp /tmp/curl-pgu-cookies.XXXXX`
    trap "cleanup; exit 1" INT TERM EXIT
}

cleanup() {
    # remove temp files
    [ -e "$cjar" ] && rm $cjar
    [ -e "$resp" ] && rm "$resp"
}

loginPgu() {
    # get login url
    login_url=`curl -s -k -L -c $cjar -b $cjar -A "$ua" -e ';auto' 'https://my.mos.ru/my/' | sed -Ene 's~.*"(https://oauth20.mos.ru/[^"]+)".*~\1~p'`
    [ -z "$login_url" ] && echo "Warning: failed to get login URL, trying default">&2 && login_url="https://oauth20.mos.ru/sps/oauth/oauth20/authorize?client_id=Wiu8G6vfDssAMOeyzf76&response_type=code&redirect_uri=https://my.mos.ru/my/website_redirect_uri"
    # post login data, follow redirects, check resulting page
    curl -s -o /dev/null -c $cjar -b $cjar -A "$ua" -e 'https://my.mos.ru/my/;auto' -k -L --data-urlencode "j_username=$login" --data-urlencode "j_password=$password" --data-urlencode "accessType=alias" https://oauth20.mos.ru/sps/j_security_check
    if ! curl -L -c $cjar -b $cjar -e ';auto' -A "$ua" -k -s 'https://my.mos.ru/my/' | grep -q "SURNAME"; then
        echo "Error: login failed!" >&2
        exit 1
    fi
}

getWaterCounterIds() {
    eval `cat $resp |  jq -r '.counter | sort_by(.type)[] | "type", .type, .counterId, "num", .type, .num' | paste -sd '_=;' -`
}

getWaterIndications() {
    # get service page, follow oauth redirects
    curl -s -o /dev/null -L -c $cjar -b $cjar -k -A "$ua" https://www.mos.ru/pgu/ru/application/guis/1111/

    # get water counters
    curl -c $cjar -b $cjar -k -s -A "$ua" 'https://www.mos.ru/pgu/common/ajax/index.php' \
        --data "ajaxModule=Guis&ajaxAction=getCountersInfo&items%5Bpaycode%5D=$paycode&items%5Bflat%5D=$kv"
}

removeWaterIndication() {
    curl -s -o /dev/null -c $cjar -b $cjar -k -s -A "$ua" 'https://www.mos.ru/pgu/common/ajax/index.php' \
		--data "ajaxModule=Guis&ajaxAction=removeCounterIndication&items%5Bpaycode%5D=$paycode&items%5Bflat%5D=$kv&items%5BcounterId%5D=$1"
}

setWaterIndications() {
    hot="$1"
    cold="$2"
    curl -s -o /dev/null -c $cjar -b $cjar -k -s -A "$ua" 'https://www.mos.ru/pgu/common/ajax/index.php' \
		--data "ajaxModule=Guis&ajaxAction=addCounterInfo&items%5Bpaycode%5D=$paycode&items%5Bflat%5D=$kv&items%5Bindications%5D%5B0%5D%5BcounterNum%5D=$type_1&items%5Bindications%5D%5B0%5D%5BcounterVal%5D=$cold&items%5Bindications%5D%5B0%5D%5Bnum%5D=$num_1&items%5Bindications%5D%5B0%5D%5Bperiod%5D=$dt&items%5Bindications%5D%5B1%5D%5BcounterNum%5D=$type_2&items%5Bindications%5D%5B1%5D%5BcounterVal%5D=$hot&items%5Bindications%5D%5B1%5D%5Bnum%5D=$num_2&items%5Bindications%5D%5B1%5D%5Bperiod%5D=$dt"
}

getMosenergoData() {
    # get service page, follow oauth redirects
    curl -s -o /dev/null -L -c $cjar -b $cjar -k -A "$ua" https://www.mos.ru/pgu/ru/application/mosenergo/counters/

    eval `curl -c $cjar -b $cjar -k -s -A "$ua" 'https://www.mos.ru/pgu/common/ajax/index.php' \
        --data "ajaxModule=Mosenergo&ajaxAction=qMpguCheckShetch&items%5Bcode%5D=$mosenergo_accnum&items%5Bnn_schetch%5D=$mosenergo_cntnum"  \
            | jq ".result" | sed -Ene 's/ +"(id_kng|schema)": "(.*)",?$/\1="\2"/p'`
    eval `curl -c $cjar -b $cjar -k -s -A "$ua" 'https://www.mos.ru/pgu/common/ajax/index.php' \
        --data "ajaxModule=Mosenergo&ajaxAction=qMpguGetLastPok&items%5Bcode%5D=$mosenergo_accnum&items%5Bid_kng%5D=$id_kng&items%5Bs%D1%81hema%5D=$schema" \
            | jq ".result" | sed -Ene 's/ +"(pok_t1|pok_t2|pok_t3|dt_obrz)": "(.*)",?$/\1="\2"/p'`
}

printMosenergoLastValues() {
    echo "Previously sent values:"
    echo "Date		T1	T2	T3"
    echo "${dt_obrz%T*}	$pok_t1	$pok_t2	$pok_t3"
}

setMosenergoIndications() {
    t1="$1"
    t2=0
    t3=0
    [ "$#" -ge "2" ] && [ "$2" -gt "0" ] && t2="$2"
    [ "$#" -ge "3" ] && [ "$3" -gt "0" ] && t3="$3"
    curl -c $cjar -b $cjar -k -s -A "$ua" "https://www.mos.ru/pgu/common/ajax/index.php" \
        --data "ajaxModule=Mosenergo&ajaxAction=qMpguDoTransPok&items%5Bid_kng%5D=$id_kng&items%5Bcode%5D=$mosenergo_accnum&items%5Bvl_pok_t1%5D=$t1&items%5Bvl_pok_t2%5D=$t2&items%5Bvl_pok_t3%5D=$t3&items%5Bs%D1%81hema%5D=$schema" \
            | jq ""
}

getLastDayOfMonth() {
    if [ `uname` = "Linux" ]; then
        dt=`date -d "$(date +'%Y-%m-1') +1 month -1 day" +'%Y-%m-%d'`
    else
        dt=`date -v1d -v+1m -v-1d +'%Y-%m-%d'`
    fi
}

printWaterHistory() {
    echo "History of values"
    echo "Date		Hot	Cold"
    cat $resp | jq -r ".counter | sort_by(.type)[] | .indications[] | .period, .indication"  | paste -sd '	\n' - | sort | paste -sd '	\n' - | cut -f 1,2,4| sed -Ee 's/\+03:00//'
}

printWaterLastValues() {
    echo "Last set values (cold, hot): "
    getWaterIndications | jq -r ".counter | sort_by(.type)[] | .indications[] | select(.period==\"$dt+03:00\").indication" | paste -sd ',' -
}
