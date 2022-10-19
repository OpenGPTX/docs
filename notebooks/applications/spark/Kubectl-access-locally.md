# Kubectl access locally

## Why

Out of the box, you only have access on S3 via your JupyterLab in the Kubeflow dashboard. Especially when uploading data from your local laptop onto S3, it makes sense to have aws cli configured with correct permission handling. Another reason could be to execute the aws s3 commands locally which could be faster than in the JupyterLab.

## Requirements

- This manual requires Linux (e.g. Ubuntu) but perhaps can be adjusted also for Windows
- Kubectl is installed
- You have a user on our Kubeflow platform
- You have a JupyterLab in the Kubeflow dashboard (in order to extract the token)
- The JupyterLab has according permissions (is automatically handled via RBAC of the ServiceAccount `kubeflow-editor`)

## Gather information

In a terminal of your JupyterLab, run the following commands.

1. Get environmental variables for S3 config (for you its slighlty different but is constant over the time):
```
env | grep AWS
AWS_DEFAULT_REGION=eu-central-1
AWS_REGION=eu-central-1
AWS_ROLE_ARN=arn:aws:iam::776604912447:role/at-onplural-sh-kubeflow-assumable-role-ns-tim-krause
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
```
For the "Setup" later, you need to add `export ` (with a space) infront of all environmental variables.

2. Get a fresh token (**Needs to be done every day!**):
```
cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token
<you-get-the-token-here>
```

## Setup

1. Export environmental variables in your terminal (**needs to be done in any terminal where you want to use `aws s3` commands** - if not added permanently in `~/.bashrc`):
```
export AWS_DEFAULT_REGION=eu-central-1
export AWS_REGION=eu-central-1
export AWS_ROLE_ARN=arn:aws:iam::776604912447:role/at-onplural-sh-kubeflow-assumable-role-ns-tim-krause
export AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
```
In case you want to add that permanently in order to avoid that step in the future, add it at the bottom of `~/.bashrc` e.g. with the `vi` editor. **Restart your terminal that it gets loaded!**

2. Insert a new token (**The second command needs to be done everyday or if the token is expired!**)
```
# Create the folders:
sudo mkdir -p /var/run/secrets/eks.amazonaws.com/serviceaccount/

# This needs to be done everyday or if the token changes - don't forget to use the new token you got in "Gather information":
sudo bash -c 'cat << EOF > /var/run/secrets/eks.amazonaws.com/serviceaccount/token 
eyJhbGciOiJSUzI1NiIsImtpA0N2E4MDIwNWZjZDY5ODY3ZWI0OWExOWE3NzE2Zjg4Y2U0MmQifQ.eyJhdWQiOlsic3RzLmImlzcyI6Imh0dHBzOi8vb2lkYy5la3MuZXUtY2VudHJhbC0xLmFtYXpvbmF3cy5jb20vaWQvOEYyRkFBNDg0NjAzQzQ0NEI4MzE3Qzk2NUIyOUM0OEIiLCJrdWJlcm5ldGVzLmlvIjp7Im5hbWVzcGFjZSI6Im5vcmZXJ2aWNlYWNjb3VudCI6eyJuYW1lIjoiZGVmYXVsdC1lZGl0b3IiLCJ1aWQiOiI2OTZlZjk2OC02YjU2LTQ0NzktYTc5Yi0xZDI0ZmMzNzdjZjkifX0sIm5iZiI6MTY2NTAzODk1Miwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Om5vcmEtZWljaGZlbGR0OmRlZmF1bHQtZWRpdG9yIn0.oSWfBdOkKK0S8Uo1ARAmeQEl4wZiyXADupzhi_Fg7xKhB-OoQKXJO_MEchKEGeAS3GkVtNexFVGHj_pTWmwNuXG3h3aqLSx0JgUKMtZHjPahVl-loQChulWp5RSjvSUpekWt08Tnm_b-9JemTcKOB2PrR64WL-5r16XuSLFAo6-Ox4C4c0rSUcp3hjSQBHgXB9R6dYwCDTW4BhqpDb2GcLXGv73Z1ODNuivzWYtx9be6A3xLg4d0vO--KHJ2Z9-V38P4llA
EOF'

# See the content, just to be sure:
cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token
```
3. Verification:
```
aws s3 ls s3://opengptx/
# You should see the folders of the bucket here.
```