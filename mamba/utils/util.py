import os
from os.path import expanduser
import datetime
import json
import re
import yaml
from utils import hiss
from settings import settings

class Result(object):
    def __init__(self, success, msg=None, data=None):
        self.success = success
        self.msg = msg
        self.data = data
    def __str__(self):
        return '{\"success\": \"%s\", \"msg\": \"%s\", \"data\":\"%s\\"}' % (self.success, self.msg, self.data)

def load_yaml_config_template(yaml_template_path, dict_env):
    new_yaml_file_name = yaml_template_path.split('/').pop()
    # Load template file
    with open(yaml_template_path, 'r') as sources:
        lines = sources.readlines()
        out_data = []
    # Replace variable
    for line in lines:
        out_line = line
        for key, value in dict_env.items():
            out_line = re.sub(r'{{%s}}' % key, value, out_line)
        out_data.append(out_line)
    # Get time now
    current_time = split_timenow_utc()

     # Create yaml_path
    hiss.echo('Create yaml file')
    yaml_path = '%s/%s/%s_%s' % (get_temp_path(),
                                     current_time[0], current_time[1], new_yaml_file_name)
    # Write yaml -> yaml_path
    with open(yaml_path, "w") as sources:
        for line in out_data:
            sources.write(line)

    # Read new yaml
    with open(yaml_path, 'r') as ymlfile:
        config = yaml.load_all(ymlfile)
    return yaml_path, config

def smart_append(list_item, items):
    if isinstance(items, list):
        list_item += items
    else:
        list_item.append(items)
    return list_item


def get_temp_path():
    return expanduser('~/.akachain/akc-mamba/mamba/_temp')


def get_k8s_template_path():
    return expanduser('~/.akachain/akc-mamba/mamba/blockchain/template')


def split_timenow_utc():
    # Get current datetime (UTC)
    current_time = datetime.datetime.utcnow().replace(
        microsecond=0).isoformat().split('T')

    current_time[1] = current_time[1].replace(':','')
    return current_time


def make_folder(path_folder):
    if not os.path.exists(path_folder):
        hiss.sub_echo('Folder %s does not exists. \n\tCreating...' %
                      path_folder)
        os.mkdir(path_folder)
    else:
        hiss.sub_echo('Folder temp %s exists.' % path_folder)


def make_temp_folder():
    hiss.echo('Create Folder temp')
    temp_path = get_temp_path()
    make_folder(temp_path)

    # Get current time
    current_time = split_timenow_utc()

    # Make folder temp if it not exists
    yaml_path = '%s/%s' % (temp_path, current_time[0])
    make_folder(yaml_path)


def get_domain(org_name):
    orgs = settings.ORGS.split(' ')
    domains = settings.DOMAINS.split(' ')

    if org_name in orgs:
        return domains[orgs.index(org_name)]
    else:
        return hiss.hiss('org_name: %s does not exists in env file' % org_name)

def get_peer_external_domain(peer, index_peer):
    peers = settings.PEER_ORGS.split(' ')

    if index_peer == 0:
        ex_domains = settings.EXTERNAL_ORG_PEER0_ADDRESSES.split(' ')
    else:
        ex_domains = settings.EXTERNAL_ORG_PEER1_ADDRESSES.split(' ')

    if peer in peers:
        if len(ex_domains) > peers.index(peer):
            return ex_domains[peers.index(peer)]
        else:
            return ''
    else:
        return hiss.hiss('peer: %s does not exists in env file' % peer)
