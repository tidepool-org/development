### Helpers Start ###
def absolute_dir(relative_dir):
  return str(local('mkdir -p {dir} && cd {dir} && pwd'.format(dir=relative_dir))).strip()

def getNested(dict, path, fallback=None):
  value = dict
  for path_segment in path.split('.'):
    value = value.get(path_segment, {})
  return value or fallback
### Helpers End ###

### Global Start ###
config = read_yaml('./Tiltconfig.yaml')
configOverrides = read_yaml('./local/Tiltconfig.yaml', False)

if type(configOverrides) == 'dict':
  config.update(configOverrides.items())

tidepool_helm_charts_version = config.get('tidepool_helm_charts_version')
tidepool_helm_chart_dir = "./charts/tidepool/{}".format(tidepool_helm_charts_version)
mongo_helm_chart_dir = "./charts/mongo"

is_shutdown = bool(int(str(local('printf ${SHUTTING_DOWN-0}'))))

### Global End ###

### Main Start ###
def main():
  # Set up tidepool helm template command
  tidepool_helm_template_cmd = 'helm template --name tidepool-tilt --namespace default '

  if not is_shutdown:
    # Fetch and/or apply generated secrets on startup
    tidepool_helm_template_cmd = setServerSecrets(tidepool_helm_template_cmd)

  # Define local mongodb service
  defineMongoService()

  # Apply any service overrides
  tidepool_helm_overrides_file = './Tiltconfig.yaml'
  watch_file(tidepool_helm_overrides_file)
  if read_file('./local/Tiltconfig.yaml'):
    tidepool_helm_overrides_file = './local/Tiltconfig.yaml'
    watch_file(tidepool_helm_overrides_file)

  tidepool_helm_template_cmd += '-f {} '.format(tidepool_helm_overrides_file)

  tidepool_helm_template_cmd = applyServiceOverrides(tidepool_helm_template_cmd)

  # Expose the gateway proxy on a host port
  gateway_port_forwards = getNested(config,'gateway-proxy.portForwards', ['3000:8080'])
  k8s_resource('gateway-proxy', port_forwards=gateway_port_forwards)

  # Deploy and watch the helm charts
  k8s_yaml(local('{helmCmd} {chartDir}'.format(
    chartDir=tidepool_helm_chart_dir,
    helmCmd=tidepool_helm_template_cmd
  )))
  watch_file(tidepool_helm_chart_dir)

  # Back out of actual provisioning for debugging purposes by uncommenting below
  # fail('NOT YET ;)')
### Main End ###

### Secrets Start ###
def setServerSecrets (tidepool_helm_template_cmd):
  required_secrets = [
    'auth',
    'blob',
    'data',
    'export',
    'gatekeeper',
    'highwater',
    'image',
    'jellyfish',
    'notification',
    'shoreline',
    'task',
    'tidepool-server-secret',
    'user',
  ]

  server_secrets_dir = getNested(config, 'global.secrets.hostPath', './local/secrets')

  # Ensure secrets directory exists
  local('mkdir -p {}'.format(server_secrets_dir))

  # Skip secrets already available on cluster
  existing_secrets = str(local("kubectl get secrets -o=jsonpath='{.items[?(@.type==\"Opaque\")].metadata.name}'")).split()
  for existing_secret in existing_secrets:
    if required_secrets.index(existing_secret) >= 0:
      required_secrets.remove(existing_secret)

  for secret in required_secrets:
    secret_file_name = '{}.yaml'.format(secret)
    secret_file_path = '{}/{}'.format(server_secrets_dir, secret_file_name)

    if read_file(secret_file_path):
      # If we already have the secret saved, apply it to the cluster
      print('Loading existing secret for {}'.format(secret))
      local('kubectl --namespace default apply --validate=0 --force -f {}'.format(secret_file_path))

    else:
      # Generate the secret and apply it to the cluster
      local('helm template -x {chartDir}/templates/{secret}-secret.yaml {chartDir} | kubectl --namespace default apply --validate=0 --force -f -'.format(
        chartDir=tidepool_helm_chart_dir,
        secret=secret,
      ))

      # Save the generated secret to our local secrets directory
      local('kubectl get secrets {secret} -o yaml > {secret_file_path}'.format(
        secret_file_path=secret_file_path,
        secret=secret,
      ))

  # Ensure that we don't recreate the secrets when provisioning
  tidepool_helm_template_cmd += '--set "global.secrets.internal.source=other" '
  return tidepool_helm_template_cmd
### Secrets End ###

