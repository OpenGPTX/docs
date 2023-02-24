



# Spark-submit overview

## Scope

This documentation gives an overview about how to submit Spark jobs.

## Overview

- [Installations](#installations)
  - [Install Spark locally](#install-spark-locally)
  - [Building Spark Dockerimage](#building-spark-dockerimage)
- [1. Locally "--deploymode=client"](#1-locally-"--deploy-modeclient")
- [2. K8s "--deploy-mode=cluster"](#2-k8s-"--deploy-modecluster")
- [3. SparkOperator (SparkApplication) "mode: cluster" == "--deploy-mode=cluster"](#3-sparkoperator-sparkapplication-"mode-cluster"--"--deploy-modecluster")
- [4. KFP "mode: cluster" == "--deploy-mode=cluster"](#4-kfp-"mode-cluster"--"--deploy-modecluster")

## Installations

The documentation has not the intention to install everything and explaining all background details. Since this manual includes examples about Spark in Docker, on K8s, as SparkApplication as well as in Kubeflow pipelines (KFP), it is to much for a single doc. Apart from that, there is a lot automated on our K8s cluster in the background and does not need be explained at this point because it just works out of the box. But in order to give users the first initial guidance how to install Spark on their local laptop, it shows that Spark can be used basically everywhere.

### Install Spark locally

Sometimes it is helpful to execute Spark locally. This shows how to install Spark on Ubuntu/Linux and is based on this [tutorial](https://phoenixnap.com/kb/install-spark-on-ubuntu).  We use Spark version 3.2.1 but it can be adapted to your needs.

According to the [doc](https://spark.apache.org/docs/latest/), Spark runs on Java 8/11. That's why we install Java 11:
```
sudo apt install default-jdk -y

java --version
openjdk 11.0.15 2022-04-19
```

Let's download the according Spark version (or get the correct url to download it via `wget`) [here](https://spark.apache.org/downloads.html), move it to the correct place and adjust the environmental variables.
```
wget https://dlcdn.apache.org/spark/spark-3.2.1/spark-3.2.1-bin-hadoop3.2.tgz

tar xvf spark-3.2.1-bin-hadoop3.2.tgz
sudo mv spark-3.2.1-bin-hadoop3.2 /opt/spark

echo "export SPARK_HOME=/opt/spark" >> ~/.profile
echo "export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin" >> ~/.profile
echo "export PYSPARK_PYTHON=/usr/bin/python3" >> ~/.profile
source ~/.profile
```

Install the according pyspark version as well:
```
pip install pyspark==3.2.1
```


### Building Spark Dockerimage

The general repository to build a Spark Dockerimage can be found [here](https://github.com/OpenGPTX/docker-images). The more specific manual is located [here](https://github.com/OpenGPTX/docker-images/tree/main/spark).


## Submitting Spark

In general Spark provides 4 different types of [clusters to launch apps](https://spark.apache.org/docs/latest/#launching-on-a-cluster):
- [Standalone Deploy Mode](https://spark.apache.org/docs/latest/spark-standalone.html)
`--master spark://IP:PORT`
- [Apache Mesos](https://spark.apache.org/docs/latest/running-on-mesos.html) (deprecated)
`--master mesos://host:5050`
- [Hadoop YARN](https://spark.apache.org/docs/latest/running-on-yarn.html)
`--master yarn`
- [Kubernetes](https://spark.apache.org/docs/latest/running-on-kubernetes.html)
`--master k8s://https://<k8s-apiserver-host>:<k8s-apiserver-port>`

### More about Standalone Deploy Mode

In order to explain the "Standalone Deploy Mode" better, the following gives a rough overview but is not needed for this manual.

At first the master needs to start:
```
./sbin/start-master.sh
```
Once started, the master will print out a `spark://HOST:PORT` URL. Then one or more workers can start and connect to the master:
```
./sbin/start-worker.sh <master-spark-URL>
```

### More about general Deploy Mode

Spark only offers 2 different "Deploy Modes" in the [doc](https://spark.apache.org/docs/latest/cluster-overview.html#glossary):
- client - "the submitter launches the driver outside of the cluster" which means **the driver runs there, where you submitted the Spark job**
- cluster - "the submitter launches the driver inside of the cluster" which means **the driver runs on the cluster, where you submitted the Spark job to**


### 1. Locally "--deploy-mode=client"

Let's start with the local method. Locally means on your laptop, either in your shell (terminal) or in the Docker container. In addition to that, we devide an interactive way via `pyspark` and a non-interactive way via executing a `.py` file.

#### 1.1 Shell

##### 1.1.1 Interactive

Open pyspark to run commands interactively:
```
pyspark

data = spark.range(0, 5)
data.write.format("parquet").mode('overwrite').save("/tmp/parquet-table")

df = spark.read.format("parquet").load("/tmp/parquet-table")
df.show()

exit()
```

##### 1.1.2 .py file

Prepare the `spark.py` (e.g. via `vi`):
```
import pyspark

spark = pyspark.sql.SparkSession.builder.appName("MyApp").getOrCreate()

data = spark.range(0, 5)
data.write.format("parquet").mode('overwrite').save("/tmp/parquet-table")

df = spark.read.format("parquet").load("/tmp/parquet-table")
df.show()
```
Execute the `spark.py`:
```
python3 spark.py
```

Both ways have the same result in the end, but interactively is more for prototyping and exploration whereas `.py` files are for pipelines and productive workloads.

#### 1.2 Docker

##### 1.2.1 Interactive

Start the correct Dockerimage (you can also use your own image you build) as a container interactively:
```
docker run -it public.ecr.aws/atcommons/spark/python:14469 bash
```

After that it feels like the local way.

Open pyspark to run commands interactively:
```
/opt/spark/bin/pyspark

data = spark.range(0, 5)
data.write.format("parquet").mode('overwrite').save("/tmp/parquet-table")

df = spark.read.format("parquet").load("/tmp/parquet-table")
df.show()

exit()

exit
```

##### 1.2.2 .py file

Start the correct Dockerimage (you can also use your own image you build) as a container interactively:
```
docker run -it public.ecr.aws/atcommons/spark/python:14469 bash
```

After that it feels like the local way.

Prepare the `spark.py`:
```
cat <<'EOF' >> spark.py
import pyspark

spark = pyspark.sql.SparkSession.builder.appName("MyApp").getOrCreate()

data = spark.range(0, 5)
data.write.format("parquet").mode('overwrite').save("/tmp/parquet-table")

df = spark.read.format("parquet").load("/tmp/parquet-table")
df.show()
EOF
```

Execute the `spark.py`:
```
python3 spark.py

exit
```

As you can see, the Shell and Docker do exactly the same, but for dependency management and platform compatability, Docker is very powerful!


### 2. K8s "--deploy-mode=cluster"

Now we use K8s as a scheduler. The `--deploy-mode=cluster` means, the driver is also scheduled on the K8s cluster. If you would use `--deploy-mode=client` (is also the default value), then the driver runs whereever you start your `spark-submit` as the executors are scheduled on K8s.

Let's find out the k8s url:
```
kubectl cluster-info
Kubernetes control plane is running at https://7640C6A7C2ACEA4BC58DCD5979970938.gr7.eu-central-1.eks.amazonaws.com
```

Adjust the k8s url, the `serviceAccountName` and well as the `namespace`:
```
spark-submit \
    --master k8s://https://7640C6A7C2ACEA4BC58DCD5979970938.gr7.eu-central-1.eks.amazonaws.com \
    --deploy-mode cluster \
    --name spark-pi \
    --conf spark.executor.instances=2 \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark-spark-operator \
    --conf spark.kubernetes.namespace=spark \
    --conf spark.kubernetes.container.image=public.ecr.aws/atcommons/timsparkdeltalake:dev \
    local:///opt/spark/examples/src/main/python/pi.py
```

### 3. SparkOperator (SparkApplication) "mode: cluster" == "--deploy-mode=cluster"

The SparkOperator is the most native way on K8s. It adds some metrics for monitoring and includes `restartPolicy` as an example.
If you used `spark-submit` in the past, the config in the SparkApplication feels different but in the end you can do pretty much the same configs. A very good guide/doc/explaination can be found [here](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/master/docs/user-guide.md).

In order to make it easy, we use the namespace `spark` where the SparkOperator is located, and we use the ServiceAccount `spark-spark-operator` which has more than enough permissions. This eliminates the some requirements but it is definitely not recommened to run workloads in the namespace of the SparkOperator.
```
cat <<EOF | kubectl apply -f -
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: pyspark-pi
  namespace: spark
spec:
  type: Python
  pythonVersion: "3"
  mode: cluster
  image: "public.ecr.aws/atcommons/spark/python:14469"
  imagePullPolicy: Always
  mainApplicationFile: local:///opt/spark/examples/src/main/python/pi.py
  sparkVersion: "3.2.1"
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
      version: 3.2.1
    serviceAccount: spark-spark-operator
  executor:
    cores: 2
    instances: 1
    memory: "512m"
    labels:
      version: 3.2.1
EOF

kubectl get SparkApplication -n spark
kubectl get pods -n spark
kubectl describe SparkApplication -n spark pyspark-pi
kubectl delete SparkApplication -n spark pyspark-pi
```

You can see after 1 minute that the SparkOperator creates the spark-driver and then the spark-driver creates the according spark-executors.

### 4. KFP "mode: cluster" == "--deploy-mode=cluster"

The difference to the previous step is, that the SparkApplication gets created by the Kubeflow pipeline (KFP) and not via kubectl anymore. As you can see, it's exactly like the `.yaml` but now its a python/json format.

In an `.ipynb`, adjust `<your-namespace>`:
```
from kfp import dsl, compiler, components

resource = {
    "apiVersion": "sparkoperator.k8s.io/v1beta2",
    "kind": "SparkApplication",
    "metadata": {
        "name": "boop-s3a",
        "namespace": "<your-namespace>"
    },
    "spec": {
        "type": "Python",
        "mode": "cluster",
        "image": "public.ecr.aws/atcommons/spark/python:latest",
        "imagePullPolicy": "Always",
        "mainApplicationFile": "local:///opt/spark/examples/src/main/python/pi.py",
        "sparkVersion": "3.2.1",
        "restartPolicy": {
            "type": "Never"
        },
        "driver": {
            "cores": 1,
            "coreLimit": "1200m",
            "memory": "512m",
            "labels": {
                "version": "3.2.1",
            },
            "serviceAccount": "default-editor",
        },
        "executor": {
            "cores": 1,
            "instances": 1,
            "memory": "512m",
        },
    }
}

@dsl.pipeline(name="spark_pipeline", description="No need to ask why.")
def local_pipeline():

    rop = dsl.ResourceOp(
        name="spark",
        k8s_resource=resource,
        action="create",
        success_condition="status.applicationState.state == COMPLETED"
    )

compiler.Compiler().compile(local_pipeline, "./spark_application.yaml")
```

Start the file `./spark_application.yaml` in kubeflow pipelines. It has 1 step which launches the SparkApplication, and then its the same like an usual SparkApplication which gets picked up after 1 minute by the SparkOperator, which creates the spark-driver and then the spark-driver creates the according spark-executors.