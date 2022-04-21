# Using S3 for mainApplicationFile in SparkApplication

## Why

During the prototyping phase it is easier to have the application file (e.g. `pi.py`) located on S3 rather than compiling/building a new Dockerimage all the time after changing a piece of code. In a SparkApplication it is possible to adjust that in the `mainApplicationFile` field.

## Scope

Instead of using:
```
    mainApplicationFile: local:///opt/spark/examples/src/main/python/pi.py
```
the S3 way would look like:
```
    mainApplicationFile: s3a://tims-delta-lake/examples/pi.py
```

This documentation focuses on the pure adjustments making `s3a://` in `mainApplicationFile` possible. Especially background information about **Prerequisites** are not scope of this manual. For deeper insights, consult other parts of documentation.

## Prerequisites

- RBAC permissions are set correctly for starting a SparkApplication (usally done via `default-editor` ServiceAccount)
- RBAC permissions are set correctly for the driver to spawn the executors (usually done via `default-editor` ServiceAccount)
- If IRSA is used, correct permissions are set accordingly (usally done via `default-editor` ServiceAccount)
- Application file `pi.py` is uploaded on S3. For this manual we use two different buckets:
  - `s3://tims-delta-lake/examples/pi.py` (access_key+secret_key)
  - `s3://opengptx/examples/pi.py` (IRSA)
- `org.apache.hadoop:hadoop-aws:3.3.1` is included in the image and can be loaded automatically (correct path)

## S3 for mainApplicationFile in SparkApplication `s3a://`

In general two different authentication mechanisms are supported: either with access_key+secret_key or with IRSA. Both ways are described with the minimal configurations that are required to work. The last part shows a full SparkApplication example for a better understanding.

### Way1: access_key+secret_key

In the end we just need to configure spark to handle S3. To do so, the library for the `S3AFileSystem` needs to be loaded as well as the credentials needs to be passed.

```
  mainApplicationFile: s3a://tims-delta-lake/examples/pi.py
  sparkConf:
    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
    "spark.hadoop.fs.s3a.access.key": "AKIA4********************"
    "spark.hadoop.fs.s3a.secret.key": "DMyLZ*********************************"
```

### Way2: IRSA

For the IRSA authentication we need to add the `spark.hadoop.fs.s3a.aws.credentials.provider` and it is crucial for the `serviceAccount` of the `driver` to have the according permissions to your S3 bucket where your `pi.py` is located.

```
  mainApplicationFile: s3a://opengptx/examples/pi.py
  sparkConf:
    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
    "spark.hadoop.fs.s3a.aws.credentials.provider": "com.amazonaws.auth.WebIdentityTokenCredentialsProvider"
  driver:
    serviceAccount: default-editor #needs IRSA permissions
```

### Full SparkApplication example (no support)

As you can see, the following example uses the IRSA authentication but you can easily adjust it to use access_key+secret_key.
The example should make the integration into the SparkApplication more clear but we do not give support for it in this specific manual, especially not for the `image`:
```
cat <<EOF | kubectl apply -f -
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: pyspark-pi
  namespace: <namespace>
spec:
  type: Python
  pythonVersion: "3"
  mode: cluster
  image: "public.ecr.aws/atcommons/timsparkdeltalake:dev"
  imagePullPolicy: Always
  mainApplicationFile: s3a://opengptx/examples/pi.py
  sparkVersion: "3.2.0"
  sparkConf:
    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
    "spark.hadoop.fs.s3a.aws.credentials.provider": "com.amazonaws.auth.WebIdentityTokenCredentialsProvider"
  restartPolicy:
    type: OnFailure
    onFailureRetries: 3
    onFailureRetryInterval: 10
    onSubmissionFailureRetries: 5
    onSubmissionFailureRetryInterval: 20
  driver:
    cores: 2
    coreLimit: "2000m"
    memory: "512m"
    labels:
      version: 3.2.0
    serviceAccount: default-editor
  executor:
    cores: 2
    instances: 1
    memory: "512m"
    labels:
      version: 3.2.0
EOF
```
The `<namespace>` needs to be adjusted as well as the `mainApplicationFile`.