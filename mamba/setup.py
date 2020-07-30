import setuptools
import sys

with open("README.md", "r") as fh:
  long_description = fh.read()

setuptools.setup(
  name='akc-mamba',
  version='0.0.8',
  entry_points={'console_scripts': ['mamba = cli.mamba:main'] },
  author="akaChain",
  author_email="admin@akachain.io",
  description="A production ready, complete experience in deploying a Hyperledger Fabric",
  long_description=long_description,
  long_description_content_type="text/markdown",
  url="https://github.com/Akachain/akc-mamba",
  include_package_data=True,
  # package_dir={'': 'mamba'},
  packages=setuptools.find_packages(),
  classifiers=[
    "Programming Language :: Python :: 3",
    "License :: OSI Approved :: MIT License",
    "Operating System :: OS Independent",
  ],
)
