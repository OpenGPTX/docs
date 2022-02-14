# Notebook configuration

## 1. Provide a name and select a namespace

![name and namespace](/img/notebooks/name.png)

-   name: Give your Notebook Server a name to identify it in the list of 
    Notebook Servers later.
-   namespace: This will be automatically filled with your personal 
    namespace. It indicates in which context the Notebook Server will be
    launched.

## 2. Select an image to start the notebook from

![image](/img/notebooks/image.png)

This defines your later working environment. Choose an image that fits your
specific needs to limit the amount of time you spend on the setup of you
environment. You can use one of the provided image or use any custom image.

-   Provided image: For example, you can choose “Jupyter Scipy” that comes 
    with a set of software preinstalled suitable for most data science 
    projects. Depending on your requirements, you can also choose images
    for Jupyter Notebook with additional configurations (e.g. Tensorflow 
    GPU), Visual Studio Code or R Studio.

-   Custom image: Here you can choose a custom image, e.g. the project 
    specific image which will have a software configuration that was tuned
    to the needs of the project. (you need to check “Custom Image”)

## 3. Define your CPU and RAM requirements

![select CPU and RAM](/img/notebooks/select-cpu-and-ram.png)

Normally, 1 CPU in your Notebook should be enough, because many data 
science packages are single core solutions. For example: pandas usually 
don’t use more than one core so it does not make sense to create a notebook
with more than 1 CPU. Only pick more than 1 CPU if you know that you can/
have to leverage multi-core parallelization.

The amount of memory required has to be estimated per use case.

## 4. Gain superpowers with GPUs

![select GPU](/img/notebooks/select-gpu.png)

In case you want to train Deep Learning Models, you can configure your 
notebook to launch on a GPU instance. In this case, also pay attention to
the section about tolerations.

## 5. Configure your workspace volume

![workspace volume](/img/notebooks/workspace-volume.png)

The workspace volume is the home directory of your working environment.
You can either create a new volume, attach an existing volume or opt out
of creating a persistent storage. The size of a new volume is configurable.
Volumes can have different read/write modes:

-   ReadWriteOnce: The volume can be mounted to exactly one notebook server
    which has read and write access.

-   ReadOnlyMany: The volume can be mounted to several notebooks (or pods
    in general). All notebooks can read data, none can write. you might
    want to prepopulate it with useful data.

-   ReadWriteMany: The volume can be mounted, read and written by multiple
    notebooks or pods. This is especially useful if many users work on the
    same data or if you run pipelines which perform parallel tasks on the 
    same data. You can also have a ReadWriteOnce workspace volume and mount
    a ReadWriteMany volume in addtion (see data volumes)

**Creating new volumes vs using existing volumes**

-   Type `New`: A new persistent volume will be created. Select this option
    If you have not created a workspace volume yet (e.g. via the volumes 
    dashboard). In this case, you can choose an arbitrary name.
    
-   Type `Existing`: The notebook tries to mount an existing volume with 
    the name you provided. Be careful to spell the volume right.Otherwhise 
    your notebook will not be provisioned correctly. 
    
    Also pay attention to the mode of the volume you specify. If you 
    specify a ReadWriteOnce volume which is already mounted to another 
    notebook or pod, your notebook will not be provisioned correctly.

If you check the checkbox labeled "Don't use Persistent Storage for User's
home", you will have a home directory to store data. However, this data
will be lost when you stop your notebook or when it is forcefully stopped.

## 6. Data Volumes

![workspace volume](/img/notebooks/data-volume.png)

Data volumes are persistent volumes you can mount in addition to your
workspace volume. You have the same configuration options as for the
workspace volume. For Data Volumes, ReadWriteMany volumes are a good
choice as you can mount them to multiple notebooks or use them in
pipelines.

## 7. Configurations<a name="configurations"></a>

![workspace volume](/img/notebooks/configurations.png)

The `Configurations` section provides addtional settings for your notebook.
Currently, you can select the "Allow access to Kubeflow Pipelines" options.
If you select this option, an access token will be mounted to your notebook
server. You will be able to authenticate against the Kubeflow Pipelines
API server and create, start and manage pipelines from within the notebook. 

## 8. Affinity and Tolerations

![workspace volume](/img/notebooks/tolerations.png)

This section allows you to influence on which type of node your notebook
is going to be launched. In general, you can choose to tolerate spot 
instances or not. Spot instances are cheaper than on on demand instances
but they can be terminated at any time. So if you have long running tasks,
you might prefer not to add toleration for the Spot Pool.

If you do not configure anything here, the only instance type your notebook
can be deployed to is an on-demand cpu instance. Consequently, you have to
add tolerations for any GPU Pool, if you have configured a GPU. Via the
affinity config, you choose between different types of GPUs. Make sure to
configure affinity and toleration consistently (e.g. both spot or both no
spot)

-   On demand instances: On demand instances cost more than spot instances.
    Use these instances if you run workloads which take a long time and
    should not be interrupted.

-   Spot instances: This instance type is a lot cheaper but comes with the
    risk of being terminated while your still working on it. This instance
    type is suitable for any kind of workload that are safe to interrupt.
    Data which is stored on Persistent Storage will not be lost. Spot
    instances are ideal for performing pipeline tasks.
