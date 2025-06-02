# Platform.sh Debugging Outages and Performance Issues

- A guide on how to investigate and debug outages and performance issues on https://platform.sh/

## Prerequisites

- Understand your setup
    - Any CDNs (e.g. Fastly / Cloudflare) in from of the Platform.sh origin
    - If the environment is on [DG2](https://docs.platform.sh/dedicated-environments/dedicated-gen-2/overview.html) / [DG3](https://docs.platform.sh/dedicated-environments/dedicated-gen-3/overview.html) / [Grid](https://docs.platform.sh/glossary.html#grid) (See more in  [`infrastructure-setup.md`](./infrastructure-setup.md))
- How to SSH/access your environments:[`access-application-services-nodes.md`](./access-application-services-nodes.md)


## Step by step Guide
- Check for any recent changes that could be contributing to change
- SSH into application / nodes
- Check metrics for clues
    - [DG2] / [DG3] : `nproc`, `uptime`, `top`
    - [Grid] :  `top`
    - Platform [metrics](https://docs.platform.sh/increase-observability/metrics.html) `platform metrics`
    - Platform [HTTP metrics](https://docs.platform.sh/increase-observability/metrics/http-metrics.html)
    - Any 3rd party metrics integrated e.g. New Relic
- Run script to analyze recent logs: [`dg2.sh`](./dg2.sh) / [`grid.sh`](./grid.sh)
    - Check for recent IPs / IP ranges (`access.log`)
    - Check for user agents (`access.log`)
    - Check for slow app requests (`php.access.log`)
- Possible resolutions steps
    - Block malicious traffic
    - Restart application to clear up stuck / slow connects as a temporary workaround
    - Review application and service configurations to see what optimizations can be done
    - Upsize to provide more resources

## Typical scenarios and possible issues

#### [DG2] High CPU on a single core node
- Possibly DB master node doing a lot of queries: 
    - possibly bad configuration if is doing read only queries (e.g. SELECT) as typically the secondary nodes can be used for handling these requests

#### [DG2] High CPU on 2 of the 3 core nodes
- Possibly lots of requests to DB non-master nodes doing read only requests
   - May requires indexes for better optimization

#### [Grid] [DG2] High Application CPU and RAM usage on nodes serving traffic
- Possibly slow application responses (e.g. slow DB / external connections)

#### [Grid] / [DG2] High database CPU
- Possibly slow / unoptimized DB queries

#### [Grid] / [DG2] application container / node not SSHable or SSH slow / sluggish / unresponsive  
- Possibly overloaded
- If possible kill processes that are causing the issue (possibly crons or specific application processing: PHP app can call `pkill php-fpm` to kill web processing workers which will automatically restart)
- May need to ask Platform support to kill processes or restarting node where applicable
- May need to review activity and tune systems
    - is PHP configured to use too much memory and causing excessive memory use? May need an upsize or reducing memory limits
    - may need to review PHP-FPM workers if they are using too much memory
    - may just need an upsize to hande extra load

### Possible quick fixes

- Restart the application / workers / redeploy
    - e.g. PHP: `pkill php-fpm`
- This is typically just a temporary fix as a workaround to free up long running / stuck connections / resources. There will be a bigger root issue that needs further investigation (e.g. application issue that may need optimized / malicious traffic that may need blocking)
- This should not typically be done unless you know why you're doing it (e.g. if there are lots of slow responses, this will help free up connections to respond to new connections)
---

## Links

### Basics
- [`infrastructure-setup.md`](./infrastructure-setup.md): understanding the setup of your infrastructure
- [`access-application-services-nodes.md`](./access-application-services-nodes.md): how to access / SSH into your applications

### Analysing logs
- [`log-analysis.md`](./log-analysis.md): how to analyze logs
    - [`dg2.sh`](./dg2.sh): script to run on [DG2] cluster to try quickly identify a current outage
    - [`grid.sh`](./grid.sh): script to run on [Grid] / [DG3] cluster to try quickly identify a current outage
- [`user-agents.md`](./user-agents.md): details of browser user agents
- [`http-response-codes.md`](./http-response-codes.md): details of HTTP response codes and typical issues

### Blocking Traffic

- [`blocking-traffic.md`](./blocking-traffic.md): blocking traffic via the origin and using Fastly

### Performance issues

- [`performance.md`](./performance.md): general performance issues how ways to debug
- [`queue.html`](./queue.html): visualization of nginx and PHP workers
- [`mariadb-mysql.md`](./mariadb-mysql.md): reviewing MariaDB / MySQL performance issues
