# Spark Setup

This doc outlines the steps necessary to setup Spark with Delta Lake on Kubeflow. It allows running Spark jobs inside the notebooks.

## Create a notebook Server

Steps to create a notebook server are found [here](https://github.com/KubeSoup/docs/blob/main/notebooks/configuration.md), but consider:

1. Create notebook server

2. Choose one of the below listed images as `Custom Image` as per the requirements.

    ```
    ghcr.io/opengptx/notebook-servers/jupyter-spark:2963962927
    ghcr.io/opengptx/notebook-servers/jupyter-spark-scipy:2963962927
    ghcr.io/opengptx/notebook-servers/jupyter-spark-pytorch:2963962927
    ghcr.io/opengptx/notebook-servers/jupyter-spark-pytorch-cuda:2963962927
    ```
3. Choose at least 2 CPU cores and 8GB RAM for spark to function properly. If you intend to load bring large subsets onto the notebooks, more RAM is adviced.

4. Create a Spark Session:

    ```python
    import os
    
    # add the maven packages you want to use
    maven_packages = [
        "io.delta:delta-core_2.12:1.2.0",
        "org.apache.hadoop:hadoop-aws:3.3.1",
        # "com.johnsnowlabs.nlp:spark-nlp-spark32_2.12:3.4.3", # for sparknlp
    ]
    maven_packages = ",".join(maven_packages)
    
    os.environ["JAVA_HOME"] = "/usr/lib/jvm/default-java"
    os.environ['PYSPARK_SUBMIT_ARGS'] = f'--packages "{maven_packages}" pyspark-shell'
    
    import pyspark
    from delta import configure_spark_with_delta_pip
    
    namespace = os.environ["NAMESPACE"] # usually "firstname-lastname"
    notebook_name = os.environ["NOTEBOOK_NAME"] # might be helpful
    
    builder = (
        pyspark.sql.SparkSession.builder.appName(f"{namespace}-spark-app")
        .config("spark.kubernetes.executor.annotation.proxy.istio.io/config", '{ "holdApplicationUntilProxyStarts": true }') # To avoid healtcheck terminating loops
        .config("spark.hadoop.fs.s3a.aws.credentials.provider", "com.amazonaws.auth.WebIdentityTokenCredentialsProvider") # Either use built in authentication for S3
        # or a custom one with specific S3 Access and Secret Keys below
        # .config("spark.hadoop.fs.s3a.access.key", os.environ['AWS_S3_ACCESS_KEY']) # optional
        # .config("spark.hadoop.fs.s3a.secret.key", os.environ['AWS_S3_SECRET_KEY']) # optional
        # .config("spark.kubernetes.container.image", "public.ecr.aws/atcommons/spark/python:latest")
        # The section with `spark.kubernetes.executor.volumes.persistentVolumeClaim` is for
        # specifying the usage of a local volume to enable more storage space for Disk Spilling
        # If not need, just completely remove the properties
        # you need only to modify the necessary size for the volume under `sizeLimit`
        .config("spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.claimName", "OnDemand") # disk storage for spilling
        .config("spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.storageClass", "efs-csi") # disk storage for spilling
        .config("spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.sizeLimit", "100Gi") # disk storage for spilling
        .config("spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.path", "/data") # disk storage for spilling
        .config("spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.readOnly", "false") # disk storage for spilling
        # The section with `spark.kubernetes.node.selector` is for specifying
        # what nodes to use for the executor and in which Availability Zone (AZ)
        # They need to be in the same zone
        .config("spark.kubernetes.node.selector.topology.ebs.csi.aws.com/zone", "eu-central-1a") # node selector
        .config("spark.kubernetes.node.selector.plural.sh/scalingGroup", "xlarge-mem-optimized-on-demand") # node selector, read "Node Groups for the Spark Executors"
        # .config("spark.kubernetes.executor.podTemplateFile", "/opt/spark/conf/pod_toleration_template.yaml") # needed for bigger nodes to schedule Spark Executors on
        .config("spark.executor.instances", "2") # number of Executors
        .config("spark.executor.memory", "3g") # Executor memory
        .config("spark.executor.cores", "1") # Executor cores
    )
    
    spark = configure_spark_with_delta_pip(builder).getOrCreate()
    ```

    The default configuration for spark and environment variables are found in `/opt/spark/conf`
      - `spark-defaults.conf`: contains Spark configurations which you want to set as default, each line consists of a key and a value separated by whitespace. The configuration can be overriden if the same key is set in your Spark Session.
      - `spark-env.sh`: certain Spark settings can be configured through environment variables. We use it to set some dynamic variables in default config (like setting up namespace).

    ```
      # default config
      spark.master                                                                          k8s://https://kubernetes.default
      spark.sql.extensions                                                                  io.delta.sql.DeltaSparkSessionExtension
      spark.sql.catalog.spark_catalog                                                       org.apache.spark.sql.delta.catalog.DeltaCatalog
      spark.hadoop.fs.s3a.impl                                                              org.apache.hadoop.fs.s3a.S3AFileSystem
      spark.driver.bindAddress                                                              0.0.0.0
      spark.driver.port                                                                     2222
      spark.driver.blockManager.port                                                        7078
      spark.blockManager.port                                                               7079
      spark.kubernetes.container.image.pullPolicy                                           Always
      spark.kubernetes.container.image                                                      ghcr.io/opengptx/spark/python:pr-13
      spark.kubernetes.authenticate.driver.serviceAccountName                               default-editor
    
      # for sparkmonitor extension
      spark.extraListeners                                                                  sparkmonitor.listener.JupyterSparkMonitorListener
      spark.driver.extraClassPath                                                           /opt/conda/lib/python3.8/site-packages/sparkmonitor/listener_2.12.jar
    
      # dynamic variables set by spark-env.sh
      spark.kubernetes.namespace                                                            $NAMESPACE
      spark.driver.host                                                                     $NOTEBOOK_NAME.$NAMESPACE.svc.cluster.local
    ```

    A reference for the above used configuration can be found on the following links:
      - [Spark Configuration](https://spark.apache.org/docs/latest/configuration.html#spark-configuration) - general attributes
      - [Running on Kubernetes Configuration](https://spark.apache.org/docs/latest/running-on-kubernetes.html#configuration) - attirbutes specific to kubernetes
      - [Spark Integration with Amazon Web Services](https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/index.html) - attributes to configuring access to S3 and other AWS related services

## Node Groups for the Spark Executors

Depending on the task, one might have different resources to get the job done. For example, there are jobs where more memory is required, or others that need more computational power, i.e. CPUs. We provide the following node groups that can be defined using the `spark.kubernetes.node.selector.plural.sh/scalingGroup` configuration property.

**IMPORTANT NOTES**: 

- The VM's have overheads. First of all 32GB RAM VM's do not deliver full 32GB RAM. Secondly, Some platform components need to run on all VM's which consume little amount of resources.
- Spark adds 10% more CPU and RAM on top of what you sepcify.
- Hence keep an eye on "Max Cores in SparkSession" and "Max RAM in SparkSession" in the table below. If you specify more, the autoschedule cannot schedule according nodes as it is an impossible request.
- **Please keep an eye on the node utilization**: Let's assume you take `xlarge-mem-optimized-on-demand` (4Cores, 32GB RAM) with 2 spark-executors each 2Cores and 16GB RAM (this is just an example to make the point clear). Due to the overhead it cannot place the 2 spark-executors on the same node, so it spins up 2 nodes which are utilized with round about 55%. So 45% are idle and not used per VM. In order to improve the utilization, we have 2 options:
  - We use 2 spark-executors each 1Core and 13GB RAM (btw: Cores can only be an integer): this reduces the Cores by 100% and reduces slightly the RAM (3GB) but both spark-executors can run on the same node.
  - We use 2 spark-executors each 3Cores and 26GB RAM: it spins up 2 VM's like our initial example but you get a lot more power in your SparkSession and the utilization of the VM's is very good.
  - **All in all**, try to avoid using 50% of the VM resources per spark-executors, it idles the VM a lot!

| Group                              | Demand Type | Instances                                                | Cores | RAM (GB) | Max Cores in SparkSession | Max RAM in SparkSession | Local NVMe Storage (GB) | Toleration needed? &#10062; = yes |
| ---------------------------------- | ----------- | -------------------------------------------------------- | ----- | -------- | ------------------------- | ----------------------- | ----------------------- | --------------------------------- |
| xlarge-mem-optimized-on-demand     | On-Demand   | r5.xlarge, r5a.xlarge, r5b.xlarge, r5n.xlarge, r4.xlarge | 4     | 32       | 3                         | 26gb                    | N/A                     |                                   |
| large-mem-optimized-nvme-on-demand | On-Demand   | r5d.large, r5ad.large, r5dn.large                        | 2     | 16       | 1                         | 13gb                    | 75                      |                                   |
| xlarge-max-mem-optimized-on-demand | On-Demand   | x1e.xlarge                                               | 4     | 122      | 3                         | 106gb                   | N/A                     | &#10062;                          |
| m68xlarge-general-on-demand        | On-Demand   | m6a.8xlarge                                              | 32    | 128      | 30                        | 90gb                    | N/A                     | &#10062;                          |
| c5a16xlarge-compute-on-demand      | On-Demand   | c5a.16xlarge                                             | 64    | 128      | 61                        | 90gb                    | N/A                     | &#10062;                          |

### Adding Toleration for &#10062;

For bigger node groups we introduced a so called `taint` which needs to be explicity tollerated in the Spark configuration. Otherwise spark executors won't be scheduled onto. Look into the table above in order to find out which node group needs it.

**Simply add the following config in your Sparksession if your wanted node group is marked with &#10062; - otherwise ignore it:**

Interactive SparkSession:
```
    .config("spark.kubernetes.executor.podTemplateFile", "/opt/spark/conf/pod_toleration_template.yaml")
```

Kubeflow Pipeline: Put inside both "driver" and "executor" dictionary as shown below.
```
"driver": {
    ...
    "tolerations": [
        {
        "key": "kubesoup.com/tier",
        "operator": "Equal",
        "value": "spark-dedicated",
        "effect": "NoSchedule",
        },
    ]
}
...
"executor": {
    ...
    "tolerations": [
        {
        "key": "kubesoup.com/tier",
        "operator": "Equal",
        "value": "spark-dedicated",
        "effect": "NoSchedule",
        },
    ]
}
```
```
# Don't forget, according nodeGroup/scalingGroup needs to be defined via this config:
    resource = {
        ...
        "spec": {
            ...
            "sparkConf": {
                ...
                "spark.kubernetes.node.selector.plural.sh/scalingGroup": "c5a16xlarge-compute-on-demand",
            },
```

SparkApplication (official doc is [here](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/master/docs/user-guide.md#using-tolerations)):
```
spec:
...
  driver:
    ...
    tolerations:
    - key: kubesoup.com/tier
      operator: Equal
      value: spark-dedicated
      effect: NoSchedule
  ...
  executor:
    ...
    tolerations:
    - key: kubesoup.com/tier
      operator: Equal
      value: spark-dedicated
      effect: NoSchedule
```
```
# Don't forget, according nodeGroup/scalingGroup needs to be defined via this config:
spec:
...
  sparkConf:
    ...
    "spark.kubernetes.node.selector.plural.sh/scalingGroup": "c5a16xlarge-compute-on-demand"
```

Optional background information:
```
cat /opt/spark/conf/pod_toleration_template.yaml
apiVersion: v1
kind: Pod
spec:
  tolerations:
  - key: "kubesoup.com/tier"
    operator: "Equal"
    value: "spark-dedicated"
    effect: "NoSchedule"
```
That adds a so called `toleration` to tolerate a `tained` node. Unfortunately Spark does not support it without a template style at the moment.

## Magic Committer (for Spark on S3)

It is highly recommended to enable the Magic Committer in your SparkSessions when writing with Spark on S3 because it speeds up writing by up to x10! The manual can be found [here](https://github.com/KubeSoup/docs/blob/main/notebooks/applications/spark/Magic-Committer-Spark-S3.md).

## SparkHistoryServer

For logging, monitoring and debugging your SparkSessions and/or your SparkApplications take a look into our SparkHistoryServer [manual](https://github.com/KubeSoup/docs/blob/main/notebooks/applications/spark/SparkHistoryServer.md).

## SparkMonitor

Successful loading of the plugin would result in seeing the below INFO when starting a SparkSession
```
>>> spark = configure_spark_with_delta_pip(builder).getOrCreate()
INFO:SparkMonitorKernel:Client Connected ('127.0.0.1', 59734)
```
### Issues
There might be times if you restart the SparkSession instantly, it might be that SparkMonitor is not loaded correctly and fail with the following error.

```python
Traceback (most recent call last):
  File "/opt/conda/lib/python3.8/threading.py", line 932, in _bootstrap_inner
    self.run()
  File "/opt/conda/lib/python3.8/site-packages/sparkmonitor/kernelextension.py", line 126, in run
    self.onrecv(msg)
  File "/opt/conda/lib/python3.8/site-packages/sparkmonitor/kernelextension.py", line 143, in onrecv
    sendToFrontEnd({
  File "/opt/conda/lib/python3.8/site-packages/sparkmonitor/kernelextension.py", line 223, in sendToFrontEnd
    monitor.send(msg)
  File "/opt/conda/lib/python3.8/site-packages/sparkmonitor/kernelextension.py", line 57, in send
    self.comm.send(msg)
AttributeError: 'ScalaMonitor' object has no attribute 'comm'
```

Solution: Shutdown the kernel and close the notebook. Re-opening the notebook and running the cells should fix it.


## Culling (auto suspend after long idled notebooks)

Due to costs savings, all notebooks get into suspend mode after the kernel is idle for more than 6 hours. You can simply start your notebook within the UI again if needed. If you start your "Feierabend" or weekend, please shut them down manually and do not wait for the culling feature. Our budgets is limited and it is better to use it for calculation and training rather than for idled notebooks.
