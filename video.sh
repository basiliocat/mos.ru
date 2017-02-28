#!/bin/sh

usage() {
    $me = `basename $0`
    cat >&2 << EOF
$me - commandline tool to get video stream from video.mos.ru
Usage:
    $me <camera_id>
EOF
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

. `dirname $0`/lib.sh
checkConfig
. `dirname $0`/config.sh

video_map_id "$1"
init
while true; do
    loginPgu
    while true; do
        curl  -c $cjar -b $cjar -k -s -A "$ua" -L "https://video.mos.ru/camera/ajaxGetVideoUrl?id=$cam_id" > $resp
        grep -q "https://login.mos.ru" $resp && echo "Relogin required" && break
        m3u=`cat $resp | jq -r '.live | .ios | .url[0]'`
        [ -z "$m3u" ] && echo "Error: couldn't get video URL" && exit 1
        ts_url=`curl -c $cjar -b $cjar -k -A "$ua" -s -L "$m3u" | grep -m 1 "http" | tr -d '\r'`
        [ -z "$ts_url" ] && echo "Error: couldn't get m3u URL" && sleep 10 && continue
        [ ! -d "video/$cam_id" ] && mkdir -p "video/$cam_id"
        curl -c $cjar -b $cjar -k -A "$ua" -L "$ts_url" -o video/$cam_id/`date +%s`.ts
        done
done
