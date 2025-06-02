# HTTP Response Codes

- HTTP response codes are returned at each step of your [infrastructure setup](./infrastructure-setup.md)
- On the Platform origin, this can be seen in the nginx `access.log` and application logs if they exist (e.g. for PHP there is `php.access.log`)
- There are standard HTTP responses (e.g. HTTP 200 typically means a good response and all things, HTTP 400 typically means a bad request due to incorrect/incomplete data provided by the client) but the common outage related errors are shown below

## HTTP 502 Bad gateway

- Typically indicates overloaded with traffic. [Related Platform.sh docs](https://docs.platform.sh/development/troubleshoot.html#http-responses-502-bad-gateway-or-503-service-unavailable)
- Large influx of traffic / application issues causing slow responses and requests to queue up until there are no more free workers resulting in this error
- Resolution steps, where applicable
   - Do appropriate [log analysis](./`log-analysis`)
   - [Block traffic](./blocking-traffic.md)
   - Review possible [performance issues](./performance.md)
- Another possibility are request gets killed at application 
   - during PHP segfaults (check `php5-fpm.log`) 
   - or application being restarted (e.g. `pkill php-fpm` - this should mean only a temporary HTTP 502 response)
- Could be indicative of the backend not running to accept requests
   - SSH into application and run `sv start app` / `systemctl --user start app`
   - Should not typically happen and depending on issue may need Platform staff to investigate further


## HTTP 503 response

- Commonly from maintenance mode 
   - set on the application itself (e.g. [Magento](https://experienceleague.adobe.com/en/docs/commerce-operations/installation-guide/tutorials/maintenance-mode#enable-or-disable-maintenance-mode-1) / [Drupal](https://www.drupal.org/docs/user_guide/en/extend-maintenance.html))
      - Check application access logs e.g. `php.access.log` to verify if application is returning `503`
   - set in the CDNs (e.g. [Fastly custom response](https://www.fastly.com/documentation/guides/full-site-delivery/responses/creating-error-pages-with-custom-responses/) / [Fastly with Magento](https://github.com/fastly/fastly-magento2/blob/master/Controller/Adminhtml/FastlyCdn/Maintenance/ToggleSuSetting.php))
      - Requests will not reach origin, check CDN configurations
      - Check requests from CDN vs origin
- CDNs configuration can result in HTTP 503 when there are backend issues
   - Check application access logs if available to determine origin responses e.g. HTTP 500s in `php.access.log` could result in an HTTP 503 from the CDN to the request
   - CDNS can return HTTP 503 responses if backend takes too long to respond
      - e.g. [Fastly returns 503 responses](https://www.fastly.com/documentation/guides/full-site-delivery/custom-vcl/developer-guide-errors/#increase-origin-timeouts) when things take took long. 
      - Check application access logs if available to duration of response e.g. `php.access.log` (or may need extra observability)
      - See [`performance.md`](./performance.md) for more details
      - If needed, modify CDN to wait longer (e.g. [Fastly setting `first_byte_timeout` value](https://www.fastly.com/documentation/reference/vcl/variables/backend-connection/bereq-first-byte-timeout/#longer-timeouts))


## HTTP 500 responses

- Typically an application issue but could have underlying infrastructure related issue
- Common scenarios
  - application issue: refer to application logs e.g. `app.log`
  - database ran out of space (check metrics `platform metrics`)
  - Redis / Valkey memory overloaded (check Redis memory usage and eviction)