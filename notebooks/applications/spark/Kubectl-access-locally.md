# Kubectl access locally

## Why

Out of the box, you only have `kubectl` via your Terminal from the JupyterLab in the Kubeflow dashboard. Especially when getting logs from pipelines, SparkApplications and more, it makes sense to have `kubectl` configured with correct permission handling. This might be faster and you are able to open more terminals at the same time. It might be also possible to use tools like Lens.

## Requirements

- This manual requires Linux (e.g. Ubuntu) but can be adjusted also for Windows
- Kubectl is installed
- You have a user on our Kubeflow platform
- You have a JupyterLab in the Kubeflow dashboard (in order to extract the token)
- The JupyterLab has according permissions (is automatically handled via RBAC of the ServiceAccount `kubeflow-editor`)

## Gather information

In a terminal of your JupyterLab, run the following commands.

1. Get the token from your serviceaccount `kubeflow-editor` (**Needs to be done every day!**):
```
TOKENNAME=`kubectl get serviceaccount/default-editor -o jsonpath='{.secrets[0].name}'`
echo $TOKENNAME #verification
TOKEN=`kubectl get secret $TOKENNAME -o jsonpath='{.data.token}'| base64 --decode`
echo $TOKEN
CA=`kubectl get secret $TOKENNAME -o jsonpath='{.data.ca\.crt}'| base64 --decode`
echo $CA
```
2. Get your namespace and adjust it accordingly in this manual:
```
echo $NAMESPACE
tim-krause
```

## Setup

1. Insert your token into you local terminal:
```
TOKEN=eyJhbGciOiJSUzI1NiIsImtpZCI6IldYcE5NOXhQaXE3X3RlM05SSnI5T3FxME9vMzhDSGhmQ281ZDFfOW9vdkkifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJ0aW0ta3JhdXNlIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImRlZmF1bHQtZWRpdG9yLXRva2VuLXM5MmNsIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImRlZmF1bHQtZWRpdG9yIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiYjY3YTZlOTctNTFjNS00MTE5LTlmMDgtZTZkZjBhMzRiZDFkIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OnRpbS1rcmF1c2U6ZGVmYXVsdC1lZGl0b3IifQ.Awui61Cw-JlSTONRNEFl-i2sAST0YFIiCbZtPDasRuj9gRZFpNkFMKpgTiRuQPeCeWZ51P-BnWqpQg3W6UW-jjDtmIh2d5yIQn7jK6MesYPdy7hYt-VQKJCh8tFRpSvhYpXLJ_n0B0WfGQYlwqh1ATloNLcSUom2gzjgb1GDXGkKlBvpRsHxCmUFUIWuLJ6XVZrA0XBULa0eaICpzQVXi25CWt53Iv0_379FYXPDYoLpD6lW-ur2ZrzMncM04aQanihFojFOys09dB_i8atX9vtaGkXVasEzLMEGTNKHUbyZyzR5IEEkgWSqctJI-_miyF7k9jgk6OFh9mgnMfhufA

echo $TOKEN #verification

CA=LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1ERXhPVEUxTkRVME9Wb1hEVE15TURFeE56RTFORFUwT1Zvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTUxjCmFDYThQOGQ3K29UT2RjeGV2NjZvYXNDL2NpNWpuOWRGei9tc1U0ZnVyY2JmL29Xb0UxSDZjdjd5REFuUmIxRGgKb2lqNEFlZFRZdEhoY1lOeVdOOXdzQ3d0WEJkVStIYzhaVkhla2laSzdjWjZpdG1uanVITWRLMllMY2dKV01sZQoyTElDVURDUVNJdW9jUUdleXZ3SzdxMStIR2Q3K0RiWWV3bEQ1YmJSZVRNaFc3WEp1NG8ybG5NcThyVWg1S2VWCjlPeC9lSnU5QXI1Mkdsa0ZNcGxEVmZBSHF1N1lIU3h5M25VUjVpSzkxWkVMb0hadG42WmNiZy9LQWw5N2txZXYKNHhsQ3AxcHAwYTdFTGtWV0JtWkd1dHQ4Q1gwT0ZzLzVSZjZZcDkvWHFoWlNIbDRlbkxReFA4eGZqYmphdUJHSgpoMnIremwzZmhoVFhqNys5UnZrQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZMVTE5S1FEMXJRd3VnN3NmeFhjNEpBblp3M2VNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFBQ2VXRXN2YmR1VnlxcVdHUTdQZG9YUmxSb3FuNDRydmFPSWdJRmNwK2l6czJoak1UZApscmxOSTJzS29JWTRVa1o0TG5nL09Ec3FtRnNxMlJJMVVrc01OKzgwNHhkeWRkS0U3YWZOSG5QNUlNOVIwNzQwCnlOTGR2b2JxZWVEY1d0ckU0Y2todVJ6Rkc0anNjM1F1WDR0emcwZDFlV0ZMYjFvMTBGRVV3eWdGa0xzUzI1ajcKamx0L05xa2VpYWtCSTh0UW9pV25FdUdBTmUrMStQa05uWG5Rb3hqZHRNbVdNb1ZFWWdLN1ZwWWk4Uis0UkxWYwpxK2U4QlFmbWNaK2F5UjhaaENpakhySlVVR1BkYTBxdHU0STc1aUhzN2ZrWEZFSWtHbmhrMkRMcEdXRzQ3VlRECjVnUmRHTnZkRkVXVVdDVUM0cnlrRU05YWtVQ1JoK05JNk9oNAotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg

echo $CA #verification
echo $CA | base64 -d #verification

```
2. Setup your local kubeconfig:
```
mkdir ~/.kube
echo $CA | base64 -d > ~/.kube/ca.crt 
cat ~/.kube/ca.crt #verification
cd ~/.kube/
kubectl config set-cluster kf6 --server=https://8F2FAA484603C444B8317C965B29C48B.gr7.eu-central-1.eks.amazonaws.com --embed-certs=true --certificate-authority=ca.crt
kubectl config set-context kf6 --cluster=kf6

kubectl config set-credentials user --token=$TOKEN
kubectl config set-context kf6 --user=user
kubectl config use-context kf6
kubectl config set-context --current --namespace=tim-krause
```
3. Insert a new token (**The second command needs to be done everyday or if the token is expired!**)
```
kubectl config set-credentials user --token=$TOKEN
```
4. Verification:
```
kubectl get pods
kubectl get pods -n tim-krause #actually you dont need to specify you namespace since we set a default in your kubeconfig
```



