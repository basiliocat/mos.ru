#!/bin/sh

AUTH=user:password
URL=http://jira.domain.com

curl -s -u $AUTH "$URL/rest/api/2/status" | python -mjson.tool
