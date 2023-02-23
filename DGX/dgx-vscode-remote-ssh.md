# Vscode remote-ssh development

This doc shows the setup and configuration of the vscode remote-ssh plugin.

## Why

On the one hand, it is very convinient to use vscode locally. It is fast, responsive and is perfectly integrated with copy&paste. On the other hand, the power of the DGX node with 128 CPU cores and 8 GPUs (each 80GB VRAM) and up to 30 TB NVME storage is impressive. Why not combine both worlds with the vscode plugin `remote-ssh`. With this setup, the vscode runs locally on your Laptop while the files/repo are located on DGX and everything is even executed on the DGX remotely.

You can use it for running python, model training, Spark and more on powerful hardware.

## Prerequisites

- This manual is based on Linux but can be adapted also for another OS
- We assume you already installed Visual Studio Code (vscode)
- You have access on the DGX node via public/private ssh keys

## Set up everyting

Your username will be provided by the DGX admins.

- Create an ssh config to make it more convinient:
```
vi ~/.ssh/config
Host dgx2
  HostName 85.215.1.202
  user your-username
```
- Test the ssh config by connecting with ssh:
```
ssh dgx2
exit
```
- Install the plugin [remote-ssh](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) in vscode.

## Use remote-ssh in vscode

- On the left side, click on `Remote Explorer`
- In the dropdown at the top of the navigation bar, select `SSH Targets`
- in the `SSH TARGETS` section, click on the `+` icon
- enter the ssh command for connecting to the dgx: `ssh dgx2`
- Select the file `~/.ssh/config`
- Then select `dgx2` (`Connect in Current Window...`)
- A new window opens and prompts you to enter the platform of the remote host. Select `Linux`
- Next you are shown the fingerprint of the DGX-Host. Click `continue`
- On connecting the first time it will take some time to install the VSCode server on the DGX
- Select the according folder where you want to work from

**Now it is like vscode is in the remote folder on the DGX node but your vscode windows is still on your laptop. So the files are remote and also all executions are done remotely.**
