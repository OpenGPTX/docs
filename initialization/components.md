# Platform components

![namespace view](/img/initialization/kubeflow-dashboard.png)

The central dashboard lets you access all components available on the platform.
The most important components are:

-   Notebook Servers: To manage Notebook servers.
-   Volumes: To manage the cluster’s Volumes.
-   Experiments (KFP): To manage Kubeflow Pipelines (KFP) experiments.
-   Pipelines: To manage KFP pipelines.

## Notebook Servers

This component allows you to configure a personal workspace on the cluster. You
can choose your required compute resources (CPU, RAM, GPU) and attach volumes
for data storage and access.

Learn how to [configure](../notebooks/configuration.md) and 
[customize](../notebooks/customization.md) your workspaces!

## Volumes

You can (and should) create Volumes independent of the Notebook servers and
attach them later. It is best practice to create an EFS Volume in the Volumes
tab and attach it to the new notebook server.

Find further details [here](../volumes/configuration.md)

## Experiments (KFP) and Pipelines

Kubeflow Pipelines (KFP) is a tool to define and orchestrate workflows on the
cluster. Each Pipeline belongs to an Experiment. To start using KFP, you first
create and experiment and later define and execute pipelines in the context of
this experiment.
