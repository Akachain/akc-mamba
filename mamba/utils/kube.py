import os
import yaml
import re
import time
from kubernetes import client, config
from kubernetes.client.rest import ApiException
from kubernetes.stream import stream
from pprint import pprint
from utils import hiss, util
from k8s.namespace import Namespace
from settings import settings


class KubeHelper:

    config.load_kube_config()
    coreApi = client.CoreV1Api()
    appsApi = client.AppsV1Api()
    batchApi = client.BatchV1Api()

    def read_pod_log(self, name, namespace):
        pods = self.find_pod(namespace, name)
        if not pods:
            msg = 'Pod %s not found!' % name
            return util.Result(success=False, msg=msg)
        
        for pod in pods:
            try:
                api_response = self.coreApi.read_namespaced_pod_log(pod, namespace)
                print(api_response)
            except ApiException as e:
                print("Exception when calling CoreV1Api->read_namespaced_pod_log: %s\n" % e)


    def read_stateful_set(self, name, namespace):
        try:
            api_response = self.appsApi.read_namespaced_stateful_set(name, namespace)
            return util.Result(success=True, data=api_response)
        except ApiException as e:
            msg = "Exception when calling AppsV1Api->read_namespaced_stateful_set: %s\n" % e
            return util.Result(success=False, msg=msg)

    def delete_job(self, name, namespace):
        try:
            body = client.V1DeleteOptions(propagation_policy='Background')
            api_response = self.batchApi.delete_namespaced_job(name, namespace, body=body)
            hiss.echo('Delete job %s on namespace %s success' % (name, namespace))
            return util.Result(success=True, data=api_response)
        except ApiException as e:
            err_msg = "Exception when calling BatchV1Api->delete_namespaced_job: %s\n" % e
            return util.Result(success=hiss.hiss(err_msg), msg=err_msg)

    def delete_persistent_volume_claim(self, name, namespace):
        try:
            api_response = self.coreApi.delete_namespaced_persistent_volume_claim(name=name, namespace=namespace)
            return util.Result(success=True, data=api_response)
        except ApiException as e:
            err_msg = "Exception when calling CoreV1Api->delete_namespaced_persistent_volume_claim: %s\n" % e
            return util.Result(success=hiss.hiss(err_msg), msg=err_msg)

    def delete_stateful(self, name, namespace, delete_pvc=False):
        action = 'Delete'
        if delete_pvc == True:
            action = 'Terminate'
            read_result = self.read_stateful_set(name, namespace)
            if read_result.success == False:
                return read_result
            volume_claim_templates = read_result.data.spec.volume_claim_templates
            if volume_claim_templates != None:
                for pvt in volume_claim_templates:
                    pvt_name = pvt.metadata.name
                    list_pvc = self.find_pvc(namespace, keyword=pvt_name)
                    for pvc in list_pvc:
                        hiss.echo('Delete pvc %s ' % pvc)
                        self.delete_persistent_volume_claim(name=pvc, namespace=namespace)

        try:
            body = client.V1DeleteOptions(propagation_policy='Background')
            api_response = self.appsApi.delete_namespaced_stateful_set(name, namespace, body=body)
            self.check_pod_status_by_keyword(keyword=name, namespace=namespace, is_delete=True)
            hiss.echo('%s stateful set %s on namespace %s success' % (action, name, namespace))
            return util.Result(success=True, data=api_response)
        except ApiException as e:
            err_msg = "Exception when calling AppsV1Api->delete_namespaced_stateful_set: %s\n" % e
            return util.Result(success=hiss.hiss(err_msg), msg=err_msg)

    def check_pod_status_by_keyword(self, keyword, namespace, is_delete=False, check_job_success=False):
        
        condition_status = 'Running' if is_delete else 'Pending'
        condition_status = 'Succeeded' if check_job_success else condition_status

        # Check status
        count = 0 # Use count variable to detect replica
        while True:
            time.sleep(1)
            # Find efs pod
            pods = self.find_pod(
                namespace=namespace, keyword=keyword)
            if not pods:
                if is_delete:
                    hiss.sub_echo('done')
                    break
                hiss.sub_echo('cannot find tiller pod when check status.. retry')
                time.sleep(1)
                continue

            if is_delete:
                hiss.sub_echo('%s terminating' % keyword)
                time.sleep(3)
                continue

            # Check replication
            if len(pods) == count:
                break
            # Check status
            while True:
                resp = self.coreApi.read_namespaced_pod_status(name=pods[count],
                                                        namespace=namespace)
                hiss.sub_echo('%s %s' % (pods[count], resp.status.phase))
                if check_job_success:
                    if resp.status.phase == condition_status:
                        count += 1
                        break
                    time.sleep(3)
                else:
                    if resp.status.phase != condition_status:
                        count += 1
                        break
                    time.sleep(3)

    def prereqs(self, namespace):
        # Create temp folder
        util.make_temp_folder()

        # Create namespace
        settings.k8s.create_namespace(namespace)

    def apply_yaml_from_template(self, namespace, k8s_template_file, dict_env):
        yaml_path, _ = util.load_yaml_config_template(k8s_template_file, dict_env)
        hiss.sub_echo('Create %s successfully' % yaml_path)

        # Execute yaml
        hiss.echo('Apply yaml file')
        stream = open(yaml_path, 'r')
        docs = yaml.safe_load_all(stream)

        success = True
        for doc in docs:
            try:
                if doc['kind'] == 'Service':
                    self.coreApi.create_namespaced_service(namespace, body=doc)
                    continue
            except ApiException as e:
                print("Service already deployed!")
                continue
            try:
                if doc['kind'] == 'StatefulSet':
                    self.appsApi.create_namespaced_stateful_set(
                        namespace, body=doc)
                    self.check_pod_status_by_keyword(keyword=doc['metadata']['name'], namespace=namespace)
                if doc['kind'] == 'Deployment':
                    self.appsApi.create_namespaced_deployment(
                        namespace, body=doc)
                    self.check_pod_status_by_keyword(keyword=doc['metadata']['name'], namespace=namespace)
                if doc['kind'] == 'Job':
                    self.batchApi.create_namespaced_job(namespace, body=doc)
                    self.check_pod_status_by_keyword(keyword=doc['metadata']['name'], namespace=namespace, check_job_success=True)
            except ApiException as e:
                print("Exception when apply yaml: %s\n" % e)
                success = False
                # self.check_pod_status_by_keyword(keyword=doc['metadata']['name'], namespace=namespace)
        return success

    def create_namespace(self, name):
        hiss.echo('Create Namespace %s' % name)
        ns = Namespace(name)
        # ns.create()
        if not ns.get():
            hiss.sub_echo('Namespace %s does not exist. Creating...' % name)
            ns.create()
        else:
            hiss.sub_echo('Namespace %s already exists' % name)

        # ns.delete()

    def show_all_pods(self):
        ret = self.coreApi.list_pod_for_all_namespaces(watch=False)
        for i in ret.items:
            print("%s\t%s\t%s" %
                  (i.status.pod_ip, i.metadata.namespace, i.metadata.name))

    def make_port_forward(self, podName, namespace, ports):
        try:
            resp = self.coreApi.connect_get_namespaced_pod_portforward(
                name=podName, namespace=namespace, ports=ports)
            return resp
        except ApiException as e:
            hiss.hiss(
                "Exception when calling CoreV1Api->connect_post_namespaced_pod_portforward: %s\n" % e)

    # Find name of the pod in a namespace with a specific keyword
    def find_pod(self, namespace, keyword):
        mypods = []
        try:
            ret = self.coreApi.list_namespaced_pod(namespace)
            for item in ret.items:
                if keyword in item.metadata.name:
                    mypods.append(item.metadata.name)
        except ApiException as e:
            hiss.hiss("Exception when calling Api: %s\n" % e)
        return mypods

    # Find name of the persistent volume claim in a namespace with a specific keyword
    def find_pvc(self, namespace, keyword):
        list_pvc = []
        try:
            ret = self.coreApi.list_namespaced_persistent_volume_claim(namespace)
            for item in ret.items:
                if keyword in item.metadata.name:
                    list_pvc.append(item.metadata.name)
        except ApiException as e:
            hiss.hiss("Exception when calling Api: %s\n" % e)
        return list_pvc

    # Requests to exec of Pod
    def exec_pod(self, podName, namespace, command):
        try:
            resp = stream(self.coreApi.connect_get_namespaced_pod_exec,
                          name=podName, namespace=namespace, container="test-pod", stderr=True, stdin=True, stdout=True, command=command)
            # return util.resultDict(success=True, msg='Success', data=resp)
            return util.Result(success=True, msg='Success', data=resp)
        except ApiException as e:
            err_msg = "Exception when calling CoreV1Api->connect_get_namespaced_pod_exec: %s\n" % e
            return util.Result(success=hiss.hiss(err_msg), msg=err_msg)

    def cp_to_pod(self, podName, namespace, source, target):
        if os.path.exists(source):
            sourcePath = source
            if os.path.isdir(sourcePath):
                sourcePath = '%s/.' % source
            cmd = 'kubectl cp %s -n %s %s:%s' % (sourcePath, namespace, podName, target)
            copyResult = os.system(cmd)
            if copyResult != 0:
                return hiss.hiss('cannot copy to pod')
        else:
            return hiss.hiss('file/folder \'%s\' does not exists' % source)
        return True

    def create_stateful_set(self, stsName, namespace, replicas, containers, volumes, volumeClaimTemplates):
        api_version = 'apps/v1'
        kind = 'StatefulSet'

        metadata = client.V1ObjectMeta(name=stsName, namespace=namespace)

        # Build spec_selector
        spec_selector_match_labels = dict()
        spec_selector_match_labels['name'] = stsName
        spec_selector_match_labels['namespace'] = namespace
        spec_selector = client.V1LabelSelector(
            match_labels=spec_selector_match_labels)

        # Build spec_template
        spec_template_metadata_labels = dict()
        spec_template_metadata_labels['name'] = stsName
        spec_template_metadata_labels['namespace'] = namespace
        spec_template_metadata = client.V1ObjectMeta(
            labels=spec_template_metadata_labels)
        spec_template_spec = client.V1PodSpec(
            containers=containers, volumes=volumes)
        spec_template = client.V1PodTemplateSpec(
            metadata=spec_template_metadata, spec=spec_template_spec)

        # Build spec
        spec = client.V1StatefulSetSpec(service_name=stsName, replicas=replicas, selector=spec_selector,
                                        template=spec_template, volume_claim_templates=volumeClaimTemplates)

        # Build body
        body = client.V1StatefulSet(
            api_version=api_version, kind=kind, metadata=metadata, spec=spec)

        # Create stateful set
        try:
            api_response = self.appsApi.create_namespaced_stateful_set(
                namespace=namespace, body=body)
            print('api_response: ', api_response)
        except ApiException as e:
            return hiss.hiss("Exception when calling AppsV1Api->create_namespaced_stateful_set: %s\n" % e)
