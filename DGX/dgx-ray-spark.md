# Ray

## Prerequisites

- Spark is installed
- python3
- python3-pip
- python3-venv
- openjdk-8-jdk

## Install dependencies

```
pip install ray==2.2.0 #2.3.0 introduced issues
pip install raydp
```

## Convert a Spark dataframe into a Ray dataframe (pandas)

Please look into the [.ipynb](https://github.com/KubeSoup/docs/blob/main/DGX/dgx-convert-sparkdf-to-raydf.ipynb)

## Problem

After a while the ssh connection breaks and it is not possible to reconnect anymore. The DGX node is stuck and IONOS need to restart to fix it as a workaround.
