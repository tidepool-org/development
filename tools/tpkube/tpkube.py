import json
import os

import click
import yaml

dir_path = os.path.dirname(os.path.realpath(__file__))

JSONNET="jsonnet"

__author__ = "Derrick Burns"

@click.group()
def main():
    """ A CLI for creating Tidepool Kubernetes clusters"""


@main.command() 
@click.option('--format', type=click.Choice(['json', 'yaml']), default='json', help='Output format')
def configfile_skeleton(format):
    """Create a skeleton configuration file."""
    input=os.path.realpath(dir_path + "/../../jsonnet/values.json")
    with open(input, 'r') as fin:
        if format == "json":
            click.echo(fin.read())
        elif format == "yaml":
            click.echo(yaml.dump(json.load(fin)))
        else:
            click.echo("unknown format: %s" % format)


@main.command()
@click.argument('configfile', type=click.File('r'), default = 'values.yaml', required=False)
@click.option('--directory', default="", type=click.Path(), help='Output directory, if none, then generate single file to stdout')
def resources_materialize(config, directory):
    """Materialize Kubernetes resource manifests to directory."""
    createEKSctlConfigFile(config, directory)
    createExternalSecrets(config, directory)
    createHorizontalPodAutoscalers(config, directory)
    pass

def createEKSctlConfigFile(config, directory):
    #jsonnet
    pass

def createExternalSecrets(config, directory):
    pass

def createHorizontalPodAutoscalers(config, directory):
    pass

def createTidepoolEnvironments(config, directory):
    pass

def createSharedGroups(config, directory):
    pass

@main.command()
@click.argument('configfile', type=click.File('r'), default = 'values.yaml', required=False)
def cluster_apply(configfile):
    """Apply the configuration to the cluster."""
    pass;

@main.command()
@click.argument('configfile', type=click.File('r'), default = 'values.yaml', required=False)
def secrets_push(config):
    """Push secrets to persistent store"""
    pass

@main.command()
@click.argument('configfile', type=click.File('r'), default = 'values.yaml', required=False)
@click.option('--environment', default='', help='environment name, empty string means all')
@click.option('--secret', default='', help='secret name, empty string means all')
@click.option('--type', default='manifest', help='Secrets manifests (manifest) or Values file (values)')
def secrets_pull(src, environment, secret, type):
    """Pull secrets from persistent store with given configfile."""
    pass

@main.command()
@click.argument('configfile', type=click.File('r'), default = 'values.yaml', required=False)
@click.option('--provider', type=click.Choice(['aws']), default='aws')
@click.option('--kubeconfig', default='~/.kube/kubeconfig.yaml')
def cluster_create(configfile, provider, kubeconfig):
    """Create a Kubernetes cluster with given configuration file"""
    pass

@main.command()
@click.argument('--kubectx', type=str, default='')
def cluster_destroy(kubectx):
    """Destroy a Kubernetes cluster with given kube context."""
    pass

if __name__ == "__main__":
    main()
