

# Spark Delta Lake concurrent writes on S3/Minio

## Why

1. Initially the scope was to test whether Minio can be used for Spark Delta Lake (yes, it can)
2. In addition to that we want to test concurrent writes with multiple Sparksessions/drivers using S3/Minio (does not work)

## Scope

- The idea was to reuse tests we already used in the past (to make is easy and fast)
- We use only 1 executor with 1 CPU with 8/16GB RAM per Sparksession/driver (makes it also easier)
- We cannot really test ACID complaince within a Sparksession/driver

## Paperwork

At first: Spark Delta Lake does not officially support Minio (does not mean that Minio cannot be used for Spark Delta Lake).

According to the official Spark Delta Lake [documentation](https://docs.delta.io/1.1.0/delta-storage.html#amazon-s3) it says: "Concurrent writes to the same Delta table from multiple Spark drivers can lead to data loss".
The reason is: "Delta Lake has built-in support for S3. Delta Lake supports concurrent reads from multiple clusters, but concurrent writes to S3 must originate from a single Spark driver in order for Delta Lake to provide transactional guarantees. This is because S3 currently does provide mutual exclusion, that is, there is no way to ensure that only one writer is able to create a file."

After doing this test here, we actually need to adjust the warning to: "Concurrent writes to the same Delta table from multiple Spark drivers **ALWAYS LEADS** to data loss."

Other storage technologies like Microsoft Azure storage, HDFS or Google Cloud Storage do not have that limitation.

## .ipynb

We prepared a `.ipynb` so that the tests can be easily reproduced.

## Results (delta-lake 1.1.0)

Three different people in different Sparksessions/drivers write to the same delta-table with a slight delay of about 10 seconds. To make the results easier to understand, we agreed on the following order for all tests:
1. Tim
2. Rosko
3. Salil

All in all it seems there is no difference between Minio and S3. Spark Delta Lake cannot deal with concurrent writes in different Sparksessions/drivers to the same delta-table located at S3/Minio.
Which Sparksession/driver wins in the end, seems random.

The following part has more insights.

### Minio

#### 'overwrite'

Tim:
```
ConcurrentAppendException: Files were added to the root of the table by a concurrent update. Please try the operation again.
Conflicting commit: {"timestamp":1649935818516,"operation":"WRITE","operationParameters":{"mode":Overwrite,"partitionBy":[]},"readVersion":1,"isolationLevel":"Serializable","isBlindAppend":false,"operationMetrics":{"numFiles":"2","numOutputRows":"100000000","numOutputBytes":"899097438"},"engineInfo":"Apache-Spark/3.2.0 Delta-Lake/1.1.0"}
Refer to https://docs.delta.io/latest/concurrency-control.html for more details.
```
Rosko:
```
ConcurrentAppendException: Files were added to the root of the table by a concurrent update. Please try the operation again.
Conflicting commit: {"timestamp":1649935818516,"operation":"WRITE","operationParameters":{"mode":Overwrite,"partitionBy":[]},"readVersion":1,"isolationLevel":"Serializable","isBlindAppend":false,"operationMetrics":{"numFiles":"2","numOutputRows":"100000000","numOutputBytes":"899097438"},"engineInfo":"Apache-Spark/3.2.0 Delta-Lake/1.1.0"}
Refer to https://docs.delta.io/latest/concurrency-control.html for more details.
```
Salil:
```
CPU times: user 66.7 ms, sys: 5.6 ms, total: 72.3 ms
Wall time: 2min 19s
```

#### 'append'

Tim:
```
ProtocolChangedException: The protocol version of the Delta table has been changed by a concurrent update. This happens when multiple writers are writing to an empty directory. Creating the table ahead of time will avoid this conflict. Please try the operation again.
Conflicting commit: {"timestamp":1649936255616,"operation":"WRITE","operationParameters":{"mode":Append,"partitionBy":[]},"isolationLevel":"Serializable","isBlindAppend":true,"operationMetrics":{"numFiles":"2","numOutputRows":"100000000","numOutputBytes":"899097460"},"engineInfo":"Apache-Spark/3.2.0 Delta-Lake/1.1.0"}
Refer to https://docs.delta.io/latest/concurrency-control.html for more details.
```
Rosko:
```
all fine
```
Salil:
```
ProtocolChangedException: The protocol version of the Delta table has been changed by a concurrent update. This happens when multiple writers are writing to an empty directory. Creating the table ahead of time will avoid this conflict. Please try the operation again.
Conflicting commit: {"timestamp":1649936255616,"operation":"WRITE","operationParameters":{"mode":Append,"partitionBy":[]},"isolationLevel":"Serializable","isBlindAppend":true,"operationMetrics":{"numFiles":"2","numOutputRows":"100000000","numOutputBytes":"899097460"},"engineInfo":"Apache-Spark/3.2.0 Delta-Lake/1.1.0"}
Refer to https://docs.delta.io/latest/concurrency-control.html for more details.
```

Verification:
```
read = spark.read.format("delta").load(f"s3a://deltabucket/{shared_folder}/thousand")
read.show()
read.count()

+--------+--------------+
|      id|         value|
+--------+--------------+
|50000001|rosko050000001|
|50000002|rosko050000002|
|50000003|rosko050000003|
|50000004|rosko050000004|
|50000005|rosko050000005|
|50000006|rosko050000006|
|50000007|rosko050000007|
|50000008|rosko050000008|
|50000009|rosko050000009|
|50000010|rosko050000010|
|50000011|rosko050000011|
|50000012|rosko050000012|
|50000013|rosko050000013|
|50000014|rosko050000014|
|50000015|rosko050000015|
|50000016|rosko050000016|
|50000017|rosko050000017|
|50000018|rosko050000018|
|50000019|rosko050000019|
|50000020|rosko050000020|
+--------+--------------+
only showing top 20 rows

100000000

read = spark.read.format("parquet").load(f"s3a://deltabucket/{shared_folder}/thousand")
read.show()
read.count()

+---+------------+
| id|       value|
+---+------------+
|  1|tim000000001|
|  2|tim000000002|
|  3|tim000000003|
|  4|tim000000004|
|  5|tim000000005|
|  6|tim000000006|
|  7|tim000000007|
|  8|tim000000008|
|  9|tim000000009|
| 10|tim000000010|
| 11|tim000000011|
| 12|tim000000012|
| 13|tim000000013|
| 14|tim000000014|
| 15|tim000000015|
| 16|tim000000016|
| 17|tim000000017|
| 18|tim000000018|
| 19|tim000000019|
| 20|tim000000020|
+---+------------+
only showing top 20 rows

100000000
```

- Editing 00000000000000000000.json manually:

from
```
      "path": "part-00000-e014c10a-cd8d-4dd8-a056-539a68dd8bfe-c000.snappy.parquet",

      "path": "part-00001-59a07974-21ee-4f9a-80fb-2f88fd10e10e-c000.snappy.parquet",
```
to
```
      "path": "part-00000-37e0d7a1-0b4b-4c2d-a3d5-054a6070fba8-c000.snappy.parquet",

      "path": "part-00001-6bed7b3b-482a-4025-b5e1-f485143176cc-c000.snappy.parquet",
```
leads to:
```
read = spark.read.format("delta").load(f"s3a://deltabucket/{shared_folder}/thousand")
read.show()
read.count()

+---+------------+
| id|       value|
+---+------------+
|  1|tim000000001|
|  2|tim000000002|
|  3|tim000000003|
|  4|tim000000004|
|  5|tim000000005|
|  6|tim000000006|
|  7|tim000000007|
|  8|tim000000008|
|  9|tim000000009|
| 10|tim000000010|
| 11|tim000000011|
| 12|tim000000012|
| 13|tim000000013|
| 14|tim000000014|
| 15|tim000000015|
| 16|tim000000016|
| 17|tim000000017|
| 18|tim000000018|
| 19|tim000000019|
| 20|tim000000020|
+---+------------+

100000000
```

#### Performance test

Tim:
```
ConcurrentAppendException: Files were added to the root of the table by a concurrent update. Please try the operation again.
Conflicting commit: {"timestamp":1649956119414,"operation":"CREATE OR REPLACE TABLE AS SELECT","operationParameters":{"isManaged":false,"description":null,"partitionBy":[],"properties":{}},"readVersion":0,"isolationLevel":"Serializable","isBlindAppend":false,"operationMetrics":{"numFiles":"20","numOutputRows":"4000000000","numOutputBytes":"22117827544"},"engineInfo":"Apache-Spark/3.2.0 Delta-Lake/1.1.0"}
Refer to https://docs.delta.io/latest/concurrency-control.html for more details.
```
Salil:
```
Time elapsed :  11164.677344682 s
CPU times: user 2.03 s, sys: 590 ms, total: 2.62 s
Wall time: 3h 6min 4s
```

### S3

#### 'overwrite'

Tim:
```
all fine
```
Rosko:
```
ConcurrentAppendException: Files were added to the root of the table by a concurrent update. Please try the operation again.
Conflicting commit: {"timestamp":1649941194854,"operation":"WRITE","operationParameters":{"mode":Overwrite,"partitionBy":[]},"readVersion":0,"isolationLevel":"Serializable","isBlindAppend":false,"operationMetrics":{"numFiles":"2","numOutputRows":"100000000","numOutputBytes":"895267495"},"engineInfo":"Apache-Spark/3.2.0 Delta-Lake/1.1.0"}
```
Salil:
```
ConcurrentAppendException: Files were added to the root of the table by a concurrent update. Please try the operation again.
Conflicting commit: {"timestamp":1649941194854,"operation":"WRITE","operationParameters":{"mode":Overwrite,"partitionBy":[]},"readVersion":0,"isolationLevel":"Serializable","isBlindAppend":false,"operationMetrics":{"numFiles":"2","numOutputRows":"100000000","numOutputBytes":"895267495"},"engineInfo":"Apache-Spark/3.2.0 Delta-Lake/1.1.0"}
Refer to https://docs.delta.io/latest/concurrency-control.html for more details.
```

Verification:
```
read = spark.read.format("delta").load(f"s3a://tims-delta-lake/{shared_folder}/thousand")
read.show()
read.count()

+---+------------+
| id|       value|
+---+------------+
|  1|tim000000001|
|  2|tim000000002|
|  3|tim000000003|
|  4|tim000000004|
|  5|tim000000005|
|  6|tim000000006|
|  7|tim000000007|
|  8|tim000000008|
|  9|tim000000009|
| 10|tim000000010|
| 11|tim000000011|
| 12|tim000000012|
| 13|tim000000013|
| 14|tim000000014|
| 15|tim000000015|
| 16|tim000000016|
| 17|tim000000017|
| 18|tim000000018|
| 19|tim000000019|
| 20|tim000000020|
+---+------------+
only showing top 20 rows

100000000
```

#### 'append'

Tim:
```
all fine
```
Rosko:
```
ProtocolChangedException: The protocol version of the Delta table has been changed by a concurrent update. This happens when multiple writers are writing to an empty directory. Creating the table ahead of time will avoid this conflict. Please try the operation again.
Conflicting commit: {"timestamp":1649940817008,"operation":"WRITE","operationParameters":{"mode":Append,"partitionBy":[]},"isolationLevel":"Serializable","isBlindAppend":true,"operationMetrics":{"numFiles":"2","numOutputRows":"100000000","numOutputBytes":"895267495"},"engineInfo":"Apache-Spark/3.2.0 Delta-Lake/1.1.0"}
Refer to https://docs.delta.io/latest/concurrency-control.html for more details.
```
Salil:
```
ProtocolChangedException: The protocol version of the Delta table has been changed by a concurrent update. This happens when multiple writers are writing to an empty directory. Creating the table ahead of time will avoid this conflict. Please try the operation again.
Conflicting commit: {"timestamp":1649940817008,"operation":"WRITE","operationParameters":{"mode":Append,"partitionBy":[]},"isolationLevel":"Serializable","isBlindAppend":true,"operationMetrics":{"numFiles":"2","numOutputRows":"100000000","numOutputBytes":"895267495"},"engineInfo":"Apache-Spark/3.2.0 Delta-Lake/1.1.0"}
Refer to https://docs.delta.io/latest/concurrency-control.html for more details.
```

Verification:
```
read = spark.read.format("delta").load(f"s3a://tims-delta-lake/{shared_folder}/thousand")
read.show()
read.count()

+---+------------+
| id|       value|
+---+------------+
|  1|tim000000001|
|  2|tim000000002|
|  3|tim000000003|
|  4|tim000000004|
|  5|tim000000005|
|  6|tim000000006|
|  7|tim000000007|
|  8|tim000000008|
|  9|tim000000009|
| 10|tim000000010|
| 11|tim000000011|
| 12|tim000000012|
| 13|tim000000013|
| 14|tim000000014|
| 15|tim000000015|
| 16|tim000000016|
| 17|tim000000017|
| 18|tim000000018|
| 19|tim000000019|
| 20|tim000000020|
+---+------------+
only showing top 20 rows

100000000
```

## Results (delta-lake 1.2.0)

We did the same test with delta-lake version 1.2.0 in "Single-cluster setup" on Minio again.

`append` improved in the new version. Concurrent writes are working.

`overwrite` still does not work. We get the same error message like in delta-lake version 1.1.0. 

When changing values in delta-tables, it requires an `overwrite`. `append` seems not needed in the NLP context. All in all the new version has no practical improvement for us when it comes to concurrent writes.


## Outlook

In Spark Delta Lake version 1.2.0 they added a "Multi-cluster" mode for S3. More info can be found [here](https://docs.delta.io/latest/delta-storage.html#amazon-s3). It is experimental and requires a DynamoDB (which is not possible in a datacenter) but it is worth to try.

Since Minio is not officially supported by Spark Delta Lake, we do not expect any alternative to DynamoDBLogStore provided by Databriks (support perspective), i.e. not enterprise support.

Alternatively, one needs a [LogStore](https://github.com/delta-io/delta/blob/master/storage/src/main/java/io/delta/storage/LogStore.java) (discused in [Storage configuration docs](https://docs.delta.io/latest/delta-storage.html#storage-configuration)), where the recommendation for S3 is to use DynamoDB. An option is to implement our own logstore, e.g. on PostgreSQL, MongoDB, Redis, or any other DB. This implementation probably would have no support from Delta Lake devs, but if successfull, it might get wide-spread community support.

