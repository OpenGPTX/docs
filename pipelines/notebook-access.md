# KFPipelines from within your Notebook

**Note:** These instructions assume you are accessing KF Pipelines from within 
a notebook running on the same cluster as the pipelines backend.

**Precondition:** You created your Notebook with the "Allow access to Kubeflow
Pipelines" option checked. if you have never heard about this before, please
check the [docs on notebook configuration](../notebooks/configuration.md#configurations)

## Connecting to the KF Pipelines API server

For connecting to the KF Pipelines API Server, you need two things:

-   the in cluster address of the API server, which is usually 
    `http://kubeflow-pipelines-api-server.kubeflow.svc.cluster.local:8888`

-   a JWT token for authentication. This is mounted to your notebook server if
    you started it with the "allow access to Kubeflow Pipelines" configuration.
    The token usually mounted to `/var/run/secrets/kubeflow/pipelines/token`
    which is also the value of the environment variable
    `KF_PIPELINES_SA_TOKEN_PATH`. 

To connect to the pipelines backend, you have to import the `kfp` package and
create a `kfp.Client`, passing it the address of the API server. Normally, the
KF pipelines SDK should find the token automatically. However, at the time of
writing it does not. You have to read the token and pass it when creating the
`kfp.Client`. The below example shows how to connect passing both, the server
address and the JWT token.

```python
import os

import kfp


with open(os.getenv("KF_PIPELINES_SA_TOKEN_PATH")) as f:
    token = f.read().strip()

client = kfp.Client(
    host='http://kubeflow-pipelines-api-server.kubeflow.svc.cluster.local:8888',
    existing_token=token
)
print(client.list_experiments())
```

## Defining Pipelines

For a tutorial on how to create Pipelines, check out the official guides and
our additional trainig material

-   [Kubeflow Pipelines docs](https://www.kubeflow.org/docs/components/pipelines/sdk/build-pipeline/)
-   [KubeSoup Training material](https://gitlab.alexanderthamm.com/kaas/learn-kubeflow-v2/-/tree/main/training-v2)
