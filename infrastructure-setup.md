# Infrastructure Setup

- Understanding the setup of your infrastructure will allow to drill down into which components could be at play

## CDNs and origin
- A standard project is hosted at the Platform.sh origin. It has nginx set up in from for your application
    - Thus where should always be an `access.log` from nginx
    - Application logs will be based on your setup, but standard PHP should have an `php.access.log`
- CDNs can be put in front from the origin to add a layer of protection and extra configurability

## Environment setup

- Each environment in Platform.sh can be hosted on a different architecture
    - [DG2](https://docs.platform.sh/dedicated-environments/dedicated-gen-2/overview.html)
    - [DG3](https://docs.platform.sh/dedicated-environments/dedicated-gen-3/overview.html)
    - [Grid](https://docs.platform.sh/glossary.html#grid) 
- [Overview of dedicated environments](https://docs.platform.sh/dedicated-environments/overview.html)
    - [Grid] : shared infrastructure with multiple tenants
    - [DG2] / [DG3] : dedicated infrastructure only for your projects and consists of multiple nodes (typical 3)
        - services such as the database (MySQL), message queues (RabbitMQ), key value stores (Redis / Valkey) are running on nodes 1,2 and 3
        - if you have more than 3 nodes, web traffic is typically served from nodes 4 and up
    - [DG2] is similar to a managed server setup on your own dedicated hardware
    - [DG3] is similar to the regular grid system but limited to your own project on your own dedicated hardware
- How to access your environment:  [`access-application-services-nodes.md`](./access-application-services-nodes.md)


## Making requests to the origin
- Making a request to the origin and reviewing headers can be helpful in understanding if an issue is at the origin or at the CDN level

### [Grid]
https://docs.platform.sh/development/regions.html

- Find your environment region
```
platform proj:info region
```

- Making a request to the origin
```
curl -sSD -o -/dev/null https://${GATEWAY_URL_OR_IP}/$OPTIONAL_PATH -H "Host: ${YOUR_DOMAIN}"
```
