# Container Images

We run a semi-automated CI/CD pipeline for building our container images that we use to run on Kubeflow. It is located in the following GitLab repository: [https://gitlab.alexanderthamm.com/kaas/ecr-images](https://gitlab.alexanderthamm.com/kaas/ecr-images) . 

![scrum](/img/plural/container-images.png "Scrum Sprint")

The pipeline is triggered every time for all of the branches. However, the image for the respective build needs to be triggered manually via the GitLab GUI. 

The images are pushed to a public repository [Alexander Thamm GmbH (atcommons)](https://gallery.ecr.aws/atcommons/) on [AWS ECR](https://gallery.ecr.aws/). The repository is managed by the "kubeflow" AWS account (reference: [AWS Accounts](/aws-accounts/accounts-and-usage.md)).

Since some of the image have a layered architecture, it might be necessary to first build an image from the first layers, before proceecing with the target image.