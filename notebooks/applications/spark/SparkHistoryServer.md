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

#### Advanced confugurations

##### Retention

##### All possible configurations

##### Troubleshooting

### Delete your SparkHistoryServer

Just run the following command: `kubectl delete SparkHistoryServer sparkhistoryserver`

BTW: The SparkHistoryServer is stateless that mean you can delete and create it as often as you want and it does not affect the data (spark logs). Hence it does not delete your spark logs on the S3 bucket!

## Access your own SparkHistoryServer

All you need to know is:
- The `base_url` from your cluster (typically `kubeflow.at.onplural.sh` but you can extract it from your JupyterLab Notebook url)
- and your `your_namespace` (typically it is `firstname-lastname` you can get it also with this command `echo $NAMESPACE`)

Then the correct url would be: `https://<base_url>/sparkhistory/<your_namespace>`
For me, it would be: `https://kubeflow.at.onplural.sh/sparkhistory/tim-krause`

## Using SparkHistoryServer

Since the Spark History Server is a kind of collection of all of your SparkUI's, just read the official doc for the [SparkUI](https://spark.apache.org/docs/latest/web-ui.html).

## Configure your SparkSession | SparkApplication to upload logs to the Bucket/SparkHistoryServer

In order to upload the according logs from your SparkSession or SparkApplication, you need to configure it to do so.

### SparkSession

```

```

### SparkApplication

```

```

### SparkApplication in KFP (in Kubeflow Pipelines)

```

```

