### Helpers Start ###
def absolute_dir(relative_dir):
  # Get absolute path in order to use as volume mount
    return str(local('mkdir -p {dir} && cd {dir} && pwd'.format(dir=relative_dir))).strip()
### Helpers End ###

### Config Start ###
config = read_yaml('./Tiltconfig.yaml')
configOverrides = read_yaml('./local/Tiltconfig.yaml', False)

if type(configOverrides) == 'dict':
  config.update(configOverrides.items())

tidepool_repos_root_dir = absolute_dir(config.get('tidepool_repos_root_dir'))
development_dir = absolute_dir(config.get('development_dir'))
mongodb_data_dir = absolute_dir(config.get('mongodb_data_dir'))
server_secrets_dir = absolute_dir(config.get('server_secrets_dir'))
tidepool_helm_overrides_file = config.get('tidepool_helm_overrides_file')
k8s_environment = config.get('k8s_environment')
k8s_cluster_name = config.get('k8s_cluster_name')
tidepool_helm_version = config.get('tidepool_helm_version')

tidepool_helm_chart_dir = "{}/charts/tidepool/{}".format(development_dir, tidepool_helm_version)
mongo_helm_chart_dir = "{}/charts/mongo".format(development_dir)
### Config End ###

### Main Start ###
def main():
  if development_dir:

    # Prepare the k8s cluster
    prepare_k8s_cluster()

    # Set up tidepool helm template command
    tidepool_helm_template_cmd = 'helm template --name tidepool-tilt --namespace default '

    # Fetch and/or apply generated secrets
    tidepool_helm_template_cmd = getServerSecrets(tidepool_helm_template_cmd)

    # Create local mongodb service
    createMongoService()

    # Apply any service overrides
    overrides = {}
    if read_file(tidepool_helm_overrides_file):
      overrides = read_yaml(tidepool_helm_overrides_file)
      tidepool_helm_template_cmd += '-f {} '.format(tidepool_helm_overrides_file)
      watch_file(tidepool_helm_overrides_file)

      applyBlipOverrides(overrides.get('blip', False))

    # Expose the gateway proxy on a host port
    gateway_port_forwards = overrides.get('gateway-proxy', {}).get('portForwards', ['3000:8080'])
    k8s_resource('gateway-proxy', port_forwards=gateway_port_forwards)

    # Deploy and watch the helm charts
    k8s_yaml(local('{helmCmd} {chartDir}'.format(
      chartDir=tidepool_helm_chart_dir,
      helmCmd=tidepool_helm_template_cmd
    )))
    watch_file(tidepool_helm_chart_dir)

    # Back out of actual provisioning for debugging purposes by uncommenting below
    # fail('NOT YET ;)')
  else:
    fail('OOPS! You need to point "development_dir" to the root of local copy of the tidepool "development" repo in your Tiltfile')
### Main End ###

### Cluster Prep Start ###
def prepare_k8s_cluster ():
  for env in ['kind', 'k3d']:
    if env == k8s_environment:
      default_admin_clusterrolebinding = local('kubectl get clusterrolebinding default-admin --ignore-not-found')
      if not default_admin_clusterrolebinding:
        local('kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default')
      break
### Cluster Prep End ###

### Secrets Start ###
def getServerSecrets (tidepool_helm_template_cmd):
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
def createMongoService ():
  mongo_helm_template_cmd = 'helm template --name tidepool-local-db --namespace default '

  if mongodb_data_dir:
    # Ensure data directory exists
    local('mkdir -p {}'.format(mongodb_data_dir))
    mongo_helm_template_cmd += '--set "mongo.hostPath={}" '.format(mongodb_data_dir)

  k8s_yaml(local(mongo_helm_template_cmd + mongo_helm_chart_dir))
  k8s_resource('mongodb', port_forwards=[27017])
  watch_file(mongo_helm_chart_dir)
### MongoDB End ###

