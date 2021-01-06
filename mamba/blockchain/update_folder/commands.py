import click
import os
from settings import settings
from os import path
from shutil import copyfile
from utils import hiss, util


def update_folder():
    hiss.rattle('Update folder crt in EFS')

    # Find efs pod
    pods = settings.k8s.find_pod(namespace="default", keyword="test-efs")
    if not pods:
        return hiss.hiss('cannot find tiller pod')

    all_command = ''

    prepare_cmd = 'rm -rf %s/akc-ca-data/crypto-config-v1;' % settings.EFS_ROOT
    prepare_cmd += 'cd %s/akc-ca-data/;'% settings.EFS_ROOT
    all_command += prepare_cmd

    if settings.ORDERER_ORGS != '':
        # Build orderer command
        orderers = settings.ORDERER_ORGS.split(' ')
        orderer_cmd = ''

        for orderer in orderers:
            # Get domain
            domain = util.get_domain(orderer) 
            orderer_cmd += (''
                'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/ca;'
                'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/msp/admincerts;'
                'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/msp/cacerts;'
                'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/msp/tlscacerts;'
                'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/tlsca;'
                'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/msp/admincerts;'
                'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/msp/cacerts;'
                'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/msp/keystore;'
                'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/msp/signcerts;'
                'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/msp/tlscacerts;'
                'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/tls;'
            '')
            for index in range(int(settings.NUM_ORDERERS)):
                orderer_cmd += (''
                    'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/admincerts;'
                    'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/cacerts;'
                    'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/keystore;'
                    'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/signcerts;'
                    'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/tlscacerts;'
                    'mkdir -p crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/tls;'

                    'cp ica-'+orderer+'-ca-chain.pem crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/cacerts/ca.'+domain+'-cert.pem;'
                    'cp ica-'+orderer+'-ca-chain.pem crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/tlscacerts/tlsca.'+domain+'-cert.pem;'
                    'cp ica-'+orderer+'-ca-chain.pem crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/tls/tlsca.'+domain+'-cert.pem;'
                    'cp crypto-config/'+orderer+'.'+domain+'/users/admin/msp/signcerts/cert.pem crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/admincerts/cert.pem;'
                    'cp crypto-config/'+orderer+'.'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/signcerts/cert.pem crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/signcerts/;'
                    'cp crypto-config/'+orderer+'.'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/keystore/*_sk crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/msp/keystore/key.pem;'
                    'cp crypto-config/'+orderer+'.'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/tls/server.crt crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/tls/;'
                    'cp crypto-config/'+orderer+'.'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/tls/server.key crypto-config-v1/ordererOrganizations/'+domain+'/orderers/orderer'+str(index)+'-'+orderer+'.'+domain+'/tls/server.key;'
                '')
            orderer_cmd += (''
                'cp ica-'+orderer+'-ca-chain.pem crypto-config-v1/ordererOrganizations/'+domain+'/ca/ca.'+domain+'-cert.pem;'
                'cp ica-'+orderer+'-ca-chain.pem crypto-config-v1/ordererOrganizations/'+domain+'/msp/cacerts/ca.'+domain+'-cert.pem;'
                'cp ica-'+orderer+'-ca-chain.pem crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/msp/cacerts/ca.'+domain+'-cert.pem;'
                'cp ica-'+orderer+'-ca-chain.pem crypto-config-v1/ordererOrganizations/'+domain+'/tlsca/tlsca.'+domain+'-cert.pem;'
                'cp ica-'+orderer+'-ca-chain.pem crypto-config-v1/ordererOrganizations/'+domain+'/msp/tlscacerts/tlsca.'+domain+'-cert.pem;'
                'cp ica-'+orderer+'-ca-chain.pem crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/msp/tlscacerts/tlsca.'+domain+'-cert.pem;'
                'cp ica-'+orderer+'-ca-chain.pem crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/tls/tlsca.'+domain+'-cert.pem;'
                'cp crypto-config/'+orderer+'.'+domain+'/users/admin/msp/signcerts/cert.pem crypto-config-v1/ordererOrganizations/'+domain+'/msp/admincerts/cert.pem;'
                'cp crypto-config/'+orderer+'.'+domain+'/users/admin/msp/signcerts/cert.pem crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/msp/admincerts/cert.pem;'
                'cp crypto-config/'+orderer+'.'+domain+'/users/admin/msp/keystore/*_sk crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/msp/keystore/key.pem;'
                'cp crypto-config/'+orderer+'.'+domain+'/users/admin/msp/signcerts/cert.pem crypto-config-v1/ordererOrganizations/'+domain+'/users/admin/msp/signcerts/cert.pem;'
                'echo "succeed";'
            '')
        all_command += orderer_cmd

    # Build peer command
    peers = settings.PEER_ORGS.split(' ')
    peer_cmd = ''
    for peer in peers:
        # Get domain
        domain = util.get_domain(peer)
        peer_cmd += (''
            'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/ca;'
            'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/msp/admincerts;'
            'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/msp/cacerts;'
            'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/msp/tlscacerts;'
            'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/tlsca;'
            'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/users/admin/msp/admincerts;'
            'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/users/admin/msp/cacerts;'
            'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/users/admin/msp/keystore;'
            'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/users/admin/msp/signcerts;'
            'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/users/admin/msp/tlscacerts;'
            'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/users/admin/tls;'
        '')
        for index in range(int(settings.NUM_PEERS)):
            peer_cmd += (''
                'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/msp/admincerts;'
                'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/msp/cacerts;'
                'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/msp/keystore;'
                'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/msp/signcerts;'
                'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/msp/tlscacerts;'
                'mkdir -p crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/tls;'

                'cp ica-'+peer+'-ca-chain.pem crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/msp/cacerts/ca.'+domain+'-cert.pem;'
                'cp ica-'+peer+'-ca-chain.pem crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/msp/tlscacerts/tlsca.'+domain+'-cert.pem;'
                'cp ica-'+peer+'-ca-chain.pem crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/tls/tlsca.'+domain+'-cert.pem;'
                'cp crypto-config/'+peer+'.'+domain+'/users/admin/msp/signcerts/cert.pem crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/msp/admincerts/cert.pem;'
                'cp crypto-config/'+peer+'.'+domain+'/peers/peer'+str(index)+'-'+peer+'.'+domain+'/msp/signcerts/cert.pem crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/msp/signcerts/;'
                'cp crypto-config/'+peer+'.'+domain+'/peers/peer'+str(index)+'-'+peer+'.'+domain+'/msp/keystore/*_sk crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/msp/keystore/key.pem;'
                'cp crypto-config/'+peer+'.'+domain+'/peers/peer'+str(index)+'-'+peer+'.'+domain+'/tls/server.crt crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/tls/;'
                'cp crypto-config/'+peer+'.'+domain+'/peers/peer'+str(index)+'-'+peer+'.'+domain+'/tls/server.key crypto-config-v1/peerOrganizations/'+domain+'/peers/peer'+str(index)+'.'+domain+'/tls/server.key;'
            '')
        peer_cmd += (''
            'cp ica-'+peer+'-ca-chain.pem crypto-config-v1/peerOrganizations/'+domain+'/ca/ca.'+domain+'-cert.pem;'
            'cp ica-'+peer+'-ca-chain.pem crypto-config-v1/peerOrganizations/'+domain+'/msp/cacerts/ca.'+domain+'-cert.pem;'
            'cp ica-'+peer+'-ca-chain.pem crypto-config-v1/peerOrganizations/'+domain+'/users/admin/msp/cacerts/ca.'+domain+'-cert.pem;'
            'cp ica-'+peer+'-ca-chain.pem crypto-config-v1/peerOrganizations/'+domain+'/tlsca/tlsca.'+domain+'-cert.pem;'
            'cp ica-'+peer+'-ca-chain.pem crypto-config-v1/peerOrganizations/'+domain+'/msp/tlscacerts/tlsca.'+domain+'-cert.pem;'
            'cp ica-'+peer+'-ca-chain.pem crypto-config-v1/peerOrganizations/'+domain+'/users/admin/msp/tlscacerts/tlsca.'+domain+'-cert.pem;'
            'cp ica-'+peer+'-ca-chain.pem crypto-config-v1/peerOrganizations/'+domain+'/users/admin/tls/tlsca.'+domain+'-cert.pem;'
            'cp crypto-config/'+peer+'.'+domain+'/users/admin/msp/signcerts/cert.pem crypto-config-v1/peerOrganizations/'+domain+'/msp/admincerts/cert.pem;'
            'cp crypto-config/'+peer+'.'+domain+'/users/admin/msp/signcerts/cert.pem crypto-config-v1/peerOrganizations/'+domain+'/users/admin/msp/admincerts/cert.pem;'
            'cp crypto-config/'+peer+'.'+domain+'/users/admin/msp/keystore/* crypto-config-v1/peerOrganizations/'+domain+'/users/admin/msp/keystore/key.pem;'
            'cp crypto-config/'+peer+'.'+domain+'/users/admin/msp/signcerts/cert.pem crypto-config-v1/peerOrganizations/'+domain+'/users/admin/msp/signcerts/cert.pem;'
        '')
    all_command += peer_cmd

    # Exec command
    exec_command = [
        '/bin/bash',
        '-c',
        '%s'  % (all_command)]

    result_get_folder = settings.k8s.exec_pod(
        podName=pods[0], namespace="default", command=exec_command)
    hiss.sub_echo(result_get_folder.data)
    return True


@click.command('updatefolder', short_help="Update folder crypto-config-v1 in EFS")
def updatefolder():
    update_folder()
