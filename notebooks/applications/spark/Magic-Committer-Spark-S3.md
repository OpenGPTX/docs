# Magic Committer (for Spark with S3)

This doc should help the users to debug SparkApplications.

Since the Kubeflow dashboard does not support enough logging capabilities for SparkApplications, this manual gives a guidance how to debug it manually.

## Simply add the following config in your SparkSession if you want to enable the Magic Committer

Interactive SparkSession:
```
    "org.apache.spark:spark-hadoop-cloud_2.13:3.2.1",
    "org.apache.hadoop:hadoop-mapreduce:3.2.1",
```
```
    .config("spark.hadoop.mapreduce.outputcommitter.factory.scheme.s3a", "org.apache.hadoop.fs.s3a.commit.S3ACommitterFactory")
    .config("spark.sql.sources.commitProtocolClass", "org.apache.spark.internal.io.cloud.PathOutputCommitProtocol")
    .config("spark.sql.parquet.output.committer.class", "org.apache.hadoop.mapreduce.lib.output.BindingPathOutputCommitter")
    .config("spark.hadoop.fs.s3a.committer.name", "magic")
    .config("spark.hadoop.fs.s3a.committer.magic.enabled", "true")
```

Kubeflow Pipeline:
```

```

SparkApplication (official doc is [here](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/master/docs/user-guide.md#using-tolerations)):
```
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