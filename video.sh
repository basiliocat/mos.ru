#!/bin/sh

usage() {
    me=`basename $0`
    cat >&2 << EOF
$me - get cctv video stream from video.mos.ru
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
        curl -o $resp -c $cjar -b $cjar -k -s -A "$ua" -e "https://video.mos.ru/;auto" -L "https://video.mos.ru/camera/ajaxGetVideoUrl?id=$cam_id"
        grep -q "https://login.mos.ru" $resp && echo "Warning: re-login requested">&2 && break
        m3u=`cat $resp | jq -r '.live | .ios | .url[0]'`
        [ -z "$m3u" ] && echo "Error: couldn't get playlist URL">&2 && exit 1
        ts_url=`curl -c $cjar -b $cjar -k -A "$ua" -s -L "$m3u" | grep -m 1 "http" | tr -d '\r'`
        [ -z "$ts_url" ] && echo "Warning: failed get video stream URL">&2 && sleep 10 && continue
        [ ! -d "video/$cam_id" ] && mkdir -p "video/$cam_id"
        curl -c $cjar -b $cjar -k -A "$ua" -L "$ts_url" -o video/$cam_id/`date +%s`.ts
        done
done
