import click
import os
from os.path import expanduser
import shutil
from utils import util, hiss

DEFAULT_CONFIG_PATH = expanduser('~/.akachain/akc-mamba/mamba/config/.env')
DEFAULT_SCRIPT_PATH = expanduser('~/.akachain/akc-mamba/mamba/scripts')
DEFAULT_TEMPLATE_PATH = expanduser('~/.akachain/akc-mamba/mamba/template')
DEFAULT_OTHER_PATH = expanduser('~/.akachain/akc-mamba/mamba/k8s/')

def get_tamplte_env():
    return util.get_package_resource('config', '.env')

def extract(force_all, force_config, force_script, force_template, force_other):
    # Extract config
    mamba_config = os.path.dirname(DEFAULT_CONFIG_PATH)

    if not os.path.isdir(mamba_config) or force_all or force_config:
        hiss.echo('Extract config to default config path: %s ' % DEFAULT_CONFIG_PATH)
        dotenv_path = util.get_package_resource('config', '.env')
        if not os.path.isdir(mamba_config):
            os.makedirs(mamba_config)
        shutil.copy(dotenv_path, DEFAULT_CONFIG_PATH)

    # Extract scripts
    if not os.path.isdir(DEFAULT_SCRIPT_PATH) or force_all or force_script:
        hiss.echo('Extract scripts to default scripts path: %s ' % DEFAULT_SCRIPT_PATH)
        script_path = util.get_package_resource('', 'scripts')
        if os.path.isdir(DEFAULT_SCRIPT_PATH):
            shutil.rmtree(DEFAULT_SCRIPT_PATH)
        shutil.copytree(script_path, DEFAULT_SCRIPT_PATH)

    # Extract template
    if not os.path.isdir(DEFAULT_TEMPLATE_PATH) or force_all or force_template:
        hiss.echo('Extract template to default template path: %s ' % DEFAULT_TEMPLATE_PATH)
        template_path = util.get_package_resource('', 'template')
        if os.path.isdir(DEFAULT_TEMPLATE_PATH):
            shutil.rmtree(DEFAULT_TEMPLATE_PATH)
        shutil.copytree(template_path, DEFAULT_TEMPLATE_PATH)

    # Extract other
    if not os.path.isdir(DEFAULT_OTHER_PATH) or force_all or force_other:
        hiss.echo('Extract other to default other path: %s ' % DEFAULT_OTHER_PATH)
        other_path = util.get_package_resource('k8s', '')
        if os.path.isdir(DEFAULT_OTHER_PATH):
            shutil.rmtree(DEFAULT_OTHER_PATH)
        shutil.copytree(other_path, DEFAULT_OTHER_PATH)


@click.command('extract-config', short_help="Extract binary config")
@click.option('-f', '--force', is_flag=True, help="Force extract all")
@click.option('-c', '--config', is_flag=True, help="Force extract config")
@click.option('-s', '--script', is_flag=True, help="Force extract script")
@click.option('-t', '--template', is_flag=True, help="Force extract template")
@click.option('-o', '--other', is_flag=True, help="Force extract other")
def extract_config(force, config, script, template, other):
    extract(force, config, script, template, other)