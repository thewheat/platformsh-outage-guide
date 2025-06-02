# Accessing your application / services / nodes

- Related [`infrastructure-setup.md`](./infrastructure-setup.md)

## Identify number of apps / workers / nodes
- Most [Grid] projects will just have a single app
- [DG2] / [DG3] : multiple nodes (typical 3)
    - services such as the database (MySQL), message queues (RabbitMQ), key value stores (Redis / Valkey) are running on nodes 1,2 and 3
    - if you have more than 3 nodes, web traffic is typically served from nodes 4 and up


## Grid based environments on [Grid] & [DG3]
- You can only SSH into application and workers
- You cannot SSH into services (e.g. database)
- To [interact with services](https://docs.platform.sh/add-services.html#connect-to-a-service)
    - connect to it via a container
        - SSH into a container that connects to the service
        - retrieve credentials detailed in `$PLATFORM_RELATIONSHIPS`[https://docs.platform.sh/development/variables/use-variables.html#use-provided-variables]
        - use HTTP requests / tools in the container to interact with the container
    - connect it it from your machine using `platform:tunnel`
        - this will open a direct connection to the service and share a URL to interact with the service


### Find all SSH URLs
```
platform ssh --pipe --all
```
- If there are multiple instances / nodes, it will be prefixed with a number which indicates the instance / node number
    - Use  `-I|--instance` followed by the number to access that particular instance / node
```
platform ssh -I 3 # connect to instance / node 3
```


#### Retreive service credentials from a container
```
echo $PLATFORM_RELATIONSHIPS | base64 -d | jq .
```

#### Open up a tunnel to a service from your machine
```
platform tunnel:single
```