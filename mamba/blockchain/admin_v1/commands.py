import click
import yaml
import re
from kubernetes import client
from os import path
from utils import hiss, util
from settings import settings

def setup_admin():

    domains = settings.ORDERER_DOMAINS.split(' ')
    if len(domains) == 0:
        domains = settings.PEER_DOMAINS.split(' ')

    # Create application artifact folder
    hiss.echo('Create application artifact folder')
    ## Find efs pod
    pods = settings.k8s.find_pod(namespace="default", keyword="test-efs")
    if not pods:
        return hiss.hiss('cannot find tiller pod')

    mkdir_cmd = ('mkdir -p '+settings.EFS_ROOT+'/admin/artifacts;'
    'mkdir -p '+settings.EFS_ROOT+'/admin/crypto-path;'
    'mkdir -p '+settings.EFS_ROOT+'/admin/crypto-store;')

    ## Exec command
    exec_command = [
        '/bin/bash',
        '-c',
        '%s'  % (mkdir_cmd)]

    result_get_folder = settings.k8s.exec_pod(
        podName=pods[0], namespace="default", command=exec_command)
    hiss.sub_echo(result_get_folder.data)

    # Create temp folder & namespace
    settings.k8s.prereqs(domains[0])
    dict_env = {
        'ORDERER_DOMAIN': domains[0],
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }

    # Apply deployment
    k8s_template_file = '%s/admin-v1/admin-deployment.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domains[0], k8s_template_file=k8s_template_file, dict_env=dict_env)

    # Apply service
    k8s_template_file = '%s/admin-v1/admin-service.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domains[0], k8s_template_file=k8s_template_file, dict_env=dict_env)

def del_admin():

    domains = settings.ORDERER_DOMAINS.split(' ')
    jobname = 'admin-v1'

    # Delete job pod
    return settings.k8s.delete_stateful(name=jobname, namespace=domains[0])
    

@click.group()
def adminv1():
    '''Admin-V1 Service'''
    pass

@adminv1.command('setup', short_help='Create new a new Admin service')
def setup():
    hiss.rattle('Create new a new Admin-V1 service')

    setup_admin()

@adminv1.command('delete', short_help='Delete the Admin service')
def delete():
    hiss.rattle('Delete the Admin-V1 service')

    del_admin()