# Magic Committer (for Spark with S3)

## Why

The default committer writing with Spark on S3 uses HDFS meachanims which is inefficient on S3. Since S3 is consistent, the Magic Committer is much faster in writing. 

During our test, the Magic Committer increased the speed for ~2TB with 6 executors each 20 cores from 15 hours to 53 minutes!

So it is highly recommended to enable the Magic Committer to save compute time and therefore costs.

## Simply add the following config in your SparkSession if you want to enable the Magic Committer

Interactive SparkSession:
```
# Don't forget to load the packages:
    "org.apache.spark:spark-hadoop-cloud_2.13:3.2.1",
    "org.apache.hadoop:hadoop-mapreduce:3.2.1",
```
```
    .config("spark.hadoop.mapreduce.outputcommitter.factory.scheme.s3a", "org.apache.hadoop.fs.s3a.commit.S3ACommitterFactory") #Magic Committer
    .config("spark.sql.sources.commitProtocolClass", "org.apache.spark.internal.io.cloud.PathOutputCommitProtocol") #Magic Committer
    .config("spark.sql.parquet.output.committer.class", "org.apache.hadoop.mapreduce.lib.output.BindingPathOutputCommitter") #Magic Committer
    .config("spark.hadoop.fs.s3a.committer.name", "magic") #Magic Committer
    .config("spark.hadoop.fs.s3a.committer.magic.enabled", "true") #Magic Committer
```

Kubeflow Pipeline:
```
# Don't forget to load the packages in your .py file:
    "org.apache.spark:spark-hadoop-cloud_2.13:3.2.1",
    "org.apache.hadoop:hadoop-mapreduce:3.2.1",
```
```
    resource = {
        ...
        "spec": {
            ...
            "sparkConf": {
                ...
                "spark.hadoop.mapreduce.outputcommitter.factory.scheme.s3a": "org.apache.hadoop.fs.s3a.commit.S3ACommitterFactory", #Magic Committer
                "spark.sql.sources.commitProtocolClass": "org.apache.spark.internal.io.cloud.PathOutputCommitProtocol", #Magic Committer
                "spark.sql.parquet.output.committer.class": "org.apache.hadoop.mapreduce.lib.output.BindingPathOutputCommitter", #Magic Committer
                "spark.hadoop.fs.s3a.committer.name": "magic", #Magic Committer
                "spark.hadoop.fs.s3a.committer.magic.enabled": "true", #Magic Committer
            },
```

SparkApplication:
```
# Don't forget to load the packages:
    "org.apache.spark:spark-hadoop-cloud_2.13:3.2.1",
    "org.apache.hadoop:hadoop-mapreduce:3.2.1",
```
```
spec:
...
  sparkConf:
    ...
    "spark.hadoop.mapreduce.outputcommitter.factory.scheme.s3a": "org.apache.hadoop.fs.s3a.commit.S3ACommitterFactory"
    "spark.sql.sources.commitProtocolClass": "org.apache.spark.internal.io.cloud.PathOutputCommitProtocol"
    "spark.sql.parquet.output.committer.class": "org.apache.hadoop.mapreduce.lib.output.BindingPathOutputCommitter"
    "spark.hadoop.fs.s3a.committer.name": "magic"
    "spark.hadoop.fs.s3a.committer.magic.enabled": "true"
```