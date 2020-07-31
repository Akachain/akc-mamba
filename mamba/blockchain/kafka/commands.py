import click
import yaml
import re
import datetime
from kubernetes import client
from os import path
from kubernetes.client.rest import ApiException
from utils import hiss, util
from settings import settings


def terminate_kafka():
    domain = settings.KAFKA_NAMESPACE
    name = 'kafka'

    # Terminate stateful set
    return settings.k8s.delete_stateful(name=name, namespace=domain, delete_pvc=True)

def delete_kafka():
    domain = settings.KAFKA_NAMESPACE
    name = 'kafka'

    # Delete stateful set
    return settings.k8s.delete_stateful(name=name, namespace=domain)

def setup_kafka():

    domain = settings.KAFKA_NAMESPACE

    # Create temp folder & namespace
    settings.k8s.prereqs(domain)

    dict_env = {
        'KAFKA_NAMESPACE': domain
    }

    zk_cs_template_file = '%s/kafka/0kafka-hs.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=zk_cs_template_file, dict_env=dict_env)

    zk_hs_template_file = '%s/kafka/1kafka-cs.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=zk_hs_template_file, dict_env=dict_env)

    zk_set_template_file = '%s/kafka/2kafka-set.yaml' % util.get_k8s_template_path()
    settings.k8s.apply_yaml_from_template(
        namespace=domain, k8s_template_file=zk_set_template_file, dict_env=dict_env)


@click.group()
def kafka():
    """Kafka"""
    pass


@kafka.command('setup', short_help="Setup Kafka")
def setup():
    hiss.rattle('Setup Kafka')
    setup_kafka()

@kafka.command('delete', short_help="Delete Kafka")
def delete():
    hiss.rattle('Delete Kafka')
    delete_kafka()

@kafka.command('terminate', short_help="Terminate Kafka")
def terminate():
    hiss.rattle('Terminate Kafka')
    terminate_kafka()
