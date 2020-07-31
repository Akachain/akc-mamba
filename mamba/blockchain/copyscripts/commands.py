import click
import os
from settings import settings
from os import path
from os.path import expanduser
from shutil import copyfile
from utils import hiss


def copy_scripts():
    hiss.rattle('Copy scripts to EFS')

    # Find efs pod
    pods = settings.k8s.find_pod(namespace="default", keyword="test-efs")
    if not pods:
        return hiss.hiss('cannot find tiller pod')

    # Check empty folder
    exec_command = [
        '/bin/bash',
        '-c',
        'test -d %s && echo "1" || echo "0"'  % (settings.EFS_ROOT)]

    result_get_folder = settings.k8s.exec_pod(
        podName=pods[0], namespace="default", command=exec_command)
    if int(result_get_folder.data) < 1:
        hiss.sub_echo('Folder %s not found. Creating...' % settings.EFS_ROOT)
        exec_command = [
            '/bin/bash',
            '-c',
            'mkdir -p %s/admin; mkdir -p %s/akc-ca-data' % (settings.EFS_ROOT, settings.EFS_ROOT)]

        # Create folder in efs
        result_create_folder = settings.k8s.exec_pod(
            podName=pods[0], namespace="default", command=exec_command)
        if result_create_folder.success == False:
            return hiss.hiss('cannot create folders in %s: %s' % (pods[0], result_create_folder.msg))

    # Copy config to scripts/env
    hiss.sub_echo('Copy config to scripts/env')
    config_file = expanduser('~/.akachain/akc-mamba/mamba/config/.env')
    env_script_File = expanduser('~/.akachain/akc-mamba/mamba/blockchain/scripts/env-scripts.sh')
    copyfile(config_file, env_script_File)

    # Remove old script folder in efs
    hiss.sub_echo('Remove old script folder in efs')
    exec_command = [
        '/bin/bash',
        '-c',
        'rm -rf %s/akc-ca-scripts/*' % (settings.EFS_ROOT)]

    result_create_folder = settings.k8s.exec_pod(
        podName=pods[0], namespace="default", command=exec_command)
    if result_create_folder.success == False:
        return hiss.hiss('cannot remove folders in %s' % pods[0])

    # Copy scripts folder to efs
    hiss.sub_echo('Copy scripts folder to efs')
    script_path = expanduser('~/.akachain/akc-mamba/mamba/blockchain/scripts')
    if not settings.k8s.cp_to_pod(podName=pods[0], namespace='default', source=script_path, target='%s/akc-ca-scripts' % settings.EFS_ROOT):
        return hiss.hiss('connot copy scripts folder to pod %s' % pods[0])

    exec_command = [
        '/bin/bash',
        '-c',
        ('test -d '+settings.EFS_ROOT+'/akc-ca-scripts/akc-ca-scripts'
        ' && mv '+settings.EFS_ROOT+'/akc-ca-scripts/akc-ca-scripts/* '+settings.EFS_ROOT+'/akc-ca-scripts || echo "ok"')]

    result_create_folder = settings.k8s.exec_pod(
        podName=pods[0], namespace="default", command=exec_command)
    if result_create_folder.success == False:
        return hiss.hiss('cannot remove folders in %s' % pods[0])

    # Copy test chaincode to efs
    hiss.sub_echo('Copy test chaincode to efs')
    artifacts_path = expanduser('~/.akachain/akc-mamba/mamba/blockchain/artifacts')
    if not settings.k8s.cp_to_pod(podName=pods[0], namespace='default', source=artifacts_path, target='%s/admin/artifacts' % settings.EFS_ROOT):
        return hiss.hiss('connot copy test chaincode to pod %s' % pods[0])

    return True


@click.command('copyscripts', short_help="Copy \'scripts\' & \'chaincode test' folder to EFS")
def copyscripts():
    copy_scripts()
