# Enable access to kubeflow pipelines

currently, new users cannot select the checkbox "allow access to Kubeflow
Pipelines" as described in the [doumentation on notebooks](../notebooks/configuration.md#configurations). 
To enable this feature, a platform admin needs to apply the resource below.
Before applying, the `namespace` field in the `metadata` section has to be
replaced with the user's namespace.


```yaml
apiVersion: kubeflow.org/v1alpha1
kind: PodDefault
metadata:
  name: access-ml-pipeline
  namespace: <USER-NAMESPACE>
spec:
  desc: Allow access to Kubeflow Pipelines
  env:
    - name: KF_PIPELINES_SA_TOKEN_PATH
      value: /var/run/secrets/kubeflow/pipelines/token
  selector:
    matchLabels:
      access-ml-pipeline: 'true'
  volumeMounts:
    - mountPath: /var/run/secrets/kubeflow/pipelines
      name: volume-kf-pipeline-token
      readOnly: true
  volumes:
    - name: volume-kf-pipeline-token
      projected:
        sources:
          - serviceAccountToken:
              audience: pipelines.kubeflow.org
              expirationSeconds: 7200
              path: token
```

1.  Save the snippet above to a file (e.g. pipelines-access.yaml) and configure
    the `namespace` field corecctly.

2.  make sure kubeconfig points to the right cluster

3.  run `kubectl apply -f pipelines-access.yaml`
