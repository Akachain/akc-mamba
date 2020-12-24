import setuptools

with open("README.md", "r") as fh:
    LONG_DESCRIPTION = fh.read()

with open('requirements.txt', 'r') as f:
    REQUIREMENTS = f.read().splitlines()
    print(REQUIREMENTS)

setuptools.setup(
    name='akc-mamba',
    version='2.1.0.a7',
    entry_points={'console_scripts': ['mamba = cli.mamba:mamba']},
    author="akaChain",
    author_email="admin@akachain.io",
    description="A production ready, complete experience in deploying a Hyperledger Fabric",
    long_description=LONG_DESCRIPTION,
    long_description_content_type="text/markdown",
    url="https://github.com/Akachain/akc-mamba",
    package_data={'': ['*']},
    include_package_data=True,
    install_requires=REQUIREMENTS,
    # package_dir={'': 'mamba'},
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    keywords='mamba akc-mamba hyperledger fabric blockchain network',
)
