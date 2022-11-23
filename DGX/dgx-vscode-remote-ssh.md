# Vscode remote-ssh development

This doc outlines the steps necessary to setup Spark with Delta Lake on Kubeflow. It allows running Spark jobs inside the notebooks.

## Why

On the one hand, it is very convinient to use vscode locally. It is fast, responsive and is perfectly integrated with copy&paste. On the other hand, the power of the DGX node with 126 CPU cores and 8 GPUs (each 80GB VRAM) and up to 30 TB NVME storage is impressive. Why not combinding both worlds with the vscode plugin `remote-ssh`. With this setup, the vscode runs locally on your Laptop while the files/repo are located on DGX and everything is even executed on the DGX remotely.

You can use it for running python, model training, Spark and more on powerful hardware.

## Prerequisites

- This manual is based on Linux but can be adapted also for another OS
- We assume you already installed Visual Studio Code (vscode)

## Set up everyting

Create an ssh config to make it more convinient:
```
vi ~/.ssh/config
Host dgx2
  HostName 85.215.1.202
  user your-username
```

Test the ssh config by connecting with ssh:
```
ssh dgx2
exit
```

Install the plugin [remote-ssh](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) in vscode.

## Use remote-ssh in vscode

- On the left side, click on `Remote Explorer`
- Select the file `~/.ssh/config`
- Then select `dgx2` (`Connect in Current Window...`)
- Select the according folder where you want to work from

**Now it is like vscode is in the remote folder on the DGX node but your vscode windows is still on your laptop. So the files are remote and also all executions are done remotely.**