# MariaDB / MySQL

## Getting MySQL command line / running commands

- Use `platform sql` to get a MySQL command line
```
platform sql
```
- Use `platform sql '$QUERY'` to directly run queries
```
platform sql 'show processlist'
```

- SSH into application container `platform ssh` and use relationships to connect to the database 

```
# assumes your database relationship is named "database"
DB_HOST=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["database"][0]["host"]')
DB_USER=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["database"][0]["username"]')
DB_PASS=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["database"][0]["password"]')
DB_PATH=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["database"][0]["path"]')
DB_PORT=$(echo $PLATFORM_RELATIONSHIPS | base64 -d | jq -r '.["database"][0]["port"]')

mysql -u $DB_USER -h $DB_HOST --password="$DB_PASS" -P $DB_PORT $DB_PATH # get mysql command line

mysql -u $DB_USER -h $DB_HOST --password="$DB_PASS" -P $DB_PORT $DB_PATH -e 'show processlist;' # run commands
```

### Things to check
- Processes running
   - If there are many it could be just lots of request hitting the database or perhaps there are slow queries
- `Time` column
   - Long queries could mean unoptimized/bad queries
   - Ask your database administration to investigate
- Show brief query details of queries to see any patterns
```
show processlist
```
- Show full query details of queries to see full commands being run
```
show full processlist
```

## DB Slowness

- Many queries `Waiting for query cache lock` 
   - May need to lower / disable Query Cache
   - Consult your database adminstrators
   - [DG2] requires Platform staff to make the configuration change
- Stuck / long queries
   - Kill process that is causing them
   - Killing process in mysql (`kill query $QUERY_ID`) may not work and may require Platform staff to restart the database
- [DG2] Review database slow log
```
grep -aEi 'Time:|Query_time:' /var/log/mysql/mysql-slow.log
```
- [DG2] Check error log
```
tail -f /var/log/mysql/mysql-error.log
```

## [DG2] notes
- The typical database cluster has 3 nodes
   - 1 primary/master
   - 2 secondary nodes
- Typically the secondary nodes are used for reading data e.g. via SELECT queries
- Connecting to the default 3306 port will connect to the primary node
- Connecting to port 3307 will connect to the database running on the specific node
- If a single node is performing SELECT queries, it is likely the DB master node and some database configuration changes should be looked into using slave