import click
import os
from os.path import expanduser
from settings import settings
from utils import hiss


def env():
    hiss.rattle('Create environment for network')
    excute = expanduser('~/.akachain/akc-mamba/mamba/k8s/environment/setup.sh')
    os.system(excute)
    return True


@click.command('environment', short_help="Create environment for network")
def environment():
    env()
