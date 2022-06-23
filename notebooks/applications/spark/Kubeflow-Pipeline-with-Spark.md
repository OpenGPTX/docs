# Kubeflow Pipeline with Spark

Notebooks might not be the most convinent way to run long Spark jobs.
This guide will cover how to use Spark inside Kubeflow Pipeline. There is also a [working example](./notebooks/spark_kfp_example.ipynb) available in the repo.

1. For running the pipelines from inside the notebook, we need to connect to the KF Pipelines API server. The steps are provided [here](../../../pipelines/notebook-access.md).

2. To run Spark, we need to create a `SparkApplication` in `Cluster` mode. Using the below function, one can provide the docker image (with all the needed packages already installed) and the resources needed for the drivers and executors and the `application_file` which is the script to run.

The `application_file` can be some [python file](https://github.com/OpenGPTX/docker-images/blob/main/spark/python/delta-lake-examples/num.py) already present inside the docker image (as shown in the [example](./notebooks/spark_kfp_example.ipynb)), or can be a file on s3 (eg [here](./Using-S3-SparkApplication-mainApplicationFile.md#way2-irsa)).

Docs about configuring the `SparkApplication` can be found [here](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/master/docs/user-guide.md)
and some other examples are located [here](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/tree/master/examples).

```python
namespace = os.environ["NAMESPACE"]  # firstname-lastname
docker_image = "ghcr.io/opengptx/spark/python:pr-13"

def get_resource(
        application_file : str,
        driver_cores: int,
        driver_memory_gb: int,
        executor_instances: int,
        executor_cores: int,
        executor_memory_gb: int,
    ):
    resource = {
        "apiVersion": "sparkoperator.k8s.io/v1beta2",
        "kind": "SparkApplication",
        "metadata": {
            "name": "spark-kfp",
            "namespace": namespace,
        },
        "spec": {
            "type": "Python",
            "mode": "cluster",
            "image": docker_image,
            "imagePullPolicy": "Always",
            "mainApplicationFile": application_file,
            "sparkVersion": "3.2.1",
            "restartPolicy": {
                "type": "Never"
            },
            "sparkConf": {
                    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem",
                    "spark.hadoop.fs.s3a.aws.credentials.provider": "com.amazonaws.auth.WebIdentityTokenCredentialsProvider"
            },
            "driver": {
                "cores": driver_cores,
                "coreLimit": f"{1200*driver_cores}m",
                "memory": f"{driver_memory_gb}G",
                "labels": {
                    "version": "3.2.1",
                },
                "serviceAccount": "default-editor",
            },
            "executor": {
                "cores": executor_cores,
                "instances": executor_instances,
                "memory": f"{executor_memory_gb}G",
            },
        }
    }

    return resource
```

3. Create the pipeline function
```python
@dsl.pipeline(name="spark_pipeline", description="Spark KFP Example")
def local_pipeline():
    step1 = dsl.ResourceOp(
        name="Create Numbers Dataframe",
        k8s_resource=get_resource(
            application_file="local:///opt/spark/examples/num.py",
            driver_cores=1,
            driver_memory_gb=1,
            executor_instances=1,
            executor_cores=1,
            executor_memory_gb=1
        ),
        action="apply",
        success_condition="status.applicationState.state == COMPLETED"
    )
```

4. Run the pipeline
```python
run = client.create_run_from_pipeline_func(
    local_pipeline,
    namespace=namespace,
    arguments={},
    experiment_name="Spark KFP Test",
)
print("Kubeflow Pipelines run id: {}".format(run.run_id))
```

### Debugging SparkApplication

For debugging the `SparkApplication`, please refer to the docs [here](./SparkApplication-debugging.md).
