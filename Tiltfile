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
tidepool_helm_overrides_file = './Tiltconfig.yaml'
config = read_yaml(tidepool_helm_overrides_file)
configOverrides = read_yaml('./local/Tiltconfig.yaml', False)

watch_file(tidepool_helm_overrides_file)

if type(configOverrides) == 'dict':
  config.update(configOverrides.items())
  tidepool_helm_overrides_file = './local/Tiltconfig.yaml'
  watch_file(tidepool_helm_overrides_file)

tidepool_helm_charts_version = config.get('tidepool_helm_charts_version')
tidepool_helm_chart_dir = "./charts/tidepool/{}".format(tidepool_helm_charts_version)
mongo_helm_chart_dir = "./charts/mongo"

is_shutdown = bool(int(str(local('printf ${SHUTTING_DOWN-0}'))))
### Global End ###

### Main Start ###
def main():
  # Set up tidepool helm template command
  tidepool_helm_template_cmd = 'helm template --is-upgrade --name tidepool-tilt --namespace default '

  gateway_port_forwards = getNested(config,'gateway-proxy.portForwards', ['3000'])
  gateway_port_forward_host_port = gateway_port_forwards[0].split(':')[0]

  mongodb_port_forwards = getNested(config,'mongodb.portForwards', ['27017'])
  mongodb_port_forward_host_port = mongodb_port_forwards[0].split(':')[0]

  if not is_shutdown:
    prepareServer()

    # Ensure mongodb service is deployed
    if not getNested(config, 'mongodb.useExternal'):
      mongodb_service = local('kubectl get service mongodb --ignore-not-found')
      if not mongodb_service:
        local('tilt up --file=Tiltfile.mongodb --hud=0 --port=0 &>/dev/null &')

    # Ensure proxy services are deployed
    gateway_proxy_service = local('kubectl get service gateway-proxy --ignore-not-found')
    if not gateway_proxy_service:
      local('tilt up --file=Tiltfile.proxy --hud=0 --port=0 &>/dev/null &')

    # Wait until mongodb and gateway-proxy services are forwarding before provisioning rest of stack
    if not getNested(config, 'mongodb.useExternal'):
      local('while ! nc -G 1 -z localhost {}; do sleep 1; done'.format(mongodb_port_forward_host_port))
    local('while ! nc -G 1 -z localhost {}; do sleep 1; done'.format(gateway_port_forward_host_port))

    # Generate and/or apply server secrets on startup
    tidepool_helm_template_cmd = setServerSecrets(tidepool_helm_template_cmd)
  else:
    # Shut down the mongodb and proxy services
    if not getNested(config, 'mongodb.useExternal'):
      local('tilt down --file=Tiltfile.mongodb &>/dev/null &')
    local('tilt down --file=Tiltfile.proxy &>/dev/null &')

    # Clean up any tilt up backround processes
    local("for pid in $(ps -ef | awk '/tilt\ up/ {print $2}'); do kill -9 $pid; done")

  # Apply any service overrides
  tidepool_helm_template_cmd += '-f {} '.format(tidepool_helm_overrides_file)
  tidepool_helm_template_cmd = applyServiceOverrides(tidepool_helm_template_cmd)

  # Don't provision the gloo gateway here - we do that in Tiltfile.proxy
  tidepool_helm_template_cmd += '--set "gloo.enabled=false" --set "gloo.created=true" '

  # Deploy and watch the helm charts
  k8s_yaml(local('{helmCmd} {chartDir}'.format(
    chartDir=tidepool_helm_chart_dir,
    helmCmd=tidepool_helm_template_cmd
  )))
  watch_file(tidepool_helm_chart_dir)

  # Back out of actual provisioning for debugging purposes by uncommenting below
  # fail('NOT YET ;)')
### Main End ###

### Prepare Server Start ###
def prepareServer():
  # Ensure default-admin clusterrolebinding on default:default service account
  default_admin_clusterrolebinding = local('kubectl get clusterrolebinding default-admin --ignore-not-found')
  if not default_admin_clusterrolebinding:
    local('kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default')
### Prepare Server End ###

### Secrets Start ###
def setServerSecrets (tidepool_helm_template_cmd):
  required_secrets = [
    'auth',
    'blob',
    'data',
    'dexcom-api',
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
      local('kubectl --namespace=default apply --validate=0 --force -f {}'.format(secret_file_path))

    else:
      # Generate the secret and apply it to the cluster
      local('helm template --is-upgrade -x {chartDir}/templates/{secret}-secret.yaml -f {overrides} {chartDir} | kubectl --namespace=default apply --validate=0 --force -f -'.format(
        chartDir=absolute_dir(tidepool_helm_chart_dir),
        overrides=tidepool_helm_overrides_file,
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

      # Force rebuild when Dockerfile changes
      fallback_commands.append(fall_back_on([
        '{}/{}'.format(hostPath, dockerFile),
      ]))

      # Sync the host path changes to the container path
      sync_commands.append(sync(hostPath, containerPath))

      if service == 'blip':
        # Force rebuild when webpack config changes
        fallback_commands.append(fall_back_on([
          '{}/{}'.format(hostPath, 'webpack.config.js'),
        ]))

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

              # Force rebuild when webpack config changes
              fallback_commands.append(fall_back_on([
                '{}/{}'.format(packageHostPath, 'webpack.config.js'),
                '{}/{}'.format(packageHostPath, 'package.config.js'),
              ]))

            activeLinkedPackages.append(packageName)
            sync_commands.append(sync(packageHostPath, '/app/packageMounts/{}'.format(packageName)))

            # Run yarn install in linked package directory when it's yarn.lock changes
            run_commands.append(run(
              'cd /app/packageMounts/{} && yarn install --silent'.format(packageName),
              trigger='{}/yarn.lock'.format(packageHostPath),
            ))

            if not is_shutdown:
              # Copy the package source into the Dockerfile build context
              preBuildCommand += 'cd {hostPath} && mkdir -p packageMounts/{packageName} && rsync -a --delete --exclude "node_modules" --exclude ".git" --exclude "dist" --exclude "coverage" {packageHostPath}/ {hostPath}/packageMounts/{packageName};'.format(
                hostPath=hostPath,
                packageHostPath=packageHostPath,
                packageName=packageName,
              )

          else:
            if not is_shutdown:
              # Remove the package source from the Dockerfile build context
              preBuildCommand += 'cd {hostPath} && rm -rf packageMounts/{packageName};'.format(
                hostPath=hostPath,
                packageName=packageName,
              );

        buildCommand += ' --build-arg LINKED_PKGS={}'.format(','.join(activeLinkedPackages))

      buildCommand += ' {}'.format(hostPath)

      # Apply any rebuild commands specified
      if overrides.get('rebuildCommand'):
        run_commands.append(run(overrides.get('rebuildCommand')))

      # Apply any rebuild commands specified
      if overrides.get('restartContainer', True):
        run_commands.append(restart_container())

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
