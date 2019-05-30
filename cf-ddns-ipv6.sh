#!/bin/bash

auth_email="xxxxxx@gmail.com"
auth_key=aa8c3c5288261317794xxxxxxxxxxxxxxxx
## your cloudflare account key above
zone_name="xxxxx.com"
record_name="www.xxxx.com"
rec_type=AAAA
## calls the ipv6_addr.sh script to return an external IPv6 on default interface eth0
content=`curl ip.sb`
echo $(date) 
echo "Checking $rec_type for $record_name"
zone_id=`curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" \
-H "X-Auth-Email: $auth_email" \
-H "X-Auth-Key: $auth_key" \
-H "content-Type: application/json" | \
grep -Eo '"id":"[^"]*' | head -1|sed -n 's/"id":"*//p'` 

echo "Zone ID: " $zone_id

record_id=`curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=$rec_type&name=$record_name" \
-H "X-Auth-Email: $auth_email" \
-H "X-Auth-Key: $auth_key" \
-H "content-Type: application/json" | \
grep -Eo '"id":"[^"]*' | head -1 | sed -n 's/"id":"*//p'`

echo "Record ID: " $record_id

current_content=`curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
-H "X-Auth-Email: $auth_email" \
-H "X-Auth-Key: $auth_key" \
-H "content-Type: application/json" | \
grep -Eo '"content":"[^"]*' | head -1 | sed -n 's/"content":"*//p'`

echo "Current Content: " $current_content
echo "New Content: " $content

if [[ $current_content == $content ]]; then
    echo "Content not changed.  Exiting."
    exit 0
else
    echo "Content Changed.  Update Cloudflare."
fi

update=`curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
-H "X-Auth-Email: $auth_email" \
-H "X-Auth-Key: $auth_key" \
-H "content-Type: application/json" \
-d "{\"id\":\"$zone_id\",\"type\":\"$rec_type\",\"name\":\"$record_name\",\"content\":\"$content\"}"`

if [[ $update == *"\"success\":false"* ]]; then
    message = "API UPDATE FAILED.  DUMPING RESULTS:\n$update"
    echo "$message"
    exit 1
else
    message="$record_type changed to: $content"
    echo "$message"
fi
