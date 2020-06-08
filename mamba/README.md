# AKC-MAMBA manuals

## 1. Installation Instructions

### a. Edit configuration files
First, copy the content of `config/operator.env-template` to be `config/.env`. This file will contain all modifiable configuration of Mamba.

```
cp ./config/operator.env-template ./config/.env
```

Update configuration parameters in `config/.env`, the file content is pretty much self-explained.

### b. Install required packages
Install required Python3 modules with

```
pip3 install -r requirements.txt
```

We now can use the Mamba tool to prepare required helm and k8s components

```
find . -type f -iname "*.sh" -exec chmod +x {} \;
python3 mamba.py environment
```

### c. Deploy and bootstrap network

```
python3 mamba.py start
```

The `mamba start` command executes a series of sub commands that installs various network components. For more information on each command for individual components, please refer to help section

```
python3 mamba.py help
```

To terminate the network, just run

```
python3 mamba.py terminate
```

## 2. Development Guide

### 2.1 Project structure
Mamba makes use of [Click_](http://click.palletsprojects.com/en/7.x/), an elegant python package for creating command line interfaces. The project structure is depicted in the tree below.

```
.
├── command_group_1
│   ├── commands.py
│   ├── __init__.py
│
├── utils
│   ├── __init__.py
│   ├── kube.py
│
├── mamba.py
├── settings.py

```

There are 4 main components: 
- mamba.py : The bootstrap instance module of Mamba 
- settings.py : Contains global variables that are shared accross all sub modules
- command_group : Each command group is separated into its own directory.
- utils : helper functions that must be initialized via settings.py

### 2.2 Coding Convention
Please follow [PEP8](https://www.python.org/dev/peps/pep-0008/) - Style guide for Python Code. 

Another example can be found [here](https://gist.github.com/RichardBronosky/454964087739a449da04)

There are several notes that are different with other languages

```
Function names should be lowercase, with words separated by underscores as necessary to improve readability.

Camel case is for class name
```

### 2.3 Logging instruction

A snake must know how hiss ... or sometimes rattle.

Normally we can just use echo to print out message during execution
However:
- It is mandatory to `hiss` when there is error
- also, `rattle` is needed when a snake meet something ... at the beginning or at the end of an execution.

For more information about logging, please follow the standard convention in `mamba/utils/hiss.py`