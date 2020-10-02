import re
import yaml
import json
import datetime
from kubernetes import client
from kubernetes.client.rest import ApiException
from os import path

from settings import settings
from utils import util, hiss


class Namespace:
    def __init__(self, ns_name):
        self.name = ns_name

    def create(self):
        # Load template file
        k8s_template_file = '%s/namespace/namespaces.yaml' % util.get_k8s_template_path()
        with open(k8s_template_file, 'r') as sources:
            lines = sources.readlines()
            out_data = []

        # Replace variable
        for line in lines:
            out_line = re.sub(r'{{NAMESPACES}}', self.name, line)
            out_data.append(out_line)

        # Get current datetime (UTC)
        current_time = datetime.datetime.utcnow().replace(
            microsecond=0).isoformat().split('T')

        # Make folder temp if it not exists
        tmp_path = "%s/%s" % (util.get_temp_path(), current_time[0])
        util.make_folder(tmp_path)

        # Create yaml_path
        yaml_path = '%s/%s/%s_namespaces.yaml' % (util.get_temp_path(), current_time[0], current_time[1])
        # Write yaml -> yaml_path
        with open(yaml_path, "w") as sources:
            for line in out_data:
                sources.write(line)

        # Execute yaml
        with open(yaml_path) as f:
            dep = yaml.safe_load(f)
            try:
                settings.k8s.coreApi.create_namespace(body=dep)
                hiss.sub_echo('Create namespace successfully')
                return True
            except ApiException as e:
                return hiss.hiss("Exception when calling CoreV1Api->create_namespace: %s\n" % e)

    def get(self):
        try:
            list = settings.k8s.coreApi.list_namespace()
        except ApiException as e:
            return hiss.hiss("Exception when calling CoreV1Api->list_namespace: %s\n" % e)
        ns = next((x for x in list.items if x.metadata.name == self.name), None)
        if not ns:
            return False
        else:
            return ns

    def delete(self):
        try:
            api_response = settings.k8s.coreApi.delete_namespace(name=self.name)
            return api_response
        except ApiException as e:
            return hiss.hiss("Exception when calling CoreV1Api->delete_namespace: %s\n" % e)
