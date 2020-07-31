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

def setup_explorer_db():
    # Get domain
    explorer_db_namespace = get_namespace()

    # Create temp folder & namespace
    settings.k8s.prereqs(explorer_db_namespace)

    dict_env = {
        'DOMAIN': explorer_db_namespace,
        'DATABASE_PASSWORD': 'Akachain'
    }

    # Deploy explorer db sts
    explorer_db_template = '%s/explorer/explorer-db-deployment.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=explorer_db_namespace, k8s_template_file=explorer_db_template, dict_env=dict_env)

    # Deploy explorer db svc
    explorer_db_svc_template = '%s/explorer/explorer-db-service.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=explorer_db_namespace, k8s_template_file=explorer_db_svc_template, dict_env=dict_env)

    # Create tables
    ## Find explorer_db pod
    pods = settings.k8s.find_pod(namespace=explorer_db_namespace, keyword="explorer-db")
    if not pods:
        return hiss.hiss('cannot find tiller pod')

    create_tbl_cmd = 'chmod 700 /opt/createdb_new.sh; /opt/createdb_new.sh'
    exec_command = [
        '/bin/bash',
        '-c',
        '%s'  % (create_tbl_cmd)]

    result_get_folder = settings.k8s.exec_pod(
        podName=pods[0], namespace=explorer_db_namespace, command=exec_command)
    hiss.sub_echo(result_get_folder.data)

def generate_explorer_config():
    # Load template config
    config_template_path = os.path.abspath(os.path.join(__file__, "../config.json"))
    with open(config_template_path, 'r') as f:
        explorer_config = json.load(f)

    # Update config
    orgs = settings.PEER_ORGS.split(' ')
    orgs_msp = []
    for org in orgs:
        orgs_msp.append('%sMSP' % org)

    client = {
        orgs[0]: {
            'tlsEnable': True,
            'organization': orgs_msp[0],
            'channel': settings.CHANNEL_NAME,
            'credentialStore': {
                'path': '/opt/explorer/crypto-path/fabric-client-kv-%s' % orgs[0],
                'cryptoStore': {
                    'path': '/tmp/crypto-store/fabric-client-kv-%s' % orgs[0]
                }
            }
        }
    }
    explorer_config['network-configs']['network-1']['clients'] = client

    channel_peers = {}
    for x in range(len(orgs)):
        domain = util.get_domain(orgs[x])
        for y in range(int(settings.NUM_PEERS)):
            peer_name = 'peer%s-%s.%s' % (y, orgs[x], domain)
            channel_peers[peer_name] = {}
    explorer_config['network-configs']['network-1']['channels'] = {
        '%s' % settings.CHANNEL_NAME: {
            'peers': channel_peers,
            'connection': {
                'timeout': {
                    'peer': {
                        "endorser": "6000",
                        "eventReg": "6000",
                        "eventHub": "6000"
                    }
                }
            }
        }
    }

    orgs_config = {}
    # org
    for i in range(len(orgs)):
        domain = util.get_domain(orgs[i])
        p_config = {
            'mspid': '%s' % orgs_msp[i],
            'fullpath': False,
            'adminPrivateKey': {
                'path': '/opt/explorer/crypto-config/peerOrganizations/%s/users/admin/msp/keystore' % domain
            },
            'signedCert': {
                'path': '/opt/explorer/crypto-config/peerOrganizations/%s/users/admin/msp/signcerts' % domain
            }
        }
        orgs_config[orgs_msp[i]] = p_config
    # orderer
    orderers = settings.ORDERER_ORGS.split(' ')
    domain = util.get_domain(orderers[0])
    o_config = {
        'mspid': '%sMSP' % orderers[0],
        'adminPrivateKey': {
            'path': '/opt/explorer/crypto-config/ordererOrganizations/'+domain+'/users/admin/msp/keystore'
        }
    }
    orgs_config['%sMSP' % settings.ORDERER_ORGS] = o_config
    explorer_config['network-configs']['network-1']['organizations'] = orgs_config
    
    # peers
    peers_config = {}
    for x in range(len(orgs)):
        domain = util.get_domain(orgs[x])
        for y in range(int(settings.NUM_PEERS)):
            peer_name = 'peer%s-%s.%s' % (y, orgs[x], domain)
            config = {
                'tlsCACerts': {
                    'path': '/opt/explorer/crypto-config/peerOrganizations/'+domain+'/peers/peer%s.%s' % (y, domain)+'/tls/tlsca.mambatest-cert.pem'
                },
                'url':  'grpcs://%s:7051' % peer_name,
                'eventUrl': 'grpcs://%s:7053' % peer_name,
                'grpcOptions': {
                    'ssl-target-name-override': peer_name
                }
            }
            peers_config[peer_name] = config
    explorer_config['network-configs']['network-1']['peers'] = peers_config
    # orderers
    orderers_config = {}
    for x in range(len(orderers)):
        domain = util.get_domain(orderers[x])
        for y in range(int(settings.NUM_ORDERERS)):
            orderer_name = 'orderer%s-%s.%s' % (y, orderers[y], domain)
            config = {
                'url': 'grpcs://%s:7050' % orderer_name,
                'grpcOptions': {
                    'ssl-target-name-override': orderer_name
                },
                'tlsCACerts': {
                    'path': '/opt/explorer/crypto-config/ordererOrganizations/'+domain+'/orderers/orderer%s.%s' % (y, domain)+'/tls/tlsca.ordererhai-cert.pem'
                }
            }
            orderers_config[orderer_name] = config
    explorer_config['network-configs']['network-1']['orderers'] = orderers_config

    return json.dumps(explorer_config)

