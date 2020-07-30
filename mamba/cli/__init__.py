import click
from settings import settings
from os.path import expanduser

from utils import hiss

from k8s.vpn.commands import vpn
from k8s.secret.commands import secret
from k8s.environment.commands import environment

from blockchain.copyscripts.commands import copyscripts
from blockchain.reg_orgs.commands import reg_orgs
from blockchain.reg_orderers.commands import reg_orderers
from blockchain.reg_peers.commands import reg_peers
from blockchain.enroll_orderers.commands import enroll_orderers
from blockchain.enroll_peers.commands import enroll_peers
from blockchain.rca.commands import rca
from blockchain.ica.commands import ica
from blockchain.zookeeper.commands import zookeeper
from blockchain.kafka.commands import kafka
from blockchain.orderer.commands import orderer
from blockchain.update_folder.commands import updatefolder
from blockchain.channel_artifact.commands import channel_artifact
from blockchain.peer.commands import peer
from blockchain.gen_artifact.commands import gen_artifact
from blockchain.admin.commands import admin
from blockchain.bootstrap_network.commands import bootstrap
from blockchain.start_network.commands import start
from blockchain.delete_network.commands import delete
from blockchain.terminate_network.commands import terminate

from blockchain.explorer.commands import explorer
from blockchain.prometheus.commands import prometheus
from blockchain.grafana.commands import grafana

from blockchain.create_org.commands import create_org
from blockchain.update_channel_config.commands import channel_config

