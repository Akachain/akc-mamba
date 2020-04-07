import click

@click.group()
def vpn():
    pass

@vpn.command('init', short_help="Initialize vpn service")
def init():
    click.echo('Initialize vpn service')

@vpn.command('drop', short_help="Remove vpn service")
def drop():
    click.echo('Remove vpn service')