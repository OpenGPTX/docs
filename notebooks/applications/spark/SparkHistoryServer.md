# SparkHistoryServer

The Spark History Server is the central logging and monitoring dashboard for Spark. It is exactly like the SparkUI but for all of your Spark jobs.

Architecture:
- The SparkSession/SparkApplication uploads the logs onto an S3 bucket
- The Spark History Server listens that S3 bucket in order to show all information about the Spark job(s)

## Create your own SparkHistoryServer

We provide the Spark History Server as a **self-serving service** which means you can simply provision it by yourself if you need it. If you don't need it anymore, please delete it to free up the resources and save money =) (don't worry, it does not delete your logs)

### 1. Get all dynamic values/variables/names

- The `base_url` from your cluster. We assume it is `kubeflow.at.onplural.sh` but change it accordingly in this manual if needed - you can extract it from your JupyterLab Notebook url.
- The `your_namespace` which is typically `firstname-lastname`. You can get it also in your JupyterLab Notebook with this command: `echo $NAMESPACE`
- The `main_bucket` from your cluster. We assume it is `at-plural-sh-at-onplural-sh-kubeflow-pipelines` but change it accordingly in this manual if needed - but you can extract it from your JupyterLab Notebook with the following command:
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
You need those in this manual a lot!

### 2. Create a bucket folder

This step is required but needs to be done **only once** for every user.

Open a JupyterLab Notebook and just execute the following in a cell, all you need to adjust is:
- the `main_bucket` 
- and your `your_namespace`
```
!pip install boto3

import boto3

client = boto3.client('s3')

response = client.put_object(
        Bucket='at-plural-sh-at-onplural-sh-kubeflow-pipelines', #<main_bucket>
        Body='',
        Key=f'pipelines/{os.environ["NAMESPACE"]}/history/'
        )
```

### 3. CRD

It is very convenient to spin up your Spark History Server. From your JupyterLab Notebook **Terminal**, simply apply:
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
That's it. Give the SparkHistoryServer one minute to start and follow with [accessing the UI](#4-access-your-own-sparkhistoryserver).

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
- By default a logrotation is enabled. It deletes all Spark logs that are older than 30d:
```
  cleaner:
    enabled: true
    maxAge: 30d
```
- Only use 1 replica otherwise it wastes a lot resources:
```
  replicas: 1
```
- The default resources have a nice responsiveness:
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

BTW: The SparkHistoryServer is stateless. This means you can delete and create it as often as you want and it does not affect the data (Spark logs). Hence it does not delete/cleanup your Spark logs on the S3 bucket!

## 4. Access your own SparkHistoryServer

All you need to know is:
- the `base_url`
- and `your_namespace`

Then the correct url would be in general: `https://<base_url>/sparkhistory/<your_namespace>`

More specificly, for me it would be: `https://kubeflow.at.onplural.sh/sparkhistory/tim-krause`

The only missing part is to configure your SparkSession/SparkApplication, just jump to the [correct section](#5-configure-your-sparksession--sparkapplication-to-upload-logs-to-the-bucketsparkhistoryserver).


## Using SparkHistoryServer

Since the Spark History Server is a kind of collection of all of your SparkUI's, just read the official doc for the [SparkUI](https://spark.apache.org/docs/latest/web-ui.html).

## 5. Configure your SparkSession | SparkApplication to upload logs to the Bucket/SparkHistoryServer

In order to upload the according logs from your SparkSession or SparkApplication, you need to configure it to do so. What you need to adjust in the following sections, is:
- the `main_bucket` 
- and your `your_namespace`

Then the bucket path would be in general: `s3a://<main_bucket>/pipelines/<your_namespace>/history`

More specificly, for me it would be: `s3a://at-plural-sh-at-onplural-sh-kubeflow-pipelines/pipelines/tim-krause/history`

### SparkSession

Normally a lot is already configured because you use S3. Then, only `spark.eventLog.enabled` and `spark.eventLog.dir` needs to be added by you. However, to make it complete:
```
    .config("spark.hadoop.fs.s3a.aws.credentials.provider", "com.amazonaws.auth.WebIdentityTokenCredentialsProvider")
    .config("spark.eventLog.enabled", "true")
    .config("spark.eventLog.dir", f's3a://at-plural-sh-at-onplural-sh-kubeflow-pipelines/pipelines/{os.environ["NAMESPACE"]}/history') #<main_bucket>
```

### SparkApplication

Normally a lot is already configured because you use S3. Then, only `spark.eventLog.enabled` and `spark.eventLog.dir` needs to be added by you. However, to make it complete:
```
spec:
  sparkConf:
    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
    "spark.hadoop.fs.s3a.aws.credentials.provider": "com.amazonaws.auth.WebIdentityTokenCredentialsProvider"
    "spark.eventLog.enabled": "true"
    "spark.eventLog.dir": f's3a://at-plural-sh-at-onplural-sh-kubeflow-pipelines/pipelines/{os.environ["NAMESPACE"]}/history' #<main_bucket>
```


### SparkApplication in KFP (in Kubeflow Pipelines)

Normally a lot is already configured because you use S3. Then, only `spark.eventLog.enabled` and `spark.eventLog.dir` needs to be added by you. However, to make it complete:
```
            "sparkConf": {
                    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem",
                    "spark.hadoop.fs.s3a.aws.credentials.provider": "com.amazonaws.auth.WebIdentityTokenCredentialsProvider"
                    "spark.eventLog.enabled": "com.amazonaws.auth.WebIdentityTokenCredentialsProvider"
                    "spark.eventLog.dir": f's3a://at-plural-sh-at-onplural-sh-kubeflow-pipelines/pipelines/{os.environ["NAMESPACE"]}/history' #<main_bucket>
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
But the `spec:` field is required. Take a look into the [CRD section](#3-crd) again!

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
But the `image:` field is required. Take a look into the [CRD section](#3-crd) again and specify the according `image`!


### FileNotFoundException

How to identify the problem?
```
# Identify the podname
kubectl get pod | grep sparkhistoryserver

# Get the logs from the podname
kubectl logs sparkhistoryserver-7bd64db7d7-tl4hn

# Here is the specific error message to identify the problem:
Caused by: java.io.FileNotFoundException: No such file or directory: s3a://at-plural-sh-at-onplural-sh-kubeflow-pipelines/pipelines/tim-krause/history
```
How to fix? Jump to [Create a bucket folder](#2-create-a-bucket-folder).