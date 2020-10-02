# AKC-MAMBA manuals

## I. Installation Instructions

### 1. Install from pip package

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

#### b. Install AKC-Mamba from pip package

  You can use the following command:

  ```python
  pip3 install akc-mamba
  ```

  After install successfuly, you can get help by command:
  
  ```bash
  mamba --help
  ```

#### c. Deploy and bootstrap network with CLI

- Init mamba evironment:

```bash
mamba environment
```

- Deploy your network:

```python
mamba start
```

### 2. Install and run from source code

#### a. Edit configuration files

  First, copy the content of `config/operator.env-template` to be `config/.env`. This file will contain all modifiable configuration of Mamba.

  ```bash
  cp ./config/operator.env-template ./config/.env
  ```

  Update configuration parameters in `config/.env`, the file content is pretty much self-explained.

#### b. Install required packages

  Install required Python3 modules with

  ```bash
  pip3 install -r requirements.txt
  ```

  We now can use the Mamba tool to prepare required helm and k8s components

  ```bash
  find . -type f -iname "*.sh" -exec chmod +x {} \;
  python3 mamba.py environment
  ```

#### c. Deploy and bootstrap network

  ```python
  python3 mamba.py start
  ```

  The `mamba start` command executes a series of sub commands that installs various network components. For more information on each command for individual components, please refer to help section

  ```python
  python3 mamba.py help
  ```

  To terminate the network, just run

  ```python
  python3 mamba.py terminate
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