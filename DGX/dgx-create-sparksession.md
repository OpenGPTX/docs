# Create a SparkSession on DGX

This doc shows how to use Spark on the DGX node and mentions DGX related specifics.

## YOU ARE NOT ALONE

Please keep in mind, that we only have one single DGX node. It is shared within the whole research project. 128 Cores, 256 Threads, 2TB RAM, 8 GPUs and 30TB NVME SSD are impressive but with wrong config you can block all resources. 

Also clean up your data so that everyone can work with the DGX node.

## Do not forget our doc for Kubernetes/Kubeflow

A lot of useful Spark configs can be found in our well known [doc](https://github.com/KubeSoup/docs/tree/main/notebooks/applications/spark) from our Kubernetes/Kubeflow ecosystem.

**This documentation shows more a minimal entrypoint and DGX specifics!**

## Create a notebook Server

First of all, there is no cluster and no scheduler anymore. We are dealing the the so called "deploy-mode=client" and the "cluster" is so to say "local". This means, the driver is the master and executor at the same time. So you can completely ignore `spark.executor.*` configs. And the config `spark.driver.cores` has no effect and instead it needs to be `.config("spark.master", "local[32]")` for 32 cores (in order to limit cores).

```
from pyspark.sql import SparkSession

spark = SparkSession \
    .builder \
    .appName("My SparkSession") \
    .config("spark.master", "local[32]") \
    .getOrCreate()
```

## Differences between DGX and Kubernetes/Kubeflow

### Configure Cores

As mentioned above following configs do not work in our mode:
```
    .config("spark.driver.cores", "32") \
    .config("spark.executor.cores", "32") \
```
Instead please use:
```
    .config("spark.master", "local[32]") \
```

### Configure RAM

Ram can be adjusted with driver memory like:
```
    .config("spark.driver.memory", "128g") \
```

### Tmp storage

It makes sense to use a tmp storage in your user folder. Simply create the folder and then you can configure spark to use that:
```
mkdir /home/your-user/sparktmp

    .config("spark.local.dir", "/home/your-user/sparktmp/") \
```
In case you need more than <1.8TB ("<" means possibly it can be up to 1.8 TB but the amount decreases when other users have some data somewhere on that disk) tmp storage, you can also switch to `/raid` which has up to 30 TB storage. For transperency, please create a directory fo your
```
mkdir /raid/your-user/sparktmp

    .config("spark.local.dir", "/raid/your-user/sparktmp/") \
```

### S3 Auth

There is no automatic IRSA S3 authorization. Instead you need to use S3 access-key and secret-key like:
```
    .config("spark.jars", "/opt/spark/jars/hadoop-aws-3.3.2.jar,/opt/spark/jars/aws-java-sdk-bundle-1.11.1026.jar") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .config("spark.hadoop.fs.s3a.access.key", "*******") \
    .config("spark.hadoop.fs.s3a.secret.key", "**************") \
```

## Accessing Spark UI

By default a SparkSession provides an UI under the port 4040 (might be different if another person already uses a SparkSession). Simply tunnel the port over ssh like:
```
ssh -L 4040:localhost:4040 dgx2 #assuming "dgx2" is the name configured in ~/.ssh/config
```
Then you can access the Spark UI on your laptop via: `http://localhost:4040`