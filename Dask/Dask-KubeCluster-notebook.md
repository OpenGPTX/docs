
# Dask with KubeCluster in a notebook

## Architecture

This is the most interactive way with Dask. The user fully controlls how many nodes, cpu and ram should be used.
The user is responsible to shutdown the Dask cluster if it is not needed anymore (in order to safe costs).
Everything can be done from the JuypterLab notebook.

This Dask setup is based on: https://kubernetes.dask.org/en/latest/kubecluster.html

## Create a notebook Server

Steps to create a notebook server can be found [here](https://github.com/KubeSoup/docs/blob/main/notebooks/configuration.md), but consider:

- Name of notebook server: `dasknotebook`
- Choose one of the below listed images as `Custom Image` as per the requirements.
```
public.ecr.aws/atcommons/notebook-servers/jupyter-dask:13345
public.ecr.aws/atcommons/notebook-servers/jupyter-dask-scipy:13345
public.ecr.aws/atcommons/notebook-servers/jupyter-dask-pytorch-full:13345
public.ecr.aws/atcommons/notebook-servers/jupyter-dask-pytorch-full:cuda-13345
public.ecr.aws/atcommons/notebook-servers/jupyter-dask-tensorflow-full:13345
public.ecr.aws/atcommons/notebook-servers/jupyter-dask-tensorflow-full:cuda-13345
```
- Choose at least 2 CPU cores and 4GB RAM for dask to function properly.

## Start a DaskCluster

This is based on: https://kubernetes.dask.org/en/latest/kubecluster.html

You can adjust cpu and memory and more as you need.

In your `.ipynb`:
```python
from dask_kubernetes import KubeCluster, make_pod_spec
from dask.distributed import Client

pod_spec = make_pod_spec(
    image='daskdev/dask:latest',
    memory_limit='6G', memory_request='6G',
    cpu_limit=2, cpu_request=2, annotations={"sidecar.istio.io/inject": "false"},
    env={'EXTRA_PIP_PACKAGES': "dask[complete] s3fs boto3 tqdm pyarrow"}, # custom packages to be installed inside the workers
    extra_pod_config={"serviceAccount": "default-editor"} # specifies to use the service account of the notebeook instance, it enables automatic S3 authentication
)

cluster = KubeCluster(pod_spec)

cluster.scale(2)
client = Client(cluster)
```

NB: Setting up the client object is critical. Without it all dask code will run locally instead on the cluster.

That creates a Dask cluster with one scheduler (`dask.org/component=scheduler`) and two workers (`dask.org/component=worker`).

It needs a couple of minutes to start. After starting it should look like this:
```bash
kubectl get pods | grep dask
dask-jovyan-760706d3-afns4q                      1/1     Running   0          2m51s
dask-jovyan-760706d3-aj62tc                      1/1     Running   0          3m19s
dask-jovyan-760706d3-axj7bf                      1/1     Running   0          2m51s
```

## Example: Dataframe

This is based on: https://examples.dask.org/dataframe.html

```python
import dask
import dask.dataframe as dd
df = dask.datasets.timeseries()

df

df.dtypes
```

## Accessing Dash dashboard (kubectl port-forward)

```bash
#Find out your dask svc:
kubectl get svc -n tim-krause | grep dask-jovyan-760706d3 #adjust your namespace and the random name of the dask cluster
dask-jovyan-760706d3-a

kubectl port-forward svc/dask-jovyan-760706d3-a 8787:8787 -n tim-krause #adjust your namespace and the random name of the dask svc

#Open in browser
http://localhost:8787
```


## How to clean up (delete the cluster)?

Options:
- Pressing "Restart the kernel" button in the notebook.
- Or delete the entire notebook (via Kubeflow UI)
