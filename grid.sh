# go into log folder: just use first folder (be aware that some cluster have multiple folders so choose the correct one)
cd /var/log/

# check disk usage
df -h
df -i

# Section 1
# last 500 responses - may not be accurate. check time based on `| head -n 2` output
echo "Last 500 responses - check time to see if within relelvant time period" 
tail -n 500 access.log | head -n 2
echo "Last 500 responses - HTTP responses"
tail -n 500 access.log | awk '{print $9}' | sort | uniq -c | sort -nr | head -n 10
echo "Last 500 responses - IPs"
tail -n 500 access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
echo "Last 500 responses - UAs"
tail -n 500 access.log | cut -d' ' -f 12- | sort | uniq -c | sort -nr | head -n 10

# Section 2
# last 500 PHP responses - may not be accurate. check time based on `| head -n 2` output
tail -n 500 php.access.log | head -n 2
echo "Last 500 responses - PHP HTTP responses"
tail -n 500 php.access.log | awk '{ print $3 }' | sort | uniq -c | sort -nr | head -n 10
echo "Last 500 responses - PHP Processing time"
tail -n 500 php.access.log | sort -n -k 4 | tail -n 20

# Section 3
# typical format 1 - may not be accurate. check time based on `| head -n 2` output
awk -vDate=`date -d'now-10 minutes' +[%Y-%m-%dT%H:%M:%S` '$4 > Date {print $0}' access.log | head -n 2
echo "Format 1 - HTTP responses"
awk -vDate=`date -d'now-10 minutes' +[%Y-%m-%dT%H:%M:%S` '$4 > Date {print $0}' access.log | awk '{print $9}' | sort | uniq -c | sort -nr | head -n 10
echo "Format 1 - IPs"
awk -vDate=`date -d'now-10 minutes' +[%Y-%m-%dT%H:%M:%S` '$4 > Date {print $0}' access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
echo "Format 1 - UAs"
awk -vDate=`date -d'now-10 minutes' +[%Y-%m-%dT%H:%M:%S` '$4 > Date {print $0}' access.log | cut -d' ' -f 12- | sort | uniq -c | sort -nr | head -n 10

# Section 4
# typical format 2 - may not be accurate. check time based on `| head -n 2` output
awk -vDate=`date -d'now-10 minutes' +[%d/%b/%Y:%H:%M:%S` '$4 > Date {print $0}' access.log | head -n 2
echo "Format 2 - HTTP responses"
awk -vDate=`date -d'now-10 minutes' +[%d/%b/%Y:%H:%M:%S` '$4 > Date {print $0}' access.log | awk '{print $9}' | sort | uniq -c | sort -nr | head -n 10
echo "Format 2 - IPs"
awk -vDate=`date -d'now-10 minutes' +[%d/%b/%Y:%H:%M:%S` '$4 > Date {print $0}' access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
echo "Format 2 - UAs"
awk -vDate=`date -d'now-10 minutes' +[%d/%b/%Y:%H:%M:%S` '$4 > Date {print $0}' access.log | cut -d' ' -f 12- | sort | uniq -c | sort -nr | head -n 10

# PHP
# Section 5
# typical format 1 - may not be accurate. check time based on `| head -n 2` output
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%d%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | head -n 2
echo "Format 1 - PHP HTTP responses"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%d%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | awk '{ print $3 }' | sort | uniq -c | sort -nr | head -n 10
echo "Format 1 - PHP Processing time"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%d%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | sort -n -k 4 | tail -n 20

# Section 6
# typical format 2 - may not be accurate. check time based on `| head -n 2` output
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%dT%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | head -n 2
echo "Format 2 - PHP HTTP responses"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%dT%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | awk '{ print $3 }' | sort | uniq -c | sort -nr | head -n 10
echo "Format 2 - PHP Processing time"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%dT%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | sort -n -k 4 | tail -n 20


ps faux | grep php                                      # php proceses. any crons?
ps faux | grep php | grep pool | wc -l                  # current children in use
grep -e '^pm.max_children' /etc/php/*/fpm/php-fpm.conf # max children available https://docs.platform.sh/languages/php/fpm.html

lsof | grep -i php | grep -i tcp                        # open connections from php

## Check services - modify relationship name and uncomment where needed

###################
## check DB
## assumes relationship is named "database"
# DB_HOST=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["database"][0]["host"]')
# DB_USER=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["database"][0]["username"]')
# DB_PASS=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["database"][0]["password"]')
# DB_PATH=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["database"][0]["path"]')
# DB_PORT=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["database"][0]["port"]')

## check number of non sleeping queries
# mysql -u $DB_USER -h $DB_HOST --password="$DB_PASS" -P $DB_PORT $DB_PATH -e 'show processlist;' | grep -v Sleep | wc -l

## view summary of non sleeping queries
# mysql -u $DB_USER -h $DB_HOST --password="$DB_PASS" -P $DB_PORT $DB_PATH -e 'show processlist;' | grep -v Sleep

## view details of non sleeping queries
# mysql -u $DB_USER -h $DB_HOST --password="$DB_PASS" -P $DB_PORT $DB_PATH -e 'show full processlist;' | grep -v Sleep

## a lot of sleeping nodes could be an application issue
# mysql -u $DB_USER -h $DB_HOST --password="$DB_PASS" -P $DB_PORT $DB_PATH -e 'show processlist;' | grep Sleep | wc -l


###################
## check redis / valkey
## assumes relationship is named "redis"
# REDIS_VALKEY_HOST=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["redis"][0]["host"]')
# REDIS_VALKEY_PORT=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["redis"][0]["port"]')

## memory usage and evicted keys
# redis-cli -h $REDIS_VALKEY_HOST -p $REDIS_VALKEY_PORT info | grep "used_memory_human\|used_memory_peak_human\|maxmemory_human\|maxmemory_policy\|evicted_keys"
# valkey-cli -h $REDIS_VALKEY_HOST -p $REDIS_VALKEY_PORT info | grep "used_memory_human\|used_memory_peak_human\|maxmemory_human\|maxmemory_policy\|evicted_keys"

###################
## check elasticsearch / openesarch
## assumes relationship is named "elasticsearch"
# ES_OS_HOST=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["elasticsearch"][0]["host"]')
# ES_OS_PORT=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["elasticsearch"][0]["port"]')

## cluster health
# curl "http://${ES_OS_HOST}:${ES_OS_PORT}/_cluster/health?pretty"

## heap usage
# curl "http://${ES_OS_HOST}:${ES_OS_PORT}/_cat/nodes?v"
# curl "http://${ES_OS_HOST}:${ES_OS_PORT}/_cat/nodes?h=heap*&v"