# Log analysis

- Logs cannot tell the full story but can help provide some hints into possible issues
- Generally recent logs (~10-15min) before any outage or performance issue would probably be a good starting point
- Log analysis in larger time spans can be useful to gauge trends of traffic / malicious IPs / user agents
- Run commands to look for requests within that time range
    - Using attached scripts [`dg2.sh`](./dg2.sh) / [`grid.sh`](grid.sh)
        - Run commands
        - Review each section and check the output of the command ending with `| head -n 2` to ensure the time matches the expected recent time range
        - It is possible to filter logs based on time but depending on situation and setup it may not work 100% of the time thus why there are multiple formats and why you should check and verify logs
- Some typical things to review
    - Influx of extra traffic from IPs / IP ranges / user agents
    - Slow application responses (only for PHP applications with `php.access.log`)
    - Odd HTTP responses (e.g. if lots of 404s could be indication of bad links or malicious requests)
- Related files
    - Check slow application responses: [`performance.md`](./performance.md)
    - Database issues: [`mariadb-mysql.md`](./mariadb-mysql.md)
    - User Agent details: [`user-agents.md`](./user-agents.md)
    - Blocking traffic: [`blocking-traffic.md`](./blocking-traffic.md)

## Log file location

### [Grid] / [DG3]
```
cd /var/log/
```

### [DG2]

- Typically a cluster will only have a single application / docroot on it
- But some can have multiple sites hosted on it. Each site will have its own DOCROOT name so ensure you're in the correct DOCROOT for the application being investigated
```
cd /var/log/platform/DOCROOT # there is typically only one but some clusters can have mutiple docroots so identify the correct one
```
- Enter first directory found
```
cd $(ls -d /var/log/platform/*/ | head -n 1) 
```

## Investigating specific / suspicious logs

- Run initial script to identify some data
- Find further details to dig into if necessary
- Run commands again with extra filters
    - Count number of requests
    - Display some of the requests
- Example below assumes `tail -n 500` is suffcient for the period being looked for
```
# number or requests
tail -n 500 access.log | grep -Eai "$SEARCH" | wc -l
# review some requests to look for any issues e.g. paths that look malicious
tail -n 500 access.log | grep -Eai "$SEARCH" | head
tail -n 500 access.log | grep -Eai "$SEARCH" | tail
# check HTTP responses e..g if lots of 404s likely malicious / bad actor
tail -n 500 access.log | grep -Eai "$SEARCH" | awk '{print $9}' | sort | uniq -c | sort -nr | head -n 10
# check "IPs" e.g. if old user agent coming from multiple IPs possible DDoS
tail -n 500 access.log | grep -Eai "$SEARCH" | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
# echo "UAs" e.g. if single IP having multiple user ageints, possible DDOs
tail -n 500 access.log | grep -Eai "$SEARCH" | cut -d' ' -f 12- | sort | uniq -c | sort -nr | head -n 10
```
- If searching gzip'd file use `zgrep $SEARCH $FILE` / `zcat $FILE | grep $SEARCH`
- If needed, search for logs for the past couple of days or hours
- Searching multiple IPs
```
    grep -Eai '127.0.0.1|10.0.0.1' # multiple IP addresss
    grep -Eai ' 127.0' | # IPs starting with 127.0 
```
- Searching time multiple matching times
```
    grep -Eai `2025-05-03T08:1|2025-05-03T08:2`
    grep -Eai '`03/May/2025:08:1|03/May/2025:08:2`
```

---- 


## nginx log searching

- List first 2 rows matching the search criteria (so we can manually review if timing is correct - if not correct, use a different format or modify things manually)
- Show counts for each kind of search
    - HTTP access response code
    - IP addresses
    - user agents

### nginx access.log - Last 500 requests
```
# last 500 responses - may not be accurate. check time based on `| head -n 2` output
tail -n 500 access.log | head -n 2
# echo "HTTP responses"
tail -n 500 access.log | awk '{print $9}' | sort | uniq -c | sort -nr | head -n 10
# echo "IPs"
tail -n 500 access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
# echo "UAs"
tail -n 500 access.log | cut -d' ' -f 12- | sort | uniq -c | sort -nr | head -n 10
```

