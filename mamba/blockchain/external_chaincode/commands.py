import click
from kubernetes import client
from os import path
from utils import hiss, util
import settings

def deploy_external_cc(peer, cc_name, cc_image, cc_package_id):
    # Get domain
    domain = util.get_domain(peer)
    
    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    # Create config map
    k8s_template_file = '%s/external-chaincode/chaincode-stateful.yaml' % util.get_k8s_template_path()
    dict_env = {
        'PEER_NAME': peer,
        'PEER_DOMAIN': domain,
        'CHAINCODE_NAME': cc_name,
        'CHAINCODE_IMAGE': cc_image,
        'CHAINCODE_PACKAGE_ID': cc_package_id
    }
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

    chaincode_service = '%s/external-chaincode/chaincode-service.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=chaincode_service, dict_env=dict_env)

def config_peer(peer):
    # Get domain
    domain = util.get_domain(peer)

    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    # Create config map
    k8s_template_file = '%s/external-chaincode/builders-config.yaml' % util.get_k8s_template_path()
    dict_env = {
        'PEER_DOMAIN': domain
    }
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def deploy_all_external_cc(ccname, ccimage, packageid):
    orgs = settings.PEER_ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        deploy_external_cc(org, ccname, ccimage, packageid)

def config_all_peer():
    orgs = settings.PEER_ORGS.split(' ')
    # TODO: Multiprocess
    for org in orgs:
        config_peer(org)

def del_config():
    print('TODO')

@click.group()

def externalCC():
    """External Chaincode"""
    pass

@externalCC.command('config', short_help="Create config map")
def config():
    hiss.rattle('Create config map')
    config_all_peer()

@externalCC.command('deploy', short_help="Deploy external chaincode")
@click.option('--ccname', help="Chaincode name")
@click.option('--ccimage', help="Chaincode image")
@click.option('--packageid', help="Chaincode package Id")
def deploy(ccname, ccimage, packageid):
    hiss.rattle('Deploy external chaincode')
    deploy_all_external_cc(ccname, ccimage, packageid)

@externalCC.command('delConfig', short_help="Delete config map")
def delete():
    hiss.rattle('Delete config map')
    del_config()
