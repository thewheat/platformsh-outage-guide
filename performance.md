# Performance / Slow Connections

- Slow connections will typically make the site seem slow or be considered an outage if it takes too long to responsd
- These can be hard to diagnose if they happened in the past. [Observability](https://docs.platform.sh/increase-observability.html) tools (e.g. New Relic / Blackfire) with history may be best way to see exact causes and historic data at the time
- Slow connections can be due to
    - internal services
        - Possible due to: 
            - unoptimized / bad application code / setup
            - unoptimized services (e.g. intensive database queries with no indexes) 
            - resources constraints
        - Possible resolutions: review code / setup to see what optimizations can be put in place
            - application could be modified to cache more things
            - DB queries can be reviewed by DBA for more performant queries. DB can be modified to add indexes to speed things up
            - upsize container for more resources (this can be helpful but may not solve root issue - e.g. high DB CPU usage could be due to bad queries / malicious requires to valid endpoints that perform intensive queries)
    - external services
        - Possible due to: connections to external IPs / services that are having issues
        - Possible resolutions: optimize code to have shorter timeouts
- For MySQL / MariaDB issues review [`mariadb-mysql.md`](./mariadb-mysql.md)


## Identifying slow connections

- Having observability/performance tools would be the easiest way to identify these but the section below will provide some possible hints

### Check logs / observability for slow endpoints
- Review any application logs (e.g. for PHP there is `php.access.log`) to see if there are any details on duration of requests
    - For PHP, refer to the "PHP" section below for a breakdown

### Check open connections
- Filter based on an application identifier (e.g. for PHP you can use `php`)
- Based on output may be able to see common endpoints / IPs being connected to and if it is external, it could indicate an issue with an external system

```
lsof | grep -i tcp | grep -i $APPLICATION_IDENTIFIER
```


### `strace` application process
- Running `strace` on an application process can help show some actions that it takes and may be helpful to figure out what is going on
- Find list of processes running based on your app (e.g. for PHP can use `php`)
```
ps faux | grep -i $APPLICATION_IDENTIFIER
```
- Run `strace` on matching process
```
strace -yy -s 512 -f -tt -T -p $PID
```

## MySQL / MariaDB related

- See further details ins [`mariadb-mysql.md`](./mariadb-mysql.md)

### Check DB processes
- particularly `Time` column for long standing requests

#### Get SQL command line
```
platform sql
```
#### Check all processes running
```
show processlist
```

### Check DB slow logs [DG2]

```
grep -aEi 'Time:|Query_time:' /var/log/mysql/mysql-slow.log | tail
```


## PHP


### Find recent slow PHP requests
- `php.access.log` has a column to indicate how long the response took
- It is a different column for [Grid] / [DG3] and [DG2]

#### [Grid] slow PHP responses in last 500 requests

```
tail -n 500 php.access.log | sort -n -k 4 | tail
```

#### [DG2] Slow PHP responses in last 500 requests
```
tail -n 500 php.access.log | sort -n -k 5 | tail
```

### PHP Check open connections
```
lsof | grep -i tcp | grep -i php
```

### PHP `strace` to see what it could be doing 

- Can also look at existing PHP workers / processes (e.g. crons) and `strace`
- Find PHP processes
```
ps faux | grep -i php # list php processes and get a PID to strace
```
- Run `strace` on process to inspect
```
strace -yy -s 512 -f -tt -T -p $PID 
```


### PHP-FPM workers

- PHP-FPM is configured with a max number of children/workers serving PHP

#### [DG2] - max PHP workers - for specific site
```
# where SITE is the docroot site you are investigating
grep -e '^pm.max_children' /etc/platform/SITE/php-fpm.conf 
```

#### [DG2] - max PHP workers - for all sites
```
grep -e '^pm.max_children' /etc/platform/*/php-fpm.conf 
```

#### [Grid] - max PHP workers
```
grep -e '^pm.max_children' /etc/php/*/fpm/php-fpm.conf 
```

#### Current number of workers is use
```
ps faux | grep php | grep pool | wc -l # current count in use
```
- If current number equals to max it means there will be a queue when there are further PHP queries
- If there are slow / stuck connections you can [restart PHP](https://docs.platform.sh/languages/php/tuning.html#restart-php-fpm) as a temporary workaround

```
pkill php-fpm 
```
- Where possible look at tuning / increasing PHP workers. You may need to upsize to have sufficient resources
    - https://docs.platform.sh/languages/php/tuning.html
    - https://docs.platform.sh/languages/php/fpm.html

#### PHP-FPM workers and nginx worker_connections

- Typical PHP setup has 2 kind of workers
    - Nginx worker connections
    - PHP-FPM workers
- For static requests, nginx workers will the files directly
- For application/dynamic content/PHP requests, nginx workers will call PHP-FPM workers
- Slow application/PHP requests will cause an exhaustion of PHP workers and further requests will be queued
- If current requests queue by nginx exceed total number of `worker_connections`, nginx will give a "worker_connections are not enough" error message
- [DG2] For cases like this you would not typically want to just increase nginx `worker_connections`, but identify the slow connections and optimize. You may want to increase the PHP-FPM workers (requires Platform staff to update configurations)
- See [`queue.html`](./queue.html) a visualization of nginx worker connections and PHP-FPM workers
