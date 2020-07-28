import click
import yaml
import re
import json
import os
import time
from kubernetes import client
from os import path
from utils import hiss, util
from settings import settings

def get_namespace():
    # Get domain
    domains = settings.ORDERER_DOMAINS.split(' ')
    if len(domains) == 0:
        domains = settings.PEER_DOMAINS.split(' ')
    explorer_namespace = domains[0]
    
    # Create temp folder & namespace
    settings.k8s.prereqs(explorer_namespace)
    return explorer_namespace

def generate_prom_config():
    prom_target = ''
    # Get orderer target
    orderers = settings.ORDERER_ORGS.split(' ')
    for orderer in orderers:
        domain = util.get_domain(orderer)
        for peer in range(int(settings.NUM_ORDERERS)):
            if len(prom_target) > 0:
                prom_target += ','
            prom_target += '\'orderer%s-%s.%s:10443\'' % (peer, orderer, domain)

    # Get peer target
    peerorgs = settings.PEER_ORGS.split(' ')
    for peerorg in peerorgs:
        domain = util.get_domain(peerorg)
        for peer in range(int(settings.NUM_PEERS)):
            if len(prom_target) > 0:
                prom_target += ','
            prom_target += '\'peer%s-%s.%s:10443\'' % (peer, peerorg, domain)
    dict_env = {
        'PROM_TARGET': prom_target
    }

    # Load config
    config_template = '%s/prometheus/prometheus-template.yml' % util.get_k8s_template_path()
    yaml_path, config = util.load_yaml_config_template(
        yaml_template_path=config_template, dict_env=dict_env)

    print('config: ', config)
    return yaml_path

def cp_config_efs(yaml_path):
    # Find efs pod
    pods = settings.k8s.find_pod(namespace="default", keyword="test-efs")
    if not pods:
        return hiss.hiss('cannot find tiller pod')

    # Create folder config
    exec_command = [
        '/bin/bash',
        '-c',
        'mkdir -p %s/promconfig' % (settings.EFS_ROOT)]
    result_create_folder = settings.k8s.exec_pod(
        podName=pods[0], namespace="default", command=exec_command)
    if result_create_folder.success == False:
        return hiss.hiss('cannot remove folders in %s' % pods[0])

    # Copy to efs pod
    target_file = '%s/promconfig/prometheus.yml' % settings.EFS_ROOT
    if not settings.k8s.cp_to_pod(podName=pods[0], namespace='default', source=yaml_path, target=target_file):
        return hiss.hiss('connot copy test chaincode to pod %s' % pods[0])

    return True

def setup_prometheus():

    hiss.echo('Generate prometheus config')
    config_path = generate_prom_config()
    if not cp_config_efs(config_path):
        return util.Result(success=False, msg='Cannot copy prom config to efs pod')

    hiss.echo('Deploy prometheus')
    # Get domain
    prom_namespace = get_namespace()
    
    # Create temp folder & namespace
    settings.k8s.prereqs(prom_namespace)

    dict_env = {
        'DOMAIN': prom_namespace,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND
    }

    # Deploy prometheus sts
    prom_template = '%s/prometheus/prometheus-stateful.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=prom_namespace, k8s_template_file=prom_template, dict_env=dict_env)
    prom_svc_template = '%s/prometheus/prometheus-service-stateful.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=prom_namespace, k8s_template_file=prom_svc_template, dict_env=dict_env)

def del_prometheus():
    # Delete prom
    return settings.k8s.delete_stateful(name='prometheus', namespace=get_namespace())

@click.group()
def prometheus():
    """Prometheus"""
    pass

@prometheus.command('setup', short_help="Setup prometheus")
def setup():

    hiss.rattle('Setup prometheus')
    setup_prometheus()
    


@prometheus.command('delete', short_help="Delete prometheus")
def delete():

    hiss.rattle('Delete prometheus')
    del_prometheus()
