import click
import os
import settings
from utils import hiss


def env():
    hiss.rattle('Create environment for network')
    os.system('./k8s/environment/setup.sh')
    return True


@click.command('environment', short_help="Create environment for network")
def environment():
    env()
