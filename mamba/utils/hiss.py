# A snake must know how hiss ... or sometimes rattle
# Normally we can just use echo to print out message during execution
# However:
    # It is mandatory to *hiss* when there is error
    # also, *rattle* is needed when a snake meet something ... at the beginning
    # or at the end of an execution.
import click

def echo(message):
    click.echo(message)

def sub_echo(message):
    click.echo('  ' + message)

def hiss(message):
    click.secho('Error: ' + message, fg='red')
    return False

def rattle(message):
    click.secho(message, blink=True, bold=True, fg='white', bg='blue')