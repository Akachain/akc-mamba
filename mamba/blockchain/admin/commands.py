import click
import yaml
import re
from kubernetes import client
from os import path
from utils import hiss, util
from settings import settings

def setup_admin(org):

    # Get domain
    domain = util.get_domain(org)

    # Get orderer information
    orderer_names = settings.ORDERER_ORGS.split(' ')
    orderer_domains = settings.ORDERER_DOMAINS.split(' ')
    if orderer_names == '' and settings.REMOTE_ORDERER_NAME != '':
        orderer_names = settings.REMOTE_ORDERER_NAME.split(' ')
        orderer_domains = settings.REMOTE_ORDERER_DOMAIN.split(' ')

    # Build endorsement config
    peer_orgs = '%s %s' % (settings.PEER_ORGS, settings.ENDORSEMENT_ORG_NAME)
    peer_domains = '%s %s' % (settings.PEER_DOMAINS, settings.ENDORSEMENT_ORG_DOMAIN)
    print(peer_orgs)

    # Create application artifact folder
    hiss.echo('Create wallet folder')
    ## Find efs pod
    pods = settings.k8s.find_pod(namespace="default", keyword="test-efs")
    if not pods:
        return hiss.hiss('cannot find tiller pod')

    mkdir_cmd = ('mkdir -p '+settings.EFS_ROOT+'/admin-v2/wallet;')

    # Exec command
    exec_command = [
        '/bin/bash',
        '-c',
        '%s'  % (mkdir_cmd)]

    result_get_folder = settings.k8s.exec_pod(
        podName=pods[0], namespace="default", command=exec_command)
    hiss.sub_echo(result_get_folder.data)

    # Create temp folder & namespace
    settings.k8s.prereqs(domain)
    dict_env = {
        'ORG_NAME': org,
        'ORG_DOMAIN': domain,
        'PEER_NAMES': peer_orgs,
        'PEER_DOMAINS': peer_domains,
        'ORDERER_DOMAIN': orderer_domains[0],
        'ORGDERER_NAME': orderer_names[0],
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND,
        'PVS_PATH': settings.PVS_PATH
    }

    # Apply deployment
    k8s_template_file = '%s/admin/admin-deployment.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

    # Apply service
    k8s_template_file = '%s/admin/admin-service.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def del_admin(org):

    # Get domain
    domain = util.get_domain(org)
    name = 'admin-v2-%s' % org

    # Delete job pod
    return settings.k8s.delete_stateful(name=name, namespace=domain)

def setup_all_admin():
    orgs = settings.PEER_ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        setup_admin(org)

def delete_all_admin():
    orgs = settings.PEER_ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        del_admin(org)

@click.group()
def admin():
    '''Admin Service'''
    pass

@admin.command('setup', short_help='Create new a new Admin service')
def setup():
    hiss.rattle('Create new Admin service in all org')

    setup_all_admin()

@admin.command('delete', short_help='Delete the Admin service')
def delete():
    hiss.rattle('Delete the Admin service in all org')

    delete_all_admin()
