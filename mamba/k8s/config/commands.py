import subprocess
import re
from os.path import expanduser
import os
import shutil
import click
from dotenv import load_dotenv
from utils import util, hiss
from utils.kube import KubeHelper

DEFAULT_CONFIG_PATH = expanduser('~/.akachain/akc-mamba/mamba/config/.env')
DEFAULT_SCRIPT_PATH = expanduser('~/.akachain/akc-mamba/mamba/scripts')
DEFAULT_TEMPLATE_PATH = expanduser('~/.akachain/akc-mamba/mamba/template')
DEFAULT_OTHER_PATH = expanduser('~/.akachain/akc-mamba/mamba/k8s/')


def get_template_env():
    return util.get_package_resource('config', 'operator.env-template')

def detect_deployed_efs_server(k8s_type):
    hiss.echo('Looking for deployed efs server...')
    efs_server = ''
    if k8s_type == 'eks':
        # Find efs-efs-provisioner pod
        pods = KubeHelper().find_pod(namespace="default", keyword="efs-efs-provisioner")
        if not pods:
            return efs_server
        efs_server_cmd = 'kubectl describe deployments -n default efs-efs-provisioner | grep Server'
        detected_efs_server = subprocess.check_output(
            efs_server_cmd, shell=True)
        if detected_efs_server:
            efs_server = detected_efs_server.decode().split(':')[1].strip()
    elif k8s_type == 'minikube':
        efs_server_cmd = 'kubectl get svc -n default | grep nfs-server | awk \'{print $3}\''
        detected_efs_server = subprocess.check_output(
            efs_server_cmd, shell=True)
        if detected_efs_server:
            efs_server = detected_efs_server.decode().strip()
    return efs_server

def detect_deployed_efs_path():
    hiss.echo('Looking for deployed efs path...')
    efs_path = ''
    efs_path_cmd = 'kubectl get pvc | grep efs | awk \'{print $3}\''
    detected_efs_path = subprocess.check_output(efs_path_cmd, shell=True)
    if detected_efs_path:
        efs_path = detected_efs_path.decode().strip()
    return efs_path

def detect_deployed_efs_pod():
    hiss.echo('Looking for deployed efs pod...')
    efs_pod = ''
    efs_pod_cmd = 'kubectl get pod -n default | grep test-efs | awk \'{print $1}\''
    detected_efs_pod = subprocess.check_output(efs_pod_cmd, shell=True)
    if detected_efs_pod:
        efs_pod = detected_efs_pod.decode().strip()
    return efs_pod

