# AKC-MAMBA manuals

## I. Installation Instructions

### 1. Prerequisites
Before you begin, you should confirm that you have installed all the prerequisites below on the platform where you will be running AKC-Mamba.
#### a. Install pip3
If you have not installed `pip3`, use the following command to install:

```bash
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python3 get-pip.py --user
```
For checking version :
```bash
pip3 --version
```

### 2. Install AKC-Mamba
#### a. Install AKC-Mamba from pip package

You can use the following command:
```python
pip3 install akc-mamba
```
After install successfuly, you can get help by command:

```bash
mamba --help
```

#### b. Install and run from source code

Install required Python3 modules with

```bash
pip3 install -r requirements.txt
```

Use akc-mamba using python3 command:
```bash
python3 mamba.py --help
```

### 3. Deploy and bootstrap network with CLI
#### a. Prepare environment
We now can use the Mamba tool to prepare required helm and k8s components

```bash
mamba environment
```

After running this command, the program will ask you to fill in some of the most necessary information of creating a blockchain network:
- `Cluster name`: The name of the cluster network you created in step [Setup an AWS EKS cluster](../README.md). Default: `cluster-mamba-example`
- `Kubenetes type`: Currently `akc-mamba` is supporting kubenetes of two types: `eks` and `minikube`. The default is `eks`
- `EFS infomation`: After you have entered the `Kubenetes type`,` mamba` will automatically search your k8s network for information about `efs`. If you have `EFS` installed before, the system will automatically update the config file located at `~/.akachain/akc-mamba/mamba/config/.env`. If not, you need to fill in the information `EFS SERVER` based on the installation step [Setup a Network File System](../README.md). If the k8s type is `minikube` then you do not need to enter this information.
- Important Note: You can check and update configuration parameters in `~/.akachain/akc-mamba/mamba/config/.env`, the file content is pretty much self-explained.
#### b. Deploy and bootstrap network

  ```python
  mamba start
  ```

  The `mamba start` command executes a series of sub commands that installs various network components. For more information on each command for individual components, please refer to help section

  ```python
  mamba --help
  ```

  To terminate the network, just run

  ```python
  mamba terminate
  ```

## II. Development Guide

### 1. Project structure

Mamba makes use of [Click_](http://click.palletsprojects.com/en/7.x/), an elegant python package for creating command line interfaces. The project structure is depicted in the tree below.

```bash
.
├── command_group_1
│   ├── commands.py
│   ├── __init__.py
│
├── utils
│   ├── __init__.py
│   ├── kube.py
├── settings
│   ├── settings.py
├── mamba.py

```

There are 4 main components:

- mamba.py : The bootstrap instance module of Mamba 
- settings : Contains global variables that are shared accross all sub modules
- command_group : Each command group is separated into its own directory.
- utils : helper functions that must be initialized via settings.py

### 2. Coding Convention

Please follow [PEP8](https://www.python.org/dev/peps/pep-0008/) - Style guide for Python Code. 

Another example can be found [here](https://gist.github.com/RichardBronosky/454964087739a449da04)

There are several notes that are different with other languages

```text
Function names should be lowercase, with words separated by underscores as necessary to improve readability.

Camel case is for class name
```

### 3. Logging instruction

A snake must know how hiss ... or sometimes rattle.

Normally we can just use echo to print out message during execution
However:

- It is mandatory to `hiss` when there is error.
- also, `rattle` is needed when a snake meet something ... at the beginning or at the end of an execution.

For more information about logging, please follow the standard convention in `mamba/utils/hiss.py`