# IONOS

### Configure your Sparksession for IONOS S3

We use the same library `spark.hadoop.fs.s3a` for IONOS S3, meaning only changes in the config are required and the file paths look the same.

**Requirements:**
- S3 bucket (eg. `opengptx-x2`)
- S3 endpoint (`spark.hadoop.fs.s3a.endpoint`) according to the region of the bucket. It can be found [here](https://docs.ionos.com/cloud/managed-services/s3-object-storage/api-how-tos). **Note: Ignore the legacy S3 endpoints.**

- Access Key and Secret Key for the bucket.

**Config:**

```python
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
    .config("spark.hadoop.fs.s3a.endpoint", "https://s3-eu-central-1.ionoscloud.com") # Change url according to bucket location
    .config("spark.hadoop.fs.s3a.path.style.access", "true")
    .config("spark.hadoop.fs.s3a.access.key", "....")
    .config("spark.hadoop.fs.s3a.secret.key", ".....")
```

Example read and write:
```python
spark.range(5).write.format("parquet").mode("overwrite").save("s3a://opengpt-x2/helloIonosS3")
spark.read.format("parquet").load("s3a://opengpt-x2/helloIonosS3").show()
```
