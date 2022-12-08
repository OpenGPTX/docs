# DGX Documentation

This page of documentation is the entrypoint of our DGX doc. Here you can find useful information and links to other related pages.

## Gettings access on DGX

AT (Alexander Thamm GmbH) is responsible to onboard OpenGPT-X users. Please provide us:
- Your name
- Your email
- Your public ssh-key (preferred via GitHub url)
```
# In case you dont have an ssh key pair already, you can simply create one with:
ssh-keygen

# By default it creates ~/.ssh/id_rsa (it is the private key you need to auth against the DGX) 
and ~/.ssh/id_rsa.pub (<== this public key you need to provide us)
```

You will get a start-password which needs to be changed automatically with the first login. Please use a secure password!

The whole USM (user management) is fully automated with Ansible in our [dgx-setup](https://github.com/KubeSoup/dgx-setup) repo. Due to security and privacy it is currently a private repo.

## Recommended order of documentation

Of course, you can pick the documentation you need, but we recommend the following order:
1. [Vscode remote-ssh development](https://github.com/KubeSoup/docs/blob/main/DGX/dgx-vscode-remote-ssh.md)
2. [Install Spark on DGX](https://github.com/KubeSoup/docs/blob/main/DGX/dgx-install-spark.md)
3. [Create a SparkSession on DGX](https://github.com/KubeSoup/docs/blob/main/DGX/dgx-create-sparksession.md)
4. [Spark-rapids: Spark with GPU on DGX](https://github.com/KubeSoup/docs/blob/main/DGX/dgx-spark-rapids-gpu.md)
5. [Spark History Server](https://github.com/KubeSoup/docs/blob/main/DGX/dgx-spark-history-server.md)


## DGX Hardware

All details are in the [datasheet](https://images.nvidia.com/aem-dam/Solutions/Data-Center/nvidia-dgx-a100-datasheet.pdf) and [User Guide](https://docs.nvidia.com/dgx/pdf/dgxa100-user-guide.pdf).
In short, it has:
- 128 total cores (256 threats)
- 2TB RAM
- 8x NVIDIA A100 80GB Tensor Core GPUs
- OS Storage: 2x 1.92TB M.2 NVME drives
- Internal Storage: 30TB (8x 3.84 TB) U.2
NVMe drives
- Ubuntu Linux OS


## Download s3 notebook (.ipynb)

In general we downloaded a lot data from the `opengptx` S3 bucket under folder `/raid/s3/opengptx/`.

For replicability you can find the according [.ipynb](https://github.com/KubeSoup/docs/blob/main/DGX/dgx-download-s3.ipynb) (only use 60 cores or less, otherwise the download fails sometimes) in this repo as well.

## Run jobs in the background

Some jobs need a long time to finish. Sometimes it makes sense to run it over the night or even the weekend. In order to avoid having your laptop up and running the whole time while the job is being executed, you can run it in the background with `nohup`:
```
mkdir $HOME/nohup
cd $HOME/nohup
nohup /bin/python3 $HOME/nohup/get_similar_rows.py > get_similar_rows.log &

# See progress:
tail -f get_similar_rows.log
```

