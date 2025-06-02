# Blocking / Rate Limit Traffic

- Understand the infrastructure setup of the environment
- Typical setups
  - CDN (e.g. Fastly) in front of Platform.sh origin
  - Regular [Grid] will only have Platform.sh origin
- Platform.sh origin
  - out of the box can only block via IPs 
  - using [a Varnish service](https://docs.platform.sh/add-services/varnish.html) will likely allow more control allowing block IPs / URLs / User Agents
- Using a CDN will allow for greater control and blocking strategies


## Identifying possible bad actors

- Check bad IP reputation 
  - Check sites like https://www.abuseipdb.com/
- Large influx of requests from 
  - same IP / IP range
  - same user agent
  - old user agents
- More information about user agents: [`user-agents.md`](./user-agents.md)
  - Before blocking ensure that the user agents are not valid ones (perhaps based on past data)
- Also be aware of your the IP of your application itself
  - [Grid] environments use the [Outbound IPs](https://docs.platform.sh/development/regions.html)
  - [DG2] / [DG3] Can also run a check on each node / instance via

### Check repuation of an IP
- Can also get use the [AbuseIP API](https://docs.abuseipdb.com/#check-endpoint) to retrieve details
```
curl -G https://api.abuseipdb.com/api/v2/check   --data-urlencode "ipAddress=127.0.0.1"   -H "Key: $ABUSEIP_TOKEN"   -H "Accept: application/json" | jq  -c '.data | [.ipAddress, .isWhitelisted, .totalReports, .abuseConfidenceScore, .isp, .usageType, .domain, .countryCode]'
```

### Identify Outgoing IP of container / node / instance
```
curl ifconfig.io
```

## Fastly

### Fastly API
- Fastly has an API that you can interact with directly or by using the [Fastly's open source CLI](https://www.fastly.com/documentation/reference/tools/cli/) (typically refered to as "Fastly CLI") to interact with it 
  - [Fastly API reference](https://www.fastly.com/documentation/reference/api/)
  - [Fastly CLI reference](https://www.fastly.com/documentation/reference/cli/)
- Platform.sh managed Fastly: [retrieving your API token](https://docs.platform.sh/domains/cdn/managed-fastly.html#retrieve-your-fastly-api-token)

### Fastly API typical workflow
- Fastly services are versioned
- Active versions cannot be typically modified directly
- Typical changes will require
  - [Retrieving current active service version](https://www.fastly.com/documentation/reference/api/services/service/#get-service)
  - [Cloning current active service version](https://www.fastly.com/documentation/reference/api/services/version/#clone-service-version)
  - Updating new service version appropriately e.g. adding a [VCL snippet](https://www.fastly.com/documentation/reference/api/vcl-services/snippet/)
  - [Activating the new version](https://www.fastly.com/documentation/reference/api/services/version/#activate-service-version) (you can also activate a previous active version if there are problems)
- [Dynamic configurations](https://www.fastly.com/documentation/guides/concepts/edge-state/dynamic-config/) can be directly updated without versioning
  - Some examples
    - [dynamic VLC snippets](https://www.fastly.com/documentation/guides/full-site-delivery/custom-vcl/using-dynamic-vcl-snippets/)
    - [ACLs](https://www.fastly.com/documentation/reference/api/acls/)
- Typical list items
  - [VCL snippets](https://www.fastly.com/documentation/reference/api/vcl-services/snippet/)
    - Each service can have multiple VCL snippets
    - Create new VCL snippet / List VCL snippets
  - [ACL](https://www.fastly.com/documentation/reference/api/acls/)
    - Each service can have multiple ACLs
      - Create new ACL / List ACLs
    - Each ACL has ACL entries
      - Add ACL entry to existing ACL
      - Edit/Delete ACL entry: List ACL entries on an ACL list to get ID for modification
  - [Dictionaries](https://www.fastly.com/documentation/reference/api/dictionaries/)
    - Each service can have multiple dictionaries
      - Create new dictionary / List dictionaries
    - Each dictionary has multiple dictionary items (each is a key value pair)
      - Add Dictionary item to existing Dictionary
      - Edit/Delete Dictionary item: List dictionary items on a dictionary to get dictionary item key to edit/delete
        
      

### Block IPs via IP block list

- https://docs.fastly.com/en/guides/using-the-ip-block-list
- If not enabled, will need to enable it
- Once enabled, there will be a `Generated_by_IP_block_list` ACL which can be modified

### Block IPs via dictionary list / ACL

- Create ACL named `blocklist`
- Add ACL entry 

```
if ( client.ip ~ blocklist) { error 403 "Forbidden"; }
```

### Block via country code

```
if ( client.geo.country_code == "US" || client.geo.country_code == "2_DIGIT_COUNTRY_CODE" ) {
  error 405 "Not allowed";
}
```

### Block Paths

```
if (req.url ~ "(?i)^/(path1/subpath1|path2/subpath2|OTHER_PATH)$") 
{
  error 405 "Not allowed";
}
```

### Block User-Agents

```
if ( req.http.User-Agent ~ "(?i)(PetalBot|SemrushBot|ANY_OTHER_USER_AGENT)" )
{
  error 405 "Not allowed";
}
```

## Blocking in Platform origin

### Via Varnish

- Blocking IPs
  - [Example of whitelisting IPs for `PURGE` requests](https://docs.platform.sh/add-services/varnish.html#clear-cache-with-a-push)
  - [Varnish example of blocking IPs and IP ranges](https://serverfault.com/questions/235841/how-do-i-block-an-ip-address-or-network-block-with-varnish-vcl)
- Blocking User Agents
  - [Varnish blog post on bot identification](https://info.varnish-software.com/blog/bot-identity-verification-in-varnish)
  - [Varnish 7.6 docs on user agent detection](https://varnish-cache.org/docs/7.6/users-guide/devicedetection.html)
- [Rate limit connections](https://docs.platform.sh/add-services/varnish.html#rate-limit-connections)

### At origin cluster

- [Block IPs via HTTP access control](https://docs.platform.sh/environments/http-access-control.html)