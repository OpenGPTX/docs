# Spark History Server

This doc shows how to set up a Spark History Server in order to see previous SparkSession logs. It also describes how to configure your SparkSession to "upload" the logs to the Spark History Server.


## Create a directory for the logs

```
mkdir ~/sparkhistoryserverlogs
```

## Create a Spark History Server config

```
echo "spark.history.fs.logDirectory      $HOME/sparkhistoryserverlogs" >> ~/spark/conf/history-server.conf
```

## Start Spark History Server

```
start-history-server.sh --properties-file ~/spark/conf/history-server.conf
```

Stopping Spark History Server can be done via:
```
stop-history-server.sh
```

## Receive logs from Spark History Server e.g. for getting the port

After you started the Spark History Server it outputs the location of the log file, like:
```
tail -f $HOME/spark/logs/spark-tim-krause-org.apache.spark.deploy.history.HistoryServer-1-DGX2.out
```

## Temporarily: Configure SparkSession to upload logs to the Spark History Server

To enable the eventlogging temporarily, just add the following config in your SparkSession:
```
    .config("spark.eventLog.enabled", True) \
    .config("spark.eventLog.dir", f"{HOME}/sparkhistoryserverlogs") \
```

## Permanent: Configure SparkSession to upload logs to the Spark History Server

You can also add the config permanentely:
```
touch $HOME/spark/conf/spark-defaults.conf
vi ~/spark/conf/spark-env.sh
SPARK_CONFIG_FILE="$HOME/spark/conf/spark-defaults.conf"
echo "spark.eventLog.enabled      True" >> $SPARK_CONFIG_FILE
echo "spark.eventLog.dir          $HOME/sparkhistoryserverlogs" >> $SPARK_CONFIG_FILE
```

## Accessing Spark History Server UI

By default a Spark History Server provides an UI under the port 18080 (might be different if another person already uses a Spark History Server). Simply tunnel the port over ssh like:
```
ssh -L 18080:localhost:18080 dgx2 #assuming "dgx2" is the name configured in ~/.ssh/config
```
Then you can access the Spark History Server UI on your laptop via: `http://localhost:18080`