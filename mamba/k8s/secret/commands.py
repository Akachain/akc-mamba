import click
import yaml
import re
import os
from kubernetes import client
from os import path
from utils import hiss, util
from settings import settings

def create_docker_secret(namespace, name):
    create_cmd = ('kubectl create secret docker-registry '+name+
    ' --docker-server='+settings.PRIVATE_DOCKER_SEVER+
    ' --docker-username='+settings.PRIVATE_DOCKER_USER+
    ' --docker-password='+settings.PRIVATE_DOCKER_PASSWORD+
    ' --docker-email='+settings.PRIVATE_DOCKER_EMAIL+
    ' -n '+namespace)
    # print(create_cmd)
    res = os.system(create_cmd)
    return True if res == 0 else False

def create_all_docker_secret(name):
    if settings.ORDERER_DOMAINS == '':
        hiss.sub_echo('Create secret in namespace: default')
        create_docker_secret('default', name)

    domains = settings.DOMAINS.split(' ')
    for domain in domains:
        hiss.sub_echo('Create secret in namespace: %s' % domain)
        create_docker_secret(domain, name)

def delete_secret(namespace, name):
    delete_cmd = ('kubectl delete secret '+name+' -n '+namespace)
    res = os.system(delete_cmd)
    return True if res == 0 else False

def delete_all_docker_secret(name):
    if settings.ORDERER_DOMAINS == '':
        hiss.sub_echo('Delete secret in namespace: default')
        delete_secret('default', name)

    domains = settings.DOMAINS.split(' ')
    for domain in domains:
        hiss.sub_echo('Delete secret in namespace: %s' % domain)
        delete_secret(domain, name)

@click.group()
def secret():
    '''Secret'''
    pass

@secret.command('create', short_help='Create docker secret in all namespace')
def create():
    hiss.rattle('Create docker secret in all namespace')

    create_all_docker_secret('mamba')

@secret.command('delete', short_help='Delete docker secret in all namespace')
def delete():
    hiss.rattle('Delete docker secret in all namespace')

    delete_all_docker_secret('mamba')
