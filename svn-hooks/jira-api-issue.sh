#!/bin/sh

AUTH=user:password
URL=http://jira.domain.com
ST1=10016|10018|10027|10022|10034
ST2=developing/reviewing/integrating/reverting/merging

curl -s -u $AUTH "$URL/rest/api/latest/issue/$1" | grep -q "Issue Does Not Exist" && echo "JIRA issue $1 does not exist" && exit
curl -s -u $AUTH "$URL/rest/api/latest/issue/$1" | grep -Eq "$URL/rest/api/2/status/($ST1)" || echo "JIRA issue $1 is not in $ST2 status"

