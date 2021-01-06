## A simple project
To create this project locally, create the following file structure:
```
packaging_tutorial
└── example_pkg
    └── __init__.py
```
```example_pkg/__init__.py``` is required to import the directory as a package, and can simply be an empty file

## Creating the package files
```
packaging_tutorial
├── LICENSE
├── README.md
├── example_pkg
│   └── __init__.py
├── setup.py
└── tests
```

## Creating a test folder
```tests/``` is a placeholder for unit test files. Leave it empty for now.

## Creating setup.py
```setup.py``` is the build script for setuptools. It tells ```setuptools``` about your package (such as the name and version) as well as which code files to include.

Open ```setup.py``` and enter the following content. Update the package name to include your username (for example, ```example-pkg-theacodes```), this ensures that you have a unique package name and that your package doesn’t conflict with packages uploaded by other people following this tutorial.

- ``name`` is the distribution name of your package. This can be any name as long as only contains letters, numbers, _ , and -. It also must not already be taken on pypi.org. Be sure to update this with your username, as this ensures you won’t try to upload a package with the same name as one which already exists when you upload the package.

## Install package in develop mode
```
sudo python3 setup.py develop
```

## Generating distribution archives
Make sure you have the latest versions of setuptools and wheel installed:
```
python3 -m pip install --user --upgrade setuptools wheel
```
Now run this command from the same directory where setup.py is located:
```
python3 setup.py sdist bdist_wheel
```
The tar.gz file is a Source Archive whereas the .whl file is a Built Distribution.

## Uploading the distribution archives
### 1. Register an account on Test PyPI 

Test PyPI is a separate instance of the package index intended for testing and experimentation

Go to https://test.pypi.org/account/register/ and complete the steps on that page.

Now you’ll create a PyPI API token so you will be able to securely upload your project

Go to https://test.pypi.org/manage/account/#api-tokens and create a new API token; don’t limit its scope to a particular project, since you are creating a new project.

### 2. Use twine to upload the distribution packages
You’ll need to install Twine:
```
python3 -m pip install --user --upgrade twine
```
Once installed, run Twine to upload all of the archives under dist:
```
python3 -m twine upload --repository testpypi dist/*
```
You will be prompted for a username and password. For the username, use __token__. For the password, use the token value, including the pypi- prefix.

After the command completes, you should see output similar to this:
```
Uploading distributions to https://test.pypi.org/legacy/
Enter your username: [your username]
Enter your password:
Uploading example_pkg_YOUR_USERNAME_HERE-0.0.1-py3-none-any.whl
100%|█████████████████████| 4.65k/4.65k [00:01<00:00, 2.88kB/s]
Uploading example_pkg_YOUR_USERNAME_HERE-0.0.1.tar.gz
100%|█████████████████████| 4.25k/4.25k [00:01<00:00, 3.05kB/s]
```

Once uploaded your package should be viewable on TestPyPI, for example, https://test.pypi.org/project/example-pkg-YOUR-USERNAME-HERE

## Installing your newly uploaded package
You can use ``pip`` to install your package and verify that it works. Create a new virtualenv (see [Installing Packages](https://packaging.python.org/tutorials/installing-packages/) for detailed instructions) and install your package from TestPyPI:
```
python3 -m pip install --index-url https://test.pypi.org/simple/ --no-deps example-pkg-YOUR-USERNAME-HERE
```

## References
https://packaging.python.org/tutorials/
https://setuptools.readthedocs.io/en/latest/pkg_resources.html#resourcemanager-api
