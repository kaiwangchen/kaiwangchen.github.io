Aliyun DRDS User Guide
----------------------

_Notice that this is not an official translation, and the DRDS product is continously evolving. Any doubt please contact me._ 

_Aliyun DRDS_ (Distributed Relational Database Service) is a distributed service in front of Aliyun RDS instances. It talks the MySQL protocol, so any client application understanding MySQL is able to talk to DRDS.

## Features

* _Distributed_. DRDS facades many backing RDS nodes with a transparent distributed processing layer.
* _Multi-language support_. DRDS is a service talking in MySQL protocol, so any programming language understanding MySQL is able to talk to DRDS.
* _Full table scan_. For complex queries, DRDS parses the original SQL and generates distributed execution plan, runs real queries on proper backing RDS nodes, and merges the results.

## Connecting to DRDS

DRDS is a service talking MySQL protocol, so application connects to DRDS in the same way it connects to traditional MySQL.

### Connecting with stock mysql(1) client

    mysql -h${DRDS_IP_ADDRESS}-P${DRDS_PORT}-u${user}-p${password}-D${DRDS_DBNAME}

Where `DRDS_IP_ADDRESS`, `DRDS_PORT`, `DRDS_DBNAME` are service address, service port, and schema of the DRDS instance, repectively. `user` and `password` are credentials to authenticate the connection.

### Connecting in Java programming language

    Class.forName("com.mysql.jdbc.Driver"); 
    Connection conn = 
    DriverManager.getConnection(
        "jdbc:mysql://10.2.3.4:3306/sample_schema", 
        "sample_user",
        "sample_password"
    );
    ...
    conn.close();

Any programming language having a MySQL driver is able to connect to DRDS instances, and the compatibility has been verified.

## DRDS-compatible SQL syntax

Most of MySQL syntax are supported in DRDS: `SHOW DATABASES`, `SHOW TABLES`, `USE ${database}`, `SELECT`, `UPDATE`, `INSERT`, `REPLACE`, `DELETE`, `SHOW`, `QUIT`, etc.

### `SET` an option

Supported `SET` options are: `AUTOCOMMIT`, `TX_READ_UNCOMMITTED`, `TX_READ_COMMITTED`, `TX_REPEATED_READ`, `TX_SERIALIZABLE`, `NAMES`, `CHARACTER_SET_CLIENT`, `CHARACTER_SET_CONNECTION`, `CHARACTER_SET_RESULTS` and `SQL_MODE`.

### Show execution plan

`EXPLAIN {SELECT|UPDATE|DELETE}` can be used to a examine execution plan on DRDS.

### Browse schema

`SHOW DATABASES`, `SHOW TABLES`, `USE ${database}`

### Describe table

`DESC ${table}`, `SHOW CREATE TABLE ${table}`

### Transaction support

`START TRANSACTION`, `BEGIN` and `SAVEPOINT` are not supported yet.

### DML support

`SELECT`, `UPDATE`, `INSERT`, `REPLACE`, `DELETE` are supported.

### Miscellaneous

`LOAD DATA INFILE` is supported for tables that are not sharded. `KILL_QUERY` is not supported.

## Sharding in DRDS

_Sharding_ is a key concept in DRDS.  DRDS splits a table horizontally and spreads each split (a.k.a shard) into backing RDS nodes. A backing schema conforms to certain naming convention, and the name of each shard is same to that of the original table.

Each backing node serves a part of the whole table, so that the overall workload is scattered. The whole system exhibits linear scalablity: to increase the overall capacity, new RDS nodes can be added, and then rebalance can be performed.

### Sharding concepts

#### Sharding key

DRDS determines the placement of a row of data in a proper backing RDS node according to its sharding key calculated from values of sharding fields. In other words, rows of same sharding key will be stored in the same backing RDS. 

Each table might define its sharding key, using a single field or a combination of multiple fields.

#### Full table scan

A complex query will be dispatched to every backing node and the results merged in DRDS. However, full table scans are usually performance killers, and should be avoided.

### Sharding key using a single field

1) Sharding fields should be included in `INSERT` / `REPLACE` statements, for example:

    INSERT INTO table VALUES ('name1', 'value2')

raises error, while

    INSERT INTO table (id, name, value) VALUES (1, 'name1', 'value2')

is OK to execute.

2) If the `WHERE` clause of `SELECT` / `UPDATE` / `DELETE` does not contain the sharding field, full table scan will be performed.

### Sharding key using multiple fields

1) If the `WHERE` clause of `SELECT` / `UPDATE` / `DELETE` statements does not contain all of the sharding fields, full table scan will be performed. Only queries that contains all sharding fields are optimized.

Given sharding key using `id` and `date`,

    SELECT * FROM table WHERE id = 1 AND date > 3;

is optimized, and

    SELECT * FROM table WHERE id = 1;

needs full table scan.

2) If `WHERE` clause of `SELECT` / `UPDATE` / `DELETE` statements contains all the sharding fields, conditions of different fields must be `AND`’ed together, conditions of same field can be either `OR`ed or `AND`ed.

Given sharding key using `id` and `date`, 

    SELECT * FROM table WHERE id = 1 AND date > '2014/1/30'; 

is OK, because id and date conditions are `AND`ed.

    SELECT * FROM table WHERE id = 1 OR date > '2014/1/30';

