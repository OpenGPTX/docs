# Spark Setup

This doc outlines the steps necessary to setup Spark with Delta Lake on Kubeflow. It allows running Spark jobs inside the notebooks.

## Create a notebook Server

Steps to create a notebook server are found [here](https://github.com/KubeSoup/docs/blob/main/notebooks/configuration.md), but consider:

1. Create notebook server whose **name must be: `sparknotebook`**

2. Choose one of the below listed images as `Custom Image` as per the requirements.

    ```
    public.ecr.aws/atcommons/notebook-servers/jupyter-spark:13867
    public.ecr.aws/atcommons/notebook-servers/jupyter-spark-scipy:13867
    public.ecr.aws/atcommons/notebook-servers/jupyter-spark-pytorch-full:13867
    public.ecr.aws/atcommons/notebook-servers/jupyter-spark-pytorch-full:cuda-13867
    ```
3. Choose at least 2 CPU cores and 4GB RAM for spark to function properly. If you intend to load bring large subsets onto the notebooks, more RAM is adviced. 

4. Create istio and svc preperation manually (workaround for the time being - will be automated soon)

    Please use the same naming, otherwise it would lead to a missconfiguration.

    Let's asume:
    - your notebook name (you created in the previous step) is "sparknotebook"
  
    In your notebook (JupyterLab): -> File -> New Launcher -> Terminal

    Executed the following two commands:

    **WARNING:** Executing the two commands will cause a one-time restart of the notebook instance

    Command 1:
    ```
    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: sparknotebook-spark
    spec:
      selector:
        notebook-name: sparknotebook
      ports:
        - name: driver
          protocol: TCP
          port: 2222
          targetPort: 2222
        - name: blockmanager
          protocol: TCP
          port: 7078
          targetPort: 7078
      type: ClusterIP
    EOF
    ```

    Command 2:
    ```
    kubectl patch StatefulSet sparknotebook --type='json' -p='[{"op":"add","path":"/spec/template/metadata/annotations","value":{}},{"op":"add","path":"/spec/template/metadata/annotations/traffic.sidecar.istio.io~1excludeInboundPorts","value": "7078"}]'
    ```

5. Create a Spark Session: 
    ```python
    import os
    os.environ["JAVA_HOME"] = "/usr/lib/jvm/default-java"
    os.environ['PYSPARK_SUBMIT_ARGS'] = '--packages "io.delta:delta-core_2.12:1.1.0,org.apache.hadoop:hadoop-aws:3.3.1" pyspark-shell'

    import pyspark
    from delta import configure_spark_with_delta_pip

    namespace = "user-name" # usually "firstname-lastname"

    builder = (
        pyspark.sql.SparkSession.builder.appName(f"{namespace}-spark-app")
        .master("k8s://https://kubernetes.default")
        .config("spark.kubernetes.namespace", namespace)
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
        .config("fs.s3a.aws.credentials.provider", "com.amazonaws.auth.WebIdentityTokenCredentialsProvider") # Either use built in authentication for S3
        # or a custom one with specific S3 Access and Secret Keys below
        # .config("spark.hadoop.fs.s3a.access.key", os.environ['AWS_S3_ACCESS_KEY']) # optional
        # .config("spark.hadoop.fs.s3a.secret.key", os.environ['AWS_S3_SECRET_KEY']) # optional
        .config("spark.kubernetes.authenticate.driver.serviceAccountName", "default-editor")
        .config("spark.kubernetes.container.image.pullPolicy", "Always")
        .config("spark.kubernetes.container.image", "public.ecr.aws/atcommons/spark/python:latest")
        .config("spark.driver.bindAddress", "0.0.0.0")
        .config("spark.driver.port", "2222")
        .config("spark.driver.blockManager.port", "7078")
        .config("spark.blockManager.port", "7079")
        .config("spark.kubernetes.executor.annotation.traffic.sidecar.istio.io/excludeOutboundPorts", "7078")
        .config("spark.kubernetes.executor.annotation.traffic.sidecar.istio.io/excludeInboundPorts", "7079")
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
        .config("spark.driver.host", f"sparknotebook-spark.{namespace}.svc.cluster.local")
        .config("spark.executor.instances", "2") # number of Executors
        .config("spark.executor.memory", "3g") # Executor memory
        .config("spark.executor.cores", "1") # Executor cores 
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
    )

    spark = configure_spark_with_delta_pip(builder).getOrCreate()
    ```

    A reference for the above used configuration can be found on the following links:
      - [Spark Configuration](https://spark.apache.org/docs/latest/configuration.html#spark-configuration) - general attributes
      - [Running on Kubernetes Configuration](https://spark.apache.org/docs/latest/running-on-kubernetes.html#configuration) - attirbutes specific to kubernetes
      - [Spark Integration with Amazon Web Services](https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/index.html) - attributes to configuring access to S3 and other AWS related services

## Optional: Verification of Modifications:

Run the following commands, where the expected output is shown.

1. `kubectl get svc sparknotebook-spark -o yaml`:
    ```
    spec:
      ports:
      - name: driver
        port: 2222
        protocol: TCP
        targetPort: 2222
      - name: blockmanager
        port: 7078
        protocol: TCP
        targetPort: 7078
    ```

2. `kubectl get StatefulSet sparknotebook -o yaml`:
    ```
    spec:
      template:
        metadata:
          annotations:
            traffic.sidecar.istio.io/excludeInboundPorts: "7078"
    ```


## Node Groups for the Spark Executors

Depending on the task, one might have different resources to get the job done. For example, there are jobs where more memory is required, or others that need more computational power, i.e. CPUs. We provide the following node groups that can be defined using the `spark.kubernetes.node.selector.plural.sh/scalingGroup` configuration property. 

**IMPORTANT NOTE**: Only a subset of the instances is available to the executors due to infrastructure overhead. So, only a few GBs should be requested by executors. For example, if we want to run four executors on a single `xlarge-mem-optimized-on-demand` instance, we should request 6GB per executor. Requesting 8GB would put each executor on a separate instance, which is very cost inefficcient. 

| Group                               | Demand Type | Instances                                                | Cores | RAM (GB) | Local NVMe Storage (GB) |
|-------------------------------------|-------------|----------------------------------------------------------|-------|----------|-------------------------|
| xlarge-mem-optimized-on-demand      | On-Demand   | r5.xlarge, r5a.xlarge, r5b.xlarge, r5n.xlarge, r4.xlarge | 4     | 32       | N/A                     |
| xlarge-mem-optimized-spot           | Spot        | r5.xlarge, r5a.xlarge, r5b.xlarge, r5n.xlarge, r4.xlarge | 4     | 32       | N/A                     |
| xlarge-burst-on-demand              | On-Demand   | m6i.8xlarge                                              | 4     | 16       | N/A                     |
| large-mem-optimized-nvme-on-demand  | On-Demand   | r5d.large, r5ad.large, r5dn.large                        | 2     | 16       | 75                      |
| xlarge-mem-optimized-nvme-on-demand | On-Demand   | x2iedn.xlarge                                            | 4     | 128      | 118                     |