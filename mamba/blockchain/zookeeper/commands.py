import click
import yaml
import re
import datetime
from kubernetes import client
from os import path
from kubernetes.client.rest import ApiException
from utils import hiss, util
from settings import settings


def terminate_zookeeper():
    domain = settings.KAFKA_NAMESPACE
    name = 'zoo'

    # Terminate stateful set
    return settings.k8s.delete_stateful(name=name, namespace=domain, delete_pvc=True)

def delete_zookeeper():
    domain = settings.KAFKA_NAMESPACE
    name = 'zoo'

    # Delete stateful set
    return settings.k8s.delete_stateful(name=name, namespace=domain)

def setup_zookeeper():

    domain = settings.KAFKA_NAMESPACE

    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    dict_env = {
        'KAFKA_NAMESPACE': domain
    }

    zk_cs_template_file = '%s/zookeeper/0zk-cs.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=zk_cs_template_file, dict_env=dict_env)

    zk_hs_template_file = '%s/zookeeper/1zk-hs.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=zk_hs_template_file, dict_env=dict_env)

    zk_set_template_file = '%s/zookeeper/2zk-set.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=zk_set_template_file, dict_env=dict_env)


@click.group()
def zookeeper():
    """Zookeeper"""
    pass


@zookeeper.command('setup', short_help="Setup Zookeeper")
def setup():
    hiss.rattle('Setup Zookeeper')
    setup_zookeeper()

@zookeeper.command('delete', short_help="Delete Zookeeper")
def delete():
    hiss.rattle('Delete Zookeeper')
    delete_zookeeper()

@zookeeper.command('terminate', short_help="Terminate Zookeeper")
def terminate():
    hiss.rattle('Terminate Zookeeper')
    terminate_zookeeper()
