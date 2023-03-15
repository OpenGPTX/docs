# Use Nvidia Triton on DGX for inference

## Why

Since we have 8 Nvidia GPUs on the DGX node and would like to use those to test the inference, it makes sense to use Nvidia Triton for doing so. It is open source, has a wide community and can run basically everywhere with Nvidia GPUs, let's use this on the DGX node as well.

## Requirements

- Be sure everything mentioned [here](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker) is installed (it was by default the case on the DGX node)
- To verify, simply run the following command:
```
docker run --rm --runtime=nvidia --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi
```

## Architecture

The architecture of Triton is quite easy. It can basically can run everywhere where a Nvidia GPU is in place (it can also run on pure CPU but this is out of scope here), no matter it is in the cloud, on the edge or a datacenter.
Nvidia recommends to start 1 Triton server per GPU (except a very large model needs multiple GPUs at the same time) and the best way is to use simply a docker container for Triton.
The major place is the so called model_repository. It is a folder with a special structure with models and the model config. Triton loads the models from that model_repostory und makes those up to get infered. If multiple models are in the model_repository and you only use 1 GPU for the Triton server, then multiple models are online in the same GPU. This improves the utilization and optimizes the costs.

## General steps for inference

The following steps need to be done to infer a model with Triton:
1. Creating a Model Repository
2. Launching Triton
3. Send an Inference Request


## Quickstart Inference

Logon DGX:
```
ssh dgx2
```

Be sure you are in your home directory:
```
cd ~
```

Clone the project:
```
git clone https://github.com/triton-inference-server/server.git
```

1. Creating a Model Repository

Let the shell script prepare everything for you. It downlods and prepares the models in the model_repository:
```
cd ~/server/docs/examples
./fetch_models.sh
```

2. Launching Triton

Start the Triton server infere the models:
```
docker run --gpus=1 --rm -p 8000:8000 -p 8001:8001 -p 8002:8002 -v /home/tim-krause/server/docs/examples/model_repository:/models nvcr.io/nvidia/tritonserver:23.01-py3 tritonserver --model-repository=/models
```

To verifiy that the Triton server is up and running, be sure it gives a `200` back:
```
curl -v localhost:8000/v2/health/ready

...
< HTTP/1.1 200 OK
< Content-Length: 0
< Content-Type: text/plain
```

3. Send an Inference Request

Infere/consume a model:
```
docker run -it --rm --net=host nvcr.io/nvidia/tritonserver:23.01-py3-sdk
/workspace/install/bin/image_client -m densenet_onnx -c 3 -s INCEPTION /workspace/images/mug.jpg

Request 0, batch size 1
Image '/workspace/images/mug.jpg':
    15.346230 (504) = COFFEE MUG
    13.224326 (968) = CUP
    10.422965 (505) = COFFEEPOT
```



### Get an overview about the deployed models

For more detailed info, look [here](https://github.com/triton-inference-server/server/blob/main/docs/protocol/extension_model_repository.md).

In order to see which models are currenly online, a special API endpoint can be consumed:
```
curl -X POST -v localhost:8000/v2/repository/index

[
  {
    "name": "densenet_onnx",
    "version": "1",
    "state": "READY"
  },
  {
    "name": "inception_graphdef",
    "version": "1",
    "state": "READY"
  },
  {
    "name": "simple",
    "version": "1",
    "state": "READY"
  },
  {
    "name": "simple_dyna_sequence",
    "version": "1",
    "state": "READY"
  },
  {
    "name": "simple_identity",
    "version": "1",
    "state": "READY"
  },
  {
    "name": "simple_int8",
    "version": "1",
    "state": "READY"
  },
  {
    "name": "simple_sequence",
    "version": "1",
    "state": "READY"
  },
  {
    "name": "simple_string",
    "version": "1",
    "state": "READY"
  }
]
```

## Outlook

So all in all the major part is:
1. to convert the model in a format, Triton can read
2. to create the correct [model format](https://github.com/triton-inference-server/server/blob/main/docs/user_guide/model_configuration.md), Triton needs
