# SparkHistoryServer

The Spark History Server is the central logging and monitoring dashboard for spark. It is exactly like the SparkUI but for all of your spark jobs.

Architecture:
- The SparkSession | SparkApplication uploads the logs onto an S3 bucket
- The Spark History Server listens that S3 bucket in order to show all information about the spark job

## Create your own SparkHistoryServer

We provide the Spark History Server as a self-serving service which means you can simply provision it by yourself if you need it. If you don't need it anymore, please delete it to free up the resources and save money (it does not delete your logs) =)

### Create a bucket folder

```
TODO
```

### CRD

It is very convinient to spin up your Spark History Server. From your JupyterLab Notebook Terminal, simply apply:
```
cat <<EOF | kubectl apply -f -
apiVersion: kubricks.kubricks.io/v1
kind: SparkHistoryServer
metadata:
  name: sparkhistoryserver
spec:
  image: public.ecr.aws/atcommons/sparkhistoryserver:14469 #It is Spark version 3.2.1
EOF
```
That's it. Give the SparkHistoryServer one minute to start and follow with [accessing the UI](#access-your-own-sparkhistoryserver).

#### Optional: background information and advanced confugurations

In the background it adds automatically a lot of default confgurations. Be careful in case of changing and ensure you know what you are doing, otherwise leave the defaults ;)

`kubectl get SparkHistoryServer sparkhistoryserver -o yaml`:
```
apiVersion: kubricks.kubricks.io/v1
kind: SparkHistoryServer
metadata:
  name: sparkhistoryserver
  namespace: <your_namespace>
spec:
  cleaner:
    enabled: true
    maxAge: 30d
  image: public.ecr.aws/atcommons/sparkhistoryserver:14469
  imagePullPolicy: IfNotPresent
  replicas: 1
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 100m
      memory: 512Mi
  serviceAccountName: default-editor
```
- By default a logrotation is enabled. It deletes all spark logs that are older than 30d
```
  cleaner:
    enabled: true
    maxAge: 30d
```
- Only use 1 replica otherwise it wastes a lot resources
```
  replicas: 1

```
- The default resources have a nice responsivness
```
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 100m
      memory: 512Mi
```
- `serviceAccountName`: It is required for according S3 permissions. Do not change it.



### Delete your SparkHistoryServer

Just run the following command: `kubectl delete SparkHistoryServer sparkhistoryserver`

BTW: The SparkHistoryServer is stateless that mean you can delete and create it as often as you want and it does not affect the data (spark logs). Hence it does not delete/cleanup your spark logs on the S3 bucket!

## Access your own SparkHistoryServer

All you need to know is:
- The `base_url` from your cluster (typically `kubeflow.at.onplural.sh` but you can extract it from your JupyterLab Notebook url)
- and your `your_namespace` (typically it is `firstname-lastname` you can get it also in your JupyterLab Notebook with this command `echo $NAMESPACE`)

Then the correct url would be: `https://<base_url>/sparkhistory/<your_namespace>`

For me, it would be: `https://kubeflow.at.onplural.sh/sparkhistory/tim-krause`

## Using SparkHistoryServer

Since the Spark History Server is a kind of collection of all of your SparkUI's, just read the official doc for the [SparkUI](https://spark.apache.org/docs/latest/web-ui.html).

## Configure your SparkSession | SparkApplication to upload logs to the Bucket/SparkHistoryServer

In order to upload the according logs from your SparkSession or SparkApplication, you need to configure it to do so.

What you need to adjust in the following sections, is:
- The `main_bucket` from your cluster (typically `at-plural-sh-at-onplural-sh-kubeflow-pipelines` but you can extract it from your JupyterLab Notebook url with the following command)
```
kubectl get cm  artifact-repositories -o yaml
...
data:
  default-v1: |-
    archiveLogs: true
    s3:
      bucket: at-plural-sh-at-onplural-sh-kubeflow-pipelines
...

```
- and your `your_namespace` (typically it is `firstname-lastname` you can get it also with this command `echo $NAMESPACE`)

Then the bucket path would be: `s3a://<main_bucket>/pipelines/<your_namespace>/history`
For me, it would be: `s3a://at-plural-sh-at-onplural-sh-kubeflow-pipelines/pipelines/tim-krause/history`

### SparkSession

Normally a lot is already configured because you use S3. Then only `spark.eventLog.enabled` and `spark.eventLog.dir` needs to be added by you. However, to make it complete:
```
    .config("spark.hadoop.fs.s3a.aws.credentials.provider", "com.amazonaws.auth.WebIdentityTokenCredentialsProvider")
    .config("spark.eventLog.enabled", "true")
    .config("spark.eventLog.dir", "s3a://<main_bucket>/pipelines/<your_namespace>/history")
```

### SparkApplication

Normally a lot is already configured because you use S3. Then only `spark.eventLog.enabled` and `spark.eventLog.dir` needs to be added by you. However, to make it complete:
```
spec:
  sparkConf:
    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
    "spark.hadoop.fs.s3a.aws.credentials.provider": "com.amazonaws.auth.WebIdentityTokenCredentialsProvider"
    "spark.eventLog.enabled": "true"
    "spark.eventLog.dir": "s3a://<main_bucket>/pipelines/<your_namespace>/history"
```


### SparkApplication in KFP (in Kubeflow Pipelines)

Normally a lot is already configured because you use S3. Then only `spark.eventLog.enabled` and `spark.eventLog.dir` needs to be added by you. However, to make it complete:
```
            "sparkConf": {
                    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem",
                    "spark.hadoop.fs.s3a.aws.credentials.provider": "com.amazonaws.auth.WebIdentityTokenCredentialsProvider"
                    "spark.eventLog.enabled": "com.amazonaws.auth.WebIdentityTokenCredentialsProvider"
                    "spark.eventLog.dir": "s3a://<main_bucket>/pipelines/<your_namespace>/history"
            },
```



## Troubleshooting

### missing required field "spec"

**error: error validating "STDIN": error validating data: ValidationError(SparkHistoryServer): missing required field "spec" in io.kubricks.kubricks.v1.SparkHistoryServer; if you choose to ignore these errors, turn validation off with --validate=false**

Probably you only specified something like:
```
cat <<EOF | kubectl apply -f -
apiVersion: kubricks.kubricks.io/v1
kind: SparkHistoryServer
metadata:
  name: sparkhistoryserver
EOF
```
But the `spec:` field is required. Take a look into the CRD section again!

### missing required field "image"

**error: error validating "STDIN": error validating data: [ValidationError(SparkHistoryServer.spec): unknown field "foo" in io.kubricks.kubricks.v1.SparkHistoryServer.spec, ValidationError(SparkHistoryServer.spec): missing required field "image" in io.kubricks.kubricks.v1.SparkHistoryServer.spec]; if you choose to ignore these errors, turn validation off with --validate=false**

Probably you only specified something like:
```
cat <<EOF | kubectl apply -f -
apiVersion: kubricks.kubricks.io/v1
kind: SparkHistoryServer
metadata:
  name: sparkhistoryserver
spec:
  foo: foo
EOF
```
But the `image:` field is required. Take a look into the CRD section again and specify the according `image`!