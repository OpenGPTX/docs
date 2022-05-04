# Spark Troubleshooting

A page with common issues and tips & tricks how to solve them

## Volumes not being deleted after Spark (zombie) session is done/closed

On rare occassions, the disk-spill volumes created by Spark do not get deleted. This usually happens due to a "unclean" shutdown of the notebook instance and the Spark session running inside, resulting in "zombie" Spark executors. They need to be manually removed. 

Here is how:
1. Open a terminal inside any Jupyter instance on the platform.
2. First list all Pods running using the command `kubectl get pod`. It should show a list of the following form:
```
(base) jovyan@spark-0:~$ kubectl get pod | grep exec
rostislav-nedelchev-spark-app-95b3dc8085631cca-exec-2   1/2     NotReady   0          16h
rostislav-nedelchev-spark-app-95b3dc8085631cca-exec-3   1/2     NotReady   0          16h
```

We are interested in the pods that have a suffix with "exec-\<number\>" (e.g. exec-2), have a Status "NotReady", and an incomplete Ready (e.g., "1/2"). There are the ones that need to be removed.

3. Remove the "zombie" pods:
```
kubectl delete pod rostislav-nedelchev-spark-app-95b3dc8085631cca-exec-2 rostislav-nedelchev-spark-app-95b3dc8085631cca-exec-3
```

***

Removing the pods should automatically remove the volumes. In case, this does not happen, the volumes can be manually, as well. To do so, follow simillar steps:

1. Open a terminal inside any Jupyter instance on the platform.
2. First list all Pods running using the command `kubectl get pvc`. It should show a list of the following form:
```
(base) jovyan@spark-0:~$ kubectl get pvc | grep exec
rostislav-nedelchev-spark-app-aa89478088dd4cc6-exec-2-pvc-0   Bound    pvc-6330337a-eeec-46e4-aa00-397073b7b497   10Gi       RWO            efs-csi        20s
rostislav-nedelchev-spark-app-aa89478088dd4cc6-exec-3-pvc-0   Bound    pvc-409bbec1-ba6c-492b-9ff2-52d5b66026d5   10Gi       RWO            efs-csi        18s
```

We are interested in the volumes containing "exec".

3. Remove old volumes:

```
kubectl delete pvc rostislav-nedelchev-spark-app-aa89478088dd4cc6-exec-2-pvc-0 rostislav-nedelchev-spark-app-aa89478088dd4cc6-exec-3-pvc-0
```
