# Best Practices on DGX

## Python

We have multiple Python versions installed on the DGX system which are Python 3.8 and Python 3.10.
Python 3.8 being installed by default with Ubuntu 20.04 LTS and Python 3.10 from [deadsnakes ppa](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa).

You can use which ever Python version you like but **please make sure to virtual environments for every project.**

### Python 3.8 virtual environment
To create a virtual environment with Python 3.8

```console
$ python3 -m venv venv
$ source venv/bin/activate
(venv) $ python --version
Python 3.8.10
```
### Python 3.10 virtual environment
To create a virtual environment with Python 3.10

```console
$ python3.10 -m venv venv
$ source venv/bin/activate
(venv) $ python --version
Python 3.10.10
```

Note: Outside of virtual environments, to run things with Python 3.10, you run with `python3.10`, `python3` still points to Python 3.8 as it comes by default with Ubuntu 20.04 LTS.