### nginx access.log - Last 10 minutes - format 1
```
# typical format 1 - may not be accurate. check time based on `| head -n 2` output
awk -vDate=`date -d'now-10 minutes' +[%Y-%m-%dT%H:%M:%S` '$4 > Date {print $0}' access.log | head -n 2
# echo "HTTP responses"
awk -vDate=`date -d'now-10 minutes' +[%Y-%m-%dT%H:%M:%S` '$4 > Date {print $0}' access.log | awk '{print $9}' | sort | uniq -c | sort -nr | head -n 10
# echo "IPs"
awk -vDate=`date -d'now-10 minutes' +[%Y-%m-%dT%H:%M:%S` '$4 > Date {print $0}' access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
# echo "UAs"
awk -vDate=`date -d'now-10 minutes' +[%Y-%m-%dT%H:%M:%S` '$4 > Date {print $0}' access.log | cut -d' ' -f 12- | sort | uniq -c | sort -nr | head -n 10
```

### nginx access.log - Last 10 minutes - format 2
```
# typical format 2 - may not be accurate. check time based on `| head -n 2` output
awk -vDate=`date -d'now-10 minutes' +[%d/%b/%Y:%H:%M:%S` '$4 > Date {print $0}' access.log | head -n 2
# echo "HTTP responses"
awk -vDate=`date -d'now-10 minutes' +[%d/%b/%Y:%H:%M:%S` '$4 > Date {print $0}' access.log | awk '{print $9}' | sort | uniq -c | sort -nr | head -n 10
# echo "IPs"
awk -vDate=`date -d'now-10 minutes' +[%d/%b/%Y:%H:%M:%S` '$4 > Date {print $0}' access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
# echo "UAs"
awk -vDate=`date -d'now-10 minutes' +[%d/%b/%Y:%H:%M:%S` '$4 > Date {print $0}' access.log | cut -d' ' -f 12- | sort | uniq -c | sort -nr | head -n 10
```

### [Grid] nginx access.log date history trend - in the last 10 days

```
cat access.log | grep "" | awk '{print $4}' | cut -c1-12 | uniq -c | tail
```

### [DG2] nginx access.log date history trend - per day for past 10 days
```
cat access.log | grep "" | awk '{print $4}' | cut -c1-12 | uniq -c
for i in {1..10};do zcat access.log.$i.gz  | grep "" | awk '{print $4}' | cut -c1-12 | uniq -c ;done
```

### nginx access.log date history trend - per hour
```
cat access.log | grep "" | awk '{print $4}' | cut -c1-15 | uniq -c
```

### nginx access.log date history trend - per 10 minutes
```
cat access.log | grep "" | awk '{print $4}' | cut -c1-17 | uniq -c
```

## php.access.log searching

- List first 2 rows matching the search criteria (so we can manually review if timing is correct - if not correct, use a different format or modify things manually)
- Output shows each kind of search
    - counts of HTTP access response code
    - longest responses

### [DG2] php.access.log - Last 500 requests
```
# last 500 PHP responses - may not be accurate. check time based on `| head -n 2` output
tail -n 500 php.access.log | head -n 2
# echo "PHP HTTP responses" # dedicated
tail -n 500 php.access.log | awk '{ print $4 }' | sort | uniq -c | sort -nr | head -n 10
# echo "PHP Processing time" # dedicated
tail -n 500 php.access.log | sort -n -k 5 | tail -n 20
```

### [Grid] php.access.log - Last 500 requests
```
# last 500 PHP responses - may not be accurate. check time based on `| head -n 2` output
tail -n 500 php.access.log | head -n 2
# echo "PHP HTTP responses"
tail -n 500 php.access.log | awk '{ print $3 }' | sort | uniq -c | sort -nr | head -n 10
# echo "PHP Processing time"
tail -n 500 php.access.log | sort -n -k 4 | tail -n 20
```

### [Grid] php.access.log - Last 10 minutes - format 1
```
# typical format 1 - may not be accurate. check time based on `| head -n 2` output
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%d%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | head -n 2
# echo "PHP HTTP responses"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%d%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | awk '{ print $3 }' | sort | uniq -c | sort -nr | head -n 10
# echo "PHP Processing time"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%d%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | sort -n -k 4 | tail -n 20
```

### [Grid] php.access.log - Last 10 minutes - format 2
```
# typical format 2 - may not be accurate. check time based on `| head -n 2` output
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%dT%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | head -n 2
# echo "PHP HTTP responses"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%dT%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | awk '{ print $3 }' | sort | uniq -c | sort -nr | head -n 10
# echo "PHP Processing time"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%dT%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | sort -n -k 4 | tail -n 20
```

### [DG2] php.access.log - Last 10 minutes - format 1
```
# typical format 1 - may not be accurate. check time based on `| head -n 2` output
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%d%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | head -n 2
# echo "PHP HTTP responses"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%d%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | awk '{ print $4 }' | sort | uniq -c | sort -nr | head -n 10
# echo "PHP Processing time"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%d%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | sort -n -k 5 | tail -n 20
```
### [DG2] php.access.log - Last 10 minutes - format 2
```
# typical format 2 - may not be accurate. check time based on `| head -n 2` output
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%dT%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | head -n 2
# echo "PHP HTTP responses"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%dT%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | awk '{ print $4 }' | sort | uniq -c | sort -nr | head -n 10
# echo "PHP Processing time"
awk -vDate=`date -d'now-10 minutes' +%Y-%m-%dT%H:%M:%S` '$1$2 > Date {print $0}' php.access.log | sort -n -k 5 | tail -n 20
```


### [Grid] php.access.log date history trend - per day

```
for i in {1..10};do zcat php.access.log.$i.gz | grep "" | awk '{print $1,$2}' | cut -c1-10 | sort | uniq -c ; done | tail
```
### [DG2] php.access.log date history trend - per day for the past 10 days

```
for i in {1..10};do zcat php.access.log.$i.gz | grep "" | awk '{print $1,$2}' | cut -c1-10 | sort | uniq -c ; done
```

### php.access.log date history trend - per hour
```
cat php.access.log | grep "" | awk '{print $1,$2}' | cut -c1-13 | sort | uniq -c
```

### php.access.log date history trend - per 10 minutes

```
cat php.access.log | grep "" | awk '{print $1,$2}' | cut -c1-15 | sort | uniq -c
```

----



## Log files

### `access.log`
- nginx access logs
- will always be there for any kind of app
- if requests are not making it here, it would be likely be due to caching layer responding (Platform cache / Fastly cache / 3rd party CDN cache)
- main data points
    - [Request] IP address
    - [Request] User agent
    - [Request] Path
    - [Response] HTTP code
    - [Response] Time response sent (i.e. end time)

### `php.access.log`
- PHP access logs
- For PHP based applications
- main data points
    - [Request] Time of request starting (i.e. start time)
    - [Request] Path
    - [Response] HTTP code
    - [Response] Time taken to respond
    - [Response] Memory used to process
- Can be customize through this process


### `error.log`
- nginx error log
- usually indicates errors when nginx has issues communicating with the (upstream) application

### `app.log` [Grid]
- output log for your application

### `php5-fpm.log`
- PHP error logs
- segfaults

### `access.log` vs `php.access.log` time difference
- `php.access.log` is based on start time
- `access.log` is based on end time
- Example below: 5 second requests starts at `2025-05-03T08:16:21Z` and ends at `03/May/2025:08:16:26`

```
# access.log
202.160.35.135 - - [03/May/2025:08:16:26 +0000] "GET /slow.php HTTP/1.1" 200 125 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"

# php.access.log
2025-05-03T08:16:21Z GET 200 5001.693 ms 2048 kB 0.00% /slow.php
```

