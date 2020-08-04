import click
import os
import time
from settings import settings
from os import path

from utils import hiss, util

def get_working_orgs_domain():
    orgs = settings.PEER_ORGS.split(' ')
    if len(orgs) > 1:
        hiss.hiss('Function is still develop')
    domain = util.get_domain(orgs[0])
    settings.k8s.prereqs(domain)

    return [orgs[0], domain]

def fetch_config(org=None, domain=None):

    if not org or not domain:
        [org, domain] = get_working_orgs_domain()

    dict_env = {
        'ORG_NAME': org,
        'ORG_DOMAIN': domain,
        'ORDERER_NAME': settings.ORDERER_ORGS,
        'ORDERER_DOMAIN': settings.ORDERER_DOMAINS,
        'CHANNEL_NAME': settings.CHANNEL_NAME,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND
    }
    k8s_template_file = '%s/add-org/2fetch-channel.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def modify_config(domain=None):
    if not domain:
        [_, domain] = get_working_orgs_domain()

    dict_env = {
        'ORG_DOMAIN': domain,
        'NEW_ORG_NAME': settings.NEW_ORG_NAME,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND
    }
    k8s_template_file = '%s/add-org/3modifyingorgmaterial.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def create_config_update_pb(domain=None):

    if not domain:
        [_, domain] = get_working_orgs_domain()

    dict_env = {
        'ORG_DOMAIN': domain,
        'CHANNEL_NAME': settings.CHANNEL_NAME,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND
    }
    k8s_template_file = '%s/add-org/4createconfigupdate.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)

def update_channel_config(org=None, domain=None):

    if not org or not domain:
        [org, domain] = get_working_orgs_domain()

    dict_env = {
        'ORG_DOMAIN': domain,
        'ORG_NAME': org,
        'CHANNEL_NAME': settings.CHANNEL_NAME,
        'ORDERER_NAME': settings.ORDERER_ORGS,
        'ORDERER_DOMAIN': settings.ORDERER_DOMAINS,
        'EFS_SERVER': settings.EFS_SERVER,
        'EFS_PATH': settings.EFS_PATH,
        'EFS_EXTEND': settings.EFS_EXTEND
    }
    k8s_template_file = '%s/add-org/6updatechannelconfig.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=k8s_template_file, dict_env=dict_env)


def auto_update_channel_config():

    fetch_config()
    modify_config()
    create_config_update_pb()
    time.sleep(2)
    update_channel_config()
    return True

def del_fetch_config(domain=None):
    if not domain:
        [_, domain] = get_working_orgs_domain()
    jobname = 'fetch-channel'
    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domain)

def del_modify_config(domain=None):
    if not domain:
        [_, domain] = get_working_orgs_domain()
    jobname = 'modifyingorgmaterial'
    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domain)

def del_config_update_pb(domain=None):
    if not domain:
        [_, domain] = get_working_orgs_domain()
    jobname = 'createconfigupdate'
    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domain)

def del_update_channel_config(domain=None):
    if not domain:
        [_, domain] = get_working_orgs_domain()
    jobname = 'updatechannelconfig'
    # Delete job pod
    return settings.k8s.delete_job(name=jobname, namespace=domain)

def auto_del_update_channel_config():
    del_fetch_config()
    del_modify_config()
    del_config_update_pb()
    del_update_channel_config()

@click.group()
def channel_config():
    """Channel config"""
    pass

@channel_config.command('auto-update', short_help="Create all job update channel config")
def auto_update():
    hiss.rattle('Update channel config')
    auto_update_channel_config()

@channel_config.command('auto-delete', short_help="Delete all job update channel config")
def auto_delete():
    hiss.rattle('Delete channel config')
    auto_del_update_channel_config()

@channel_config.command('fetch', short_help="Fetch channel config")
def fetch():
    hiss.rattle('Fetch channel config')
    fetch_config()

@channel_config.command('create-pb', short_help="Create modify config pb")
def create_pb():
    hiss.rattle('Create modify config pb')
    create_config_update_pb()

@channel_config.command('update', short_help="Update channel config using modify config pb")
def update():
    hiss.rattle('Update channel config using modify config pb')
    update_channel_config()

@channel_config.command('del-fetch', short_help="Delete job fetch channel config")
def del_fetch():
    hiss.rattle('Delete job fetch channel config')
    del_fetch_config()

@channel_config.command('del-create-pb', short_help="Delete job create modify config pb")
def del_create_pb():
    hiss.rattle('Delete job create modify config pb')
    del_config_update_pb()

@channel_config.command('del-update', short_help="Delete job update channel config using modify config pb")
def del_update():
    hiss.rattle('Delete job update channel config using modify config pb')
    del_update_channel_config()
