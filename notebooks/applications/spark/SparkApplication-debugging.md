# SparkApplication debugging

This doc should help the users to debug SparkApplications.

Since the Kubeflow dashboard does not support enough logging capabilities for SparkApplications, this manual gives a guidance how to debug it manually.

## Jupyter terminal

It is expected to use the following commands in a jupyter terminal. First of all, it ensures correct permissions and secondly the namespace is set correctly in the background. Otherwise you need to explicitly mention the namespace with `kubectl -n $NAMESPACE ...` or `kubectl -n firstname-lastname ...`.

### "Get" SparkApplication

```
#Good for finding out the name of the SparkApplication
kubectl get sparkapplication

#Shows only the specific SparkApplication
kubectl get sparkapplication <sparkapplication-name>
NAME       STATUS   ATTEMPTS   START                  FINISH                 AGE
boop-s3a   FAILED   1          2022-04-22T08:23:09Z   2022-04-22T08:23:18Z   3d3h
```

This gives you a good overview about the status of the SparkApplication.

### "Describe" SparkApplication

To get more information about the CR SparkApplication, you can "describe" it. The "Events" (always at the bottom of the output) are normally helpful in case of basic errors that relate more to K8s or incorrect configurations.
In the following example everything is fine without any given events:

```
kubectl describe sparkapplication <sparkapplication-name>

Events:                          <none>
```

### Logs from spark-driver

The driver log shows you more details about possible errors in your application itself. Normally this is the way to go when debugging a SparkApplication. In the following case the `sparkdeltalake.py` (which should be executed) does not exist:

```
kubectl logs <sparkapplication-name>-driver

python3: can't open file '/opt/spark/examples/src/main/python/sparkdeltalake.py': [Errno 2] No such file or directory
```

Tip: you can add the `-f` flag (similar to `tail -f`) to follow the continuous logs.

### Logs from spark-executor

If the driver log is not enough, perhaps it is helpful to check the executor logs as well.

```
#Find out the name
kubectl get pods | grep exec

kubectl logs <spark-executor-name>
```

Tip: you can add the `-f` flag (similar to `tail -f`) to follow the continuous logs.