def create_explorer_config_in_efs(explorer_config):

    # Find efs pod
    pods = settings.k8s.find_pod(namespace="default", keyword="test-efs")
    if not pods:
        return hiss.hiss('cannot find tiller pod')

    config_path = '%s/explorer-config' % settings.EFS_ROOT
    exec_command = [
        '/bin/bash',
        '-c',
        'mkdir -p '+config_path+'; cd '+config_path+'; echo '+explorer_config+' > config.json']

    create_file = settings.k8s.exec_pod(
        podName=pods[0], namespace="default", command=exec_command)
    if create_file.success == False:
        return hiss.hiss('cannot create explorer config in %s' % pods[0])

def setup_explorer():

    hiss.echo('Generate explorer config')
    config = generate_explorer_config()
    create_explorer_config_in_efs(json.dumps(config))

    hiss.echo('Deploy explorer')
    # Get domain
    explorer_namespace = get_namespace()
    
    # Create temp folder & namespace
    settings.k8s.prereqs(explorer_namespace)

    dict_env = {
        'DOMAIN': explorer_namespace,
        'DATABASE_PASSWORD': 'Akachain',
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND
    }

    # Deploy explorer db sts
    explorer_template = '%s/explorer/explorer-deployment.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=explorer_namespace, k8s_template_file=explorer_template, dict_env=dict_env)

    # Deploy explorer db svc
    explorer_svc_template = '%s/explorer/explorer-service.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=explorer_namespace, k8s_template_file=explorer_svc_template, dict_env=dict_env)


def del_explorer_db():
    # Delete sts
    return settings.k8s.delete_stateful(name='explorer-db', namespace=get_namespace(), delete_pvc=True)

def del_explorer():
    # Delete sts
    return settings.k8s.delete_stateful(name='explorerpod', namespace=get_namespace())

@click.group()
def explorer():
    """Explorer"""
    pass

@explorer.command('setup', short_help="Setup explorer")
def setup():
    hiss.rattle('Setup explorer DB')
    setup_explorer_db()

    hiss.rattle('Setup explorer')
    setup_explorer()

@explorer.command('delete', short_help="Delete explorer")
def delete():
    hiss.rattle('Delete explorer DB')
    del_explorer_db()

    hiss.rattle('Delete explorer')
    del_explorer()
