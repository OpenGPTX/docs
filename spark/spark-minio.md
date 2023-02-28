



# Using Minio instead of S3 in Spark

This manual is based on the example: 
- name of helm release `miniotimrelease` 
- within the namespace `miniotim`. 

Adjust it accordingly.

## Prepare credentials

### Login with mc cli

The `helm install ...` or `helm upgrade ...` gives you the prepared commands. You can also adjust it on your own:

- Portforwarding (adjust `miniotim` and `miniotimrelease`):
```
export POD_NAME=$(kubectl get pods --namespace miniotim -l "release=miniotimrelease" -o jsonpath="{.items[0].metadata.name}")

kubectl port-forward $POD_NAME 9000 --namespace miniotim
```

- Login (adjust `<username>` and `<password>`):
```
export MC_HOST_miniotimrelease=http://<username>:<password>@localhost:9000
```

## Create user and assign a policy

- Create user and assign a policy:
```
mc admin user add miniotimrelease newuser newuser123

mc admin policy set miniotimrelease readwrite user=newuser
```
fyi: the predefined policy `readwrite` has permissions on all buckets automatically.



## Configure your Sparksession using Minio

- Spark uses the same lib `spark.hadoop.fs.s3a` for S3 as well as Minio
- Use `spark.hadoop.fs.s3a.endpoint` to point to your Minio (internal and external way possible)
- Use spark.hadoop.fs.s3a.path.style.access because AWS S3 would use style `<bucket>.s3.Region.amazonaws.com` but minio needs `yourMinioDns.com/<bucket>`
- IRSA is not implemented for Minio, so `access.key` and `secret.key` need to be provided

### Internally via svc

If your Minio is located in the same K8s cluster as your Sparksession, use the internal way via K8s svc (service). Then the connection is faster because it does not leave the K8s cluster.
Either deactivate SSL or include the Minio cert into your truststore in order to validate the internal Minio cert.

```
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .config("spark.hadoop.fs.s3a.endpoint", "miniotimrelease.miniotim:9000") \
    .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.access.key", "username") \
    .config("spark.hadoop.fs.s3a.secret.key", "userpassword") \
```

### Externally via ingress

If your Minio is located in another K8s cluster than your Sparksession, you need to use the according DNS entry, going over the ingress controller.
This way is also good to test/use valid Minio certs (issued by LetsEncrypt).

```
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .config("spark.hadoop.fs.s3a.endpoint", "https://miniotim.dev.at.onplural.sh") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.access.key", "username") \
    .config("spark.hadoop.fs.s3a.secret.key", "userpassword") \
```