def extract_cfg(mamba_config, dev_mode):
    hiss.echo('Extract config to default config path: %s ' %
              DEFAULT_CONFIG_PATH)
    dotenv_path = get_template_env()
    if not os.path.isdir(mamba_config):
        os.makedirs(mamba_config)
    shutil.copy(dotenv_path, DEFAULT_CONFIG_PATH)
    load_dotenv(DEFAULT_CONFIG_PATH)

    default_cluster_name = os.getenv('EKS_CLUSTER_NAME')
    default_k8s_type = os.getenv('K8S_TYPE')
    deployment_mode = os.getenv('DEPLOYMENT_ENV')

    # Input
    cluster_name = input(
        f'Cluster name ({default_cluster_name}): ') or default_cluster_name
    k8s_type = input(
        f'Kubenetes type - support eks or minikube ({default_k8s_type}): ') or default_k8s_type
    if dev_mode:
        deployment_mode = 'develop'

    # Detect current environment setting
    # EFS_SERVER
    efs_server = detect_deployed_efs_server(k8s_type)
    # EFS_SERVER_ID
    efs_server_id = efs_server.split('.')[0]
    print('efs_server: ', efs_server)
    # EFS_PATH
    efs_path = detect_deployed_efs_path()
    # EFS_POD
    efs_pod = detect_deployed_efs_pod()

    if not efs_pod and k8s_type == 'eks':
        retry = 3
        while retry > 0:
            efs_server = input('EFS server (*):')
            if efs_server:
                break
            retry -= 1
        if not efs_server:
            hiss.hiss('Must specify EFS_SERVER!')
            exit()

    with open(DEFAULT_CONFIG_PATH, "r") as sources:
        lines = sources.readlines()
    with open(DEFAULT_CONFIG_PATH, "w") as sources:
        for line in lines:
            newline = re.sub(r'EKS_CLUSTER_NAME=.*',
                             f'EKS_CLUSTER_NAME=\"{cluster_name}\"', line)
            newline = re.sub(
                r'K8S_TYPE=.*', f'K8S_TYPE=\"{k8s_type}\"', newline)

            if efs_server:
                newline = re.sub(r'EFS_SERVER=.*',
                                 f'EFS_SERVER=\"{efs_server}\"', newline)
            if efs_server_id:
                newline = re.sub(r'EFS_SERVER_ID=.*',
                                 f'EFS_SERVER_ID=\"{efs_server_id}\"', newline)
            if efs_path:
                newline = re.sub(
                    r'EFS_PATH=.*', f'EFS_PATH=\"efs-{efs_path}\"', newline)
            if efs_pod:
                newline = re.sub(
                    r'EFS_POD=.*', f'EFS_POD=\"{efs_pod}\"', newline)
            newline = re.sub(
                    r'DEPLOYMENT_ENV=.*', f'DEPLOYMENT_ENV=\"{deployment_mode}\"', newline)
            sources.write(newline)

    hiss.rattle("See more config in %s" % DEFAULT_CONFIG_PATH)


def extract(force_all, force_config, force_script, force_template, force_other, dev_mode):
    # Extract config
    mamba_config = os.path.dirname(DEFAULT_CONFIG_PATH)

    if not os.path.isdir(mamba_config) or force_all or force_config:
        extract_cfg(mamba_config, dev_mode)

    # Extract scripts
    if not os.path.isdir(DEFAULT_SCRIPT_PATH) or force_all or force_script:
        hiss.echo('Extract scripts to default scripts path: %s ' %
                  DEFAULT_SCRIPT_PATH)
        script_path = util.get_package_resource('', 'scripts')
        if os.path.isdir(DEFAULT_SCRIPT_PATH):
            shutil.rmtree(DEFAULT_SCRIPT_PATH)
        shutil.copytree(script_path, DEFAULT_SCRIPT_PATH)

    # Extract template
    if not os.path.isdir(DEFAULT_TEMPLATE_PATH) or force_all or force_template:
        hiss.echo('Extract template to default template path: %s ' %
                  DEFAULT_TEMPLATE_PATH)
        template_path = util.get_package_resource('', 'template')
        if os.path.isdir(DEFAULT_TEMPLATE_PATH):
            shutil.rmtree(DEFAULT_TEMPLATE_PATH)
        shutil.copytree(template_path, DEFAULT_TEMPLATE_PATH)

    # Extract other
    if not os.path.isdir(DEFAULT_OTHER_PATH) or force_all or force_other:
        hiss.echo('Extract other to default other path: %s ' %
                  DEFAULT_OTHER_PATH)
        other_path = util.get_package_resource('k8s', '')
        if os.path.isdir(DEFAULT_OTHER_PATH):
            shutil.rmtree(DEFAULT_OTHER_PATH)
        shutil.copytree(other_path, DEFAULT_OTHER_PATH)


@click.command('init', short_help="Extract binary config")
@click.option('-f', '--force', is_flag=True, help="Force extract all")
@click.option('-c', '--config', is_flag=True, help="Force extract config")
@click.option('-s', '--script', is_flag=True, help="Force extract script")
@click.option('-t', '--template', is_flag=True, help="Force extract template")
@click.option('-o', '--other', is_flag=True, help="Force extract other")
@click.option('--dev', is_flag=True, help="Develop mode")
def extract_config(force, config, script, template, other, dev):
    extract(force, config, script, template, other, dev)
