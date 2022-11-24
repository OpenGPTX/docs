# Spark-rapids: Spark with GPU on DGX

This documentation gives an overview how to use the DGX with Spark and GPUs. The technoligy is called spark-rapids. It gives you a brief overview how to set up everything.
## Official documentation

- The official doc of spark-rapids can be found [here](https://nvidia.github.io/spark-rapids/) 
- It provides a very helpful [FAQ](https://nvidia.github.io/spark-rapids/docs/FAQ.html)
- In case of "Gettings-Started" we need to look at [On-Prem](https://nvidia.github.io/spark-rapids/docs/get-started/getting-started-on-prem.html)
- The Plugin can be found [here](https://nvidia.github.io/spark-rapids/docs/download.html) (keep the listed requirements in your mind)

## Set up dependencies

- First check the cuda version with `nvidia-smi` it shows `CUDA Version: 11.4`
- The latest spark-rapids version on the [download page](https://nvidia.github.io/spark-rapids/docs/download.html) is `v22.10.0` which needs cuda version `11.x`, max Spark version `3.3.0` and Java 8. Download and save it accordingly:
```
wget https://repo1.maven.org/maven2/com/nvidia/rapids-4-spark_2.12/22.10.0/rapids-4-spark_2.12-22.10.0.jar -O $HOME/spark/jars/rapids-4-spark_2.12-22.10.0.jar
```
- It is needed to have the `getGpusResources.sh`:
```
mkdir $HOME/spark/sparkRapidsPlugin
wget https://github.com/apache/spark/blob/master/examples/src/main/scripts/getGpusResources.sh -O $HOME/spark/sparkRapidsPlugin/getGpusResources.sh
chmod +x $HOME/spark/sparkRapidsPlugin/getGpusResources.sh
```

## Configure your SparkSession accordingly

For more info and details look into [On-Prem](https://nvidia.github.io/spark-rapids/docs/get-started/getting-started-on-prem.html) doc. To be more specific, we use the [Local Mode](https://nvidia.github.io/spark-rapids/docs/get-started/getting-started-on-prem.html#local-mode).

Add at least the following config to your SparkSession:
```
    .config("spark.plugins", "com.nvidia.spark.SQLPlugin") \
    .config("spark.worker.resource.gpu.discoveryScript", "${HOME}/spark/sparkRapidsPlugin/getGpusResources.sh) \
    .config("jars", "${HOME}/spark/jars/rapids-4-spark_2.12-22.10.0.jar") \
```

All configs can be found in the official [doc](https://nvidia.github.io/spark-rapids/docs/configs.html).

## GPU usage

The command `nvidia-smi` is very useful to see the current utilization of all GPUs.

## Limitations

- Currently it is only possible to use only 1 GPU for the SparkSession. The reason is described [here](https://nvidia.github.io/spark-rapids/docs/FAQ.html#why-are-multiple-gpus-per-executor-not-supported). Unfortunately it is also not possible to use multiple executors each with 1 GPU on the same node (DGX).