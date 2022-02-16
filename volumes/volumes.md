# Volumes

![volumes tab](/img/volumes/volumes-tab.png)

You can create a new volume by clicking the top right "+ NEW VOLUME" button. 
The Volumes tab provides an overview over the existing volumes. You can see the

-   name,
-   status,
-   age,
-   access mode and
-   storage class 

of your volumes. You can also start a file browser to view the contents of a
volume. Also, you can delete Volumes. 

## Create a new Volume

![volumes tab](/img/volumes/volumes-tab.png)

The "New Volume" dialog lets you configure name and size of the new volume. Pay
attention when selecting storage class and access mode!

### Storage class

You can choose between EBS Volumes and EFS Volumes. The options `None` and `gp2` will eventually result in a new EBS volume as EBS is the default for EKS clusters.

-   EBS Volume: Block Store with a fixed size. New volumes will be provisioned
    when they are attached to a notebook (or any pod) for the first time.
    **Attention:** although you can select "ReadManyOnly" and "ReadWriteMany"
    access modes, EBS only supports "ReadWriteOnce". if you select anything
    else and use the volume with e.g. with a notebook, your notebook will not
    be able to launch.

-   EFS Volume: Dynamically sized volume supporting "ReadWriteMany" access 
    mode. This is the recommended volume type.

### Access mode

-   ReadWriteOnce: The volume can be mounted to exactly one notebook server
    which has read and write access. **Attention:** if you try to attach 
    "ReadWriteOnce" volume to a new notebook, make sure it is not attached to
    any other pod like another notebook or also the file browser! otherwhise
    your notebook will not start.

-   ReadOnlyMany: The volume can be mounted to several notebooks (or pods
    in general). All notebooks can read data, none can write. you might
    want to prepopulate it with useful data.

-   ReadWriteMany: The volume can be mounted, read and written by multiple
    notebooks or pods. This is especially useful if many users work on the
    same data or if you run pipelines which perform parallel tasks on the 
    same data. You can also have a ReadWriteOnce workspace volume and mount
    a ReadWriteMany volume in addtion (see data volumes)