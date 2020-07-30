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


@click.group(invoke_without_command=True)
@click.option('-config', default=expanduser('~/.akachain/akc-mamba/mamba/config/.env'))
@click.option('--set-default/--no-default', default=False)

def mamba(config, set_default):
    # Setup all shared global utilities in settings module
    settings.init(config, set_default)
    if mamba.invoke_without_command:
       hiss.rattle('Initialize mamba')
       hiss.echo('Successfully with \'%s\' on the %s!' % (config, settings.EKS_CLUSTER_NAME))

mamba.add_command(environment)
mamba.add_command(vpn)
mamba.add_command(copyscripts)
mamba.add_command(reg_orgs)
mamba.add_command(reg_orderers)
mamba.add_command(reg_peers)
mamba.add_command(enroll_orderers)
mamba.add_command(enroll_peers)
mamba.add_command(rca)
mamba.add_command(ica)
mamba.add_command(zookeeper)
mamba.add_command(kafka)
mamba.add_command(orderer)
mamba.add_command(updatefolder)
mamba.add_command(peer)
mamba.add_command(gen_artifact)
mamba.add_command(channel_artifact)
mamba.add_command(admin)
mamba.add_command(secret)
mamba.add_command(bootstrap)
mamba.add_command(start)
mamba.add_command(delete)
mamba.add_command(terminate)
mamba.add_command(explorer)
mamba.add_command(prometheus)
mamba.add_command(grafana)
mamba.add_command(create_org)
mamba.add_command(channel_config)

if __name__ == '__main__':
    mamba()