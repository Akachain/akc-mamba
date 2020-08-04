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

def setup_grafana():

    hiss.echo('Deploy grafana')
    namespace = get_namespace()

    # Create temp folder & namespace
    settings.k8s.prereqs(namespace)

    dict_env = {
        'DOMAIN': namespace
    }

    # Deploy grafana sts
    grafana_template = '%s/grafana/grafana-stateful.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=namespace, k8s_template_file=grafana_template, dict_env=dict_env)
    # Deploy grafana svc
    grafana_sv_template = '%s/grafana/grafana-service-stateful.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=namespace, k8s_template_file=grafana_sv_template, dict_env=dict_env)

def del_grafana():
    # Delete
    return settings.k8s.delete_stateful(name='grafana', namespace=get_namespace())

@click.group()
def grafana():
    """Grafana"""
    pass

@grafana.command('setup', short_help="Setup grafana")
def setup():

    hiss.rattle('Setup grafana')
    setup_grafana()

@grafana.command('delete', short_help="Delete grafana")
def delete():

    hiss.rattle('Delete grafana')
    del_grafana()