### MongoDB Start ###
def defineMongoService ():
  mongo_helm_template_cmd = 'helm template --name tidepool-local-db --namespace default '

  mongodb_data_dir = getNested(config, 'mongodb.hostPath')
  if mongodb_data_dir:
    mongo_helm_template_cmd += '--set "mongo.hostPath={}" '.format(mongodb_data_dir)

  k8s_yaml(local(mongo_helm_template_cmd + mongo_helm_chart_dir))
  k8s_resource('mongodb', port_forwards=[27017])
  watch_file(mongo_helm_chart_dir)
### MongoDB End ###

### Service Overrides Start ###
def applyServiceOverrides(tidepool_helm_template_cmd):
  for service, overrides in config.items():
    if type(overrides) == 'dict' and overrides.get('hostPath') and overrides.get('image') and overrides.get('enabled', True):
      hostPath = absolute_dir(overrides.get('hostPath'))
      containerPath = overrides.get('containerPath')
      dockerFile = overrides.get('dockerFile', 'Dockerfile')
      target = overrides.get('buildTarget', 'development')

      fallback_commands = []
      sync_commands = []
      run_commands = []
      build_deps = [hostPath]

      buildCommand = 'docker build --file {dockerFile} -t $EXPECTED_REF'.format(
        dockerFile='{}/{}'.format(hostPath, dockerFile),
        target=target,
      )

      if target:
        buildCommand += ' --target {}'.format(target)

      preBuildCommand = ''
      postBuildCommand = ''

      fallback_commands.append(fall_back_on([
        '{}/{}'.format(hostPath, dockerFile),
      ]))

      # Sync the host path changes to the container path
      sync_commands.append(sync(hostPath, containerPath))

      if service == 'blip':
        # Run yarn install in container whenever yarn.lock changes on host
        run_commands.append(run(
          'cd {} && yarn install --silent'.format(containerPath),
          trigger='{}/yarn.lock'.format(hostPath),
        ))

        activeLinkedPackages = []

        for package in overrides.get('linkedPackages'):
          packageName = package.get('packageName')
          packageHostPath = absolute_dir(package.get('hostPath'))
          build_deps.append(packageHostPath)

          if package['enabled']:
            if package.get('name') == 'viz':
              tidepool_helm_template_cmd += '--set "blip.command=[yarn]" --set "blip.args=[startWithViz]" '

            activeLinkedPackages.append(packageName)
            sync_commands.append(sync(packageHostPath, '/app/packageMounts/{}'.format(packageName)))

            # Run yarn install in linked package directory when it's yarn.lock changes
            run_commands.append(run(
              'cd /app/packageMounts/{} && yarn install --silent'.format(packageName),
              trigger='{}/yarn.lock'.format(packageHostPath),
            ))

            if not is_shutdown:
              # Copy the package source into the Dockerfile build context
              local('cd {hostPath} && mkdir -p packageMounts/{packageName} && rsync -a --delete --exclude "node_modules" --exclude ".git" --exclude "dist" --exclude "coverage" {packageHostPath}/ {hostPath}/packageMounts/{packageName}'.format(
                hostPath=hostPath,
                packageHostPath=packageHostPath,
                packageName=packageName,
              ))

              # Copy package.json and yarn.lock files to the Dockerfile build context
              local('cd {hostPath} && mkdir -p packageMountDeps/{packageName} && rsync -a --delete {packageHostPath}/package.json {hostPath}/packageMountDeps/{packageName}/'.format(
                hostPath=hostPath,
                packageHostPath=packageHostPath,
                packageName=packageName,
              ))

              local('if [ -f {packageHostPath}/yarn.lock ]; then cd {hostPath} && mkdir -p packageMountDeps/{packageName} && rsync -a --delete {packageHostPath}/yarn.lock {hostPath}/packageMountDeps/{packageName}/; fi'.format(
                hostPath=hostPath,
                packageHostPath=packageHostPath,
                packageName=packageName,
              ))
          else:
            if not is_shutdown:
              # Remove the package source from the Dockerfile build context
              local('cd {hostPath} && rm -rf packageMounts/{packageName} && rm -rf packageMountDeps/{packageName}/package.json && rm -rf packageMountDeps/{packageName}/yarn.lock'.format(
                hostPath=hostPath,
                packageName=packageName,
              ))

        buildCommand += ' --build-arg LINKED_PKGS={}'.format(','.join(activeLinkedPackages))

      buildCommand += ' {}'.format(hostPath)

      # Apply any rebuild commands specified
      if overrides.get('restartCommand'):
        run_commands.append(run(overrides.get('restartCommand')))

      live_update_commands = fallback_commands + sync_commands + run_commands;

      custom_build(
        ref=overrides.get('image'),
        command='{} {} {}'.format(preBuildCommand, buildCommand, postBuildCommand),
        deps=build_deps,
        disable_push=True,
        tag='tilt',
        live_update=live_update_commands
      )

  return tidepool_helm_template_cmd
### Service Overrides End ###

# Unleash the beast
main()
