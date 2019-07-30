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

      buildCommand = 'docker build --file {dockerFile} --target {target} -t $EXPECTED_REF'.format(
        dockerFile='{}/{}'.format(hostPath, dockerFile),
        target=target,
      )

      preBuildCommand = ''
      postBuildCommand = ''

      fallback_commands.append(fall_back_on([
        '{}/{}'.format(hostPath, dockerFile),
      ]))

      # Sync the host path changes to the container path
      sync_commands.append(sync(hostPath, containerPath))

      if service == 'blip':
        # Persist the yarn cache from builds to allow subsequent builds to be faster
        # preBuildCommand += """
        #   CACHE_UPDATE_REQUIRED=false
        #   if [ ! -f {hostPath}/packageMountDeps/.yarn-cache.tgz ]; then
        #     echo "Init empty .yarn-cache.tgz"
        #     tar -cvzf {hostPath}/packageMountDeps/.yarn-cache.tgz --files-from /dev/null
        #     CACHE_UPDATE_REQUIRED=true
        #   fi
        # """.format(
        #   hostPath=hostPath,
        # )

        # postBuildCommand += """
        #   if [ "$CACHE_UPDATE_REQUIRED" == 'true' ]; then
        #     echo "Saving Yarn cache"
        #     docker run --rm --entrypoint tar $EXPECTED_REF czf - /home/node/.cache/yarn/ > {hostPath}/packageMountDeps/.yarn-cache.tgz
        #   fi
        # """.format(
        #   hostPath=hostPath,
        # )

        # Run yarn install in container whenever yarn.lock changes on host
        run_commands.append(run(
          'cd {} && yarn install'.format(containerPath),
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
              'cd /app/packageMounts/{} && yarn install'.format(packageName),
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
      if overrides.get('rebuildCommand'):
        run_commands.append(run(overrides.get('rebuildCommand')))

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

### Blip Overrides Start ###
def applyBlipOverrides(overrides):
  mounts = overrides.get('linkedPackages')
  buildTarget = overrides.get('buildTarget', 'development')

  if type(mounts) == 'list':
    custom_build_args = {
      'deps': [],
      'disable_push': True, # No need to push in default docker-for-desktop k8s env
    }

    fallback_commands = []
    sync_commands = []
    run_commands = []

    for mount in mounts:
      hostPath = mount.get('hostPath')
      custom_build_args['deps'].append(hostPath)
      port_forwards += mount.get('portForwards', []);

      if mount.get('primary'):
        custom_build_args['command'] = """
          CACHE_UPDATE_REQUIRED=false

          if [ ! -f {hostPath}/packageMountDeps/.yarn-cache.tgz ]; then
            echo "Init empty .yarn-cache.tgz"
            tar -cvzf {hostPath}/packageMountDeps/.yarn-cache.tgz --files-from /dev/null
            CACHE_UPDATE_REQUIRED=true
          fi

          docker build --target {target} -t $EXPECTED_REF {hostPath};

          docker run --rm --entrypoint cat $EXPECTED_REF /app/yarn.lock > /tmp/yarn.lock

          if ! diff -q {hostPath}/yarn.lock /tmp/yarn.lock > /dev/null 2>&1; then
            echo "Saving yarn.lock"
            cp /tmp/yarn.lock {hostPath}/yarn.lock
            CACHE_UPDATE_REQUIRED=true
          fi;
        """.format(
          target=buildTarget,
          hostPath=hostPath,
        )

        custom_build_args['primaryHostPath'] = hostPath

        image = overrides.get('image', 'tidepool/blip:develop')
        custom_build_args['image'] = image

        fallback_commands.append(fall_back_on([
          '{}/Dockerfile'.format(hostPath),
        ]))

        sync_commands.append(sync(hostPath, '/app'))

        # Run yarn install on app directory when it's package.json changes
        run_commands.append(run(
          'cd /app && yarn install --silent',
          trigger='{}/yarn.lock'.format(hostPath),
        ))

      else:
        package_name = mount.get('packageName');

        if mount.get('mounted'):
          print('Linking package: {}'.format(package_name))

          yarn_cache_update_required = yarn_cache_update_required or bool(int(str(local('if [ ! -f {path}/packageMountDeps/{pkg}/yarn.lock ]; then printf 1; else printf 0; fi'.format(
            path=custom_build_args.get('primaryHostPath'),
            pkg=package_name,
          )))))

          custom_build_args['command'] += """
            if [ -f {hostPath}/yarn.lock ]; then
              docker run --rm --entrypoint cat $EXPECTED_REF /app/packageMounts/{pkg}/yarn.lock > /tmp/yarn.lock

              if ! diff -q {hostPath}/yarn.lock /tmp/yarn.lock > /dev/null 2>&1; then
                echo "Saving yarn.lock for {pkg}"
                cp /tmp/yarn.lock {hostPath}/yarn.lock
                CACHE_UPDATE_REQUIRED=true
              fi;
            fi;
          """.format(
            hostPath=hostPath,
            pkg=package_name,
          )

          local('cd {path} && mkdir -p packageMounts/{pkg} && rsync -a --delete --exclude "node_modules" --exclude ".git" --exclude "dist" --exclude "coverage" {hostPath}/ {path}/packageMounts/{pkg}'.format(
            path=custom_build_args.get('primaryHostPath'),
            hostPath=hostPath,
            pkg=package_name,
          ))

          local('cd {path} && mkdir -p packageMountDeps/{pkg} && rsync -a --delete {hostPath}/package.json {path}/packageMountDeps/{pkg}/'.format(
            path=custom_build_args.get('primaryHostPath'),
            hostPath=hostPath,
            pkg=package_name,
          ))

          local('if [ -f {hostPath}/yarn.lock ]; then cd {path} && mkdir -p packageMountDeps/{pkg} && rsync -a --delete {hostPath}/yarn.lock {path}/packageMountDeps/{pkg}/; fi'.format(
            path=custom_build_args.get('primaryHostPath'),
            hostPath=hostPath,
            pkg=package_name,
          ))

          sync_commands.append(sync(hostPath, '/app/packageMounts/{}'.format(package_name)))

          # Run yarn install in linked package directory when it's yarn.lock changes
          run_commands.append(run(
            'cd /app/packageMounts/{} && yarn install --silent'.format(package_name),
            trigger='{}/yarn.lock'.format(hostPath),
          ))

        else:
          print('Unmounting package: {}'.format(package_name))

          yarn_cache_update_required = yarn_cache_update_required or bool(int(str(local('if [ ! f {path}/packageMountDeps/{pkg}/yarn.lock ]; then printf 1; else printf 0; fi'.format(
            path=custom_build_args.get('primaryHostPath'),
            pkg=package_name,
          )))))

          local('cd {path} && rm -rf packageMounts/{pkg} && rm -rf packageMountDeps/{pkg}/package.json && rm -rf packageMountDeps/{pkg}/yarn.lock'.format(
            path=custom_build_args.get('primaryHostPath'),
            hostPath=hostPath,
            pkg=package_name,
          ))

    live_update_commands = fallback_commands + sync_commands + run_commands;

    if custom_build_args.get('command'):
      if yarn_cache_update_required:
        custom_build_args['command'] += """
          echo "Saving Yarn cache"
          docker run --rm --entrypoint tar $EXPECTED_REF czf - /home/node/.cache/yarn/ > {path}/packageMountDeps/.yarn-cache.tgz
        """.format(
          path=custom_build_args.get('primaryHostPath'),
        )
      else:
        custom_build_args['command'] += """
          if [ "$CACHE_UPDATE_REQUIRED" == 'true' ]; then
            echo "Saving Yarn cache"
            docker run --rm --entrypoint tar $EXPECTED_REF czf - /home/node/.cache/yarn/ > {path}/packageMountDeps/.yarn-cache.tgz
          fi;
        """.format(
          path=custom_build_args.get('primaryHostPath'),
        )

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
### Blip Overrides End ###

# Unleash the beast
main()