is not OK, because they are `OR`ed together.

    SELECT * FROM table WHERE id > 1 AND date > '2014/1/30' AND date < '2014/3/1';

is OK, because they are `AND`ed together.

    SELECT * FROM table WHERE id > 1 AND (date < '2014/2/1' OR date > '2014/2/28');

is OK, because date conditions are `OR`ed, and then `AND`ed with the id condition.

3) A single sharding field can only has two `AND`ed conditions, however, the number of `OR`ed conditions are not limited.

Given sharding key using the date field,

    SELECT * FROM table WHERE date > '2014/1/30' AND date < '2014/3/1';

is OK, because there are only two date conditions `AND`ed together.

    SELECT * FROM table WHERE date > '2014/1/30' AND date < '2014/3/1' AND date < '2014/2/28';

is not OK, because there are more than two date conditions `AND`ed together.

4) A sharding field may be compared to many values, however, each same value should be used with same kind of comparison.

Given sharding key using `date`,

    SELECT * FROM table WHERE date > '2014/1/30' AND date < '2014/3/1';

is OK, because the `date` field are compared against two different values '2014/1/30' and '2014/3/1'.

    SELECT * FROM table WHERE date > '2014/1/30' AND date < '2014/1/30';

is not OK, because the same value '2014/1/30' is compared with both greater and lower operators.

5) `IN` list is supported, and the elements are `OR`ed together.

Given sharding key using `id`,

    SELECT * FROM table WHERE id IN (1, 2, 3);

is equal to

    SELECT * FROM table WHERE id = 1 OR id = 2 OR id = 3;

## Full table scan in DRDS

DRDS may perform full table scan to support aggregations. The following cautions should be noticed:

1. If the table is not sharded, any aggregation is supported, since in this case DRDS simply hands over the original SQL statements to the backing RDS node.
2. The original query might be served by a single backing RDS node, for example, the WHERE clause contains that the sharding field is equal to some value. In this case, any aggregation function is supported.
3. Full table scan: `COUNT`, `MAX`, `MIN` and `SUM` are supported; `LIKE`, `ORDER BY`, and `LIMIT` are pushed down, however, `GROUP BY` are not supported.

### 1. `COUNT`

1) `SELECT *`, `COUNT(*)` are not supported. Fields must be specified explicitly.

2) `SELECT COUNT(*) + 1` is not supported. No additional calculation are allowed.

#### 2. `ORDER BY`

1) Fields used in `ORDER BY` clause must be present in the `SELECT` list.

For example,

    SELECT c1 FROM table ORDER BY c2;

is not OK, should instead be:

    SELECT c1, c2 FROM table ORDER BY c2;

2) Pagination by `ORDER BY` and `LIMIT` are served by loading and sorting all of data `LIMIT limit` into DRDS. So, it is performance killer to do pagination by `ORDER BY` and `LIMIT` with huge amount of data.

### 3. Other aggregations

Aggregation functions other than `COUNT`, `MAX`, `MIN` and `SUM` might not return error in full table scan, however, the results might be wrong. 

### 4. `LIKE`

`LIKE` clause results in full table scan.

## DRDS Sequence

DRDS provides sequence service for application to get globally unique ID. The type of ID is `BIGINT`, whose max value is `2^63 – 1 (9223372036854775808)`. The generated IDs are increasing, but are not guaranteed to be monotone.

1. Sequence can only be created by the support team.
2. your application retrieves sequence value via a special syntax:

    SELECT DRDS_SEQ_VAL FROM ${seq};

retrives a GUID from a sequence called ${seq}

    SELECT DRDS_SEQ_VAL FROM ${seq} WHERE DRDS_SEQ_COUNT = ${count};

retrieves a batch of GUIDs from the sequence called ${seq} , and the batch size is specified by ${count}

For example, 

    SELECT DRDS_SEQ_VAL FROM SEQ_FLOW_LINE_ID_TEST WHERE DRDS_SEQ_COUNT = 10;

generates the following result:

    DRDS_SEQ_VAL
    10006001
    10006002
    10006003
    10006004
    10006005
    10006006
    10006007
    10006008
    10006009
    10006010


## DRDS Hints

### 1. Explicit sharding fields in hints

Example 1: specify a single value of the sharding field

    /!drds: $partitionOperand=('id'=['2']),$table='table'*/
    SELECT * FROM tableWHERE date > '2014/04/25';

Example 2: specify multiple values of the sharding field.

    /!drds: $partitionOperand=('id'=['2','3']),$table='table'*/
    SELECT * FROM tableWHERE date > '2014/04/25';

Example 3: specify a group of values sharding fields

    /!drds: $partitionOperand=(['id','type']=['2','a']),
    $table='table'*/
    SELECT * FROM table WHERE date > '2014/04/25'

Example 4: specify multiple groups of values of sharding fields.

    /!drds: $partitionOperand=(['id','type']=[['2','a'],['3','b']]),
    $table='table'*/
    SELECT * FROM table WHERE date > '2014/04/25';

### 2. Placeholder in hints

Example 1: specify a single place holder for sharding field id.

    /!drds: $partitionOperand=('id'=[?]),$table='table'*/
    SELECT * FROM tableWHERE date > ?;

Example 2: specify multiple place holders for sharding fields id and type.

    /!drds: $partitionOperand=(['id','type']=[?,?]),
    $table='table'*/
    SELECT * FROM table WHERE date > ?