### Blip Overrides Start ###
def applyBlipOverrides (overrides):
  if overrides:
    mounts = overrides.get('mounts')
    buildTarget = overrides.get('buildTarget', 'develop')

    if type(mounts) == 'list':
      custom_build_args = {
        'deps': [],
        'disable_push': True, # No need to push in default docker-for-desktop k8s env
      }

      fallback_commands = []
      sync_commands = []
      run_commands = []
      port_forwards = []

      for mount in mounts:
        hostPath = mount.get('hostPath')
        custom_build_args['deps'].append(hostPath)
        port_forwards += mount.get('portForwards', []);

        if mount.get('primary'):
          custom_build_args['command'] = 'docker build --target {} -t $EXPECTED_REF {}; '.format(buildTarget, hostPath)

          if k8s_environment == 'kind':
            if k8s_cluster_name != 'kind':
              # Tilt has bug where it will not auto-deploy to kind if the cluster_name isn't `kind`, so we take care of that
              custom_build_args['command'] += ' kind load docker-image --nodes {cluster}-control-plane --name {cluster} $EXPECTED_REF '.format(cluster=k8s_cluster_name)
            else:
              # Allow Tilt to automatically sideload image with `kind load` internally
              custom_build_args['disable_push'] = False

          if k8s_environment == 'k3d':
            custom_build_args['disable_push'] = False
            # custom_build_args['command'] += ' k3d import-images -n {cluster} $EXPECTED_REF'.format(cluster=k8s_cluster_name)

          custom_build_args['primaryHostPath'] = hostPath

          image = overrides.get('image', 'tidepool/blip:develop')
          custom_build_args['image'] = image

          fallback_commands.append(fall_back_on([
            '{}/Dockerfile'.format(hostPath),
          ]))

          sync_commands.append(sync(hostPath, '/app'))

          # Run yarn install on app directory when it's package.json changes
          run_commands.append(run(
            'cd /app && yarn install',
            trigger='{}/yarn.lock'.format(hostPath),
          ))

        elif mount.get('mounted'):
          package_name = mount.get('packageName');
          print('Linking package: {}'.format(package_name))

          local('cd {path} && mkdir -p packageMounts/{pkg} && rsync -a --delete --exclude "node_modules" --exclude ".git" --exclude "dist" --exclude "coverage" {hostPath}/ {path}/packageMounts/{pkg}'.format(
            path=custom_build_args['primaryHostPath'],
            hostPath=hostPath,
            pkg=package_name,
          ))

          local('cd {path} && mkdir -p packageMountDeps/{pkg} && rsync -a --delete {hostPath}/package.json {path}/packageMountDeps/{pkg}/'.format(
            path=custom_build_args['primaryHostPath'],
            hostPath=hostPath,
            pkg=package_name,
          ))

          local('if [ -f {hostPath}/yarn.lock ]; then cd {path} && mkdir -p packageMountDeps/{pkg} && rsync -a --delete {hostPath}/yarn.lock {path}/packageMountDeps/{pkg}/; fi'.format(
            path=custom_build_args['primaryHostPath'],
            hostPath=hostPath,
            pkg=package_name,
          ))

          sync_commands.append(sync(hostPath, '/app/packageMounts/{}'.format(package_name)))

          # Run yarn install in linked package directory when it's package.json changes
          run_commands.append(run(
            'cd /app/packageMounts/{} && yarn install'.format(package_name),
            trigger='{}/yarn.lock'.format(hostPath),
          ))

          if mount.get('linked'):
            run_commands.append(run(
              'if [ ! -L /app/node_modules/{pkg} ]; then cd /app/packageMounts/{pkg} && yarn link && cd /app && yarn link {pkg}; else exit 0; fi'.format(
                pkg=package_name,
              ),
            ))
          else:
             run_commands.append(run(
            'if [ -L /app/node_modules/{pkg} ]; then yarn unlink {pkg} && cd /{pkg} && yarn unlink && cd /app && rm -f node_modules/{pkg} && yarn install --force; fi'.format(
                pkg=package_name,
              ),
            ))

        else:
          package_name = mount.get('packageName');
          print('Unmounting and unlinking package: {}'.format(package_name))

          local('cd {path} && rm -rf packageMounts/{pkg} && rm -rf packageMountDeps/{pkg}/package.json && rm -rf packageMountDeps/{pkg}/yarn.lock'.format(
            path=custom_build_args['primaryHostPath'],
            hostPath=hostPath,
            pkg=package_name,
          ))

          run_commands.append(run(
            'if [ -L /app/node_modules/{pkg} ]; then yarn unlink {pkg} && cd /{pkg} && yarn unlink && cd /app && rm -f node_modules/{pkg} && yarn install --force; else exit 0; fi'.format(
              pkg=package_name,
            ),
          ))

      live_update_commands = fallback_commands + sync_commands + run_commands;

      if custom_build_args.get('command'):
        print('Building custom blip image using base image: {}'.format(custom_build_args.get('image')))

        custom_build(
          ref=custom_build_args.get('image'),
          command=custom_build_args.get('command'),
          deps=custom_build_args.get('deps'),
          disable_push=custom_build_args.get('disable_push'),
          live_update=live_update_commands,
          ignore=['node_modules'],
          tag='tilt-blip',
        )

    for i in range(len(port_forwards)):
      port_forwards[i] = int(port_forwards[i])

    k8s_resource('blip', port_forwards=port_forwards, trigger_mode=TRIGGER_MODE_AUTO)
### Blip Overrides End ###

# Unleash the beast
main()
