load('Tiltfile.global', 'getAbsoluteDir', 'getNested', 'getConfig', 'getHelmValuesFile', 'getHelmOverridesFile', 'isShutdown')

allow_k8s_contexts('kind-admin@mk')

### Config Start ###
tidepool_helm_values_file = getHelmValuesFile()
tidepool_helm_overrides_file = getHelmOverridesFile()
config = getConfig()

watch_file(tidepool_helm_values_file)
watch_file(tidepool_helm_overrides_file)

tidepool_helm_chart_dir = "./charts/tidepool"

is_shutdown = isShutdown()
### Config End ###

### Main Start ###
def main():

  # Set up tidepool helm template command
  tidepool_helm_template_cmd = 'helm template --namespace default '

  if not is_shutdown:
    updateHelmDependancies()
    provisionClusterRoleBindings()
    provisionServerSecrets()
    provisionConfigMaps()

    # Ensure kafka service is deployed
    kafka_service = local('kubectl get service kafka-kafka-bootstrap --ignore-not-found')
    if not kafka_service:
      local('tilt up --file=Tiltfile.kafka --legacy=0 --port=0 >/dev/null 2>&1 &')

    # Ensure proxy services are deployed
    gateway_proxy_service = local('kubectl get service gateway-proxy --ignore-not-found -n default')
    if not gateway_proxy_service:
      fail("Gateway service is missing. Please install gateway via glooctl")

    # Wait until kafka is ready and kafka secrets are created
    if not kafka_service:
      print("Preparing kafka service...")
      local('while [ -z "$(kubectl get secret kafka --ignore-not-found)" ]; do sleep 5; done')
      print("Kafka ready.")

  else:
    local('SHUTTING_DOWN=1 tilt down --file=Tiltfile.gateway &>/dev/null &')

    local('SHUTTING_DOWN=1 tilt down --file=Tiltfile.kafka &>/dev/null &')

    # Clean up any tilt up background processes
    local('for pid in $(ps -o pid,args | awk \'$2 ~ /tilt/ && $3 ~ /up/ {print $1}\'); do kill -9 $pid; done')

  # Apply any service overrides
  tidepool_helm_template_cmd += '-f {baseConfig} -f {overrides} '.format(
    baseConfig=tidepool_helm_values_file,
    overrides=tidepool_helm_overrides_file,
  )
  tidepool_helm_template_cmd = applyServiceOverrides(tidepool_helm_template_cmd)

  # Don't provision the gloo gateway here - we do that in Tiltfile.gateway
  tidepool_helm_template_cmd += '--set "gloo.enabled=false" --set "gloo.created=true" '

  # Set release name
  tidepool_helm_template_cmd += '--name-template "tp" '

  # Deploy and watch the helm charts
  k8s_yaml(
    [
      local('{helmCmd} {chartDir}'.format(
      chartDir=tidepool_helm_chart_dir,
      helmCmd=tidepool_helm_template_cmd)),
    ]
  )

  # To update on helm chart source changes, uncomment below
  # watch_file(tidepool_helm_chart_dir)

  # Back out of actual provisioning for debugging purposes by uncommenting below
  # fail('NOT YET ;)')
### Main End ###

### Helm Dependancies Update Start ###
def updateHelmDependancies():
  local('cd charts/tidepool && for dep in $(helm dep list | grep "file://" | cut -f 3 | sed s#file:/#.#); do helm dep update $dep; done')
  local('cd charts/tidepool && helm dep up')
### Helm Dependancies Update End ###

### Cluster Role Bindings Start ###
def provisionClusterRoleBindings():
  required_admin_clusterrolebindings = [
    'default',
  ]

  for serviceaccount in required_admin_clusterrolebindings:
    clusterrolebinding = local('kubectl get clusterrolebinding {serviceaccount}-admin --ignore-not-found'.format(
      serviceaccount = serviceaccount
    ))

    if not clusterrolebinding:
      local('kubectl create clusterrolebinding {serviceaccount}-admin --clusterrole cluster-admin --serviceaccount=default:{serviceaccount} --validate=0'.format(
        serviceaccount = serviceaccount
      ))
### Cluster Role Bindings End ###

### Secrets Start ###
def provisionServerSecrets ():
  required_secrets = [
    'auth',
    'blob',
    'data',
    'dexcom',
    'export',
    'kissmetrics',
    'marketo',
    'mongo',
    'prescription',
    'server',
    'shoreline',
    'task',
    'userdata',
  ]

  secretHelmKeyMap = {
    'kissmetrics': 'global.secret.templated',
  }

  secretChartPathMap = {
    'kissmetrics': 'highwater/charts/kissmetrics/templates/kissmetrics-secret.yaml',
  }

  # Skip secrets already available on cluster
  existing_secrets = str(local("kubectl get secrets -o=jsonpath='{.items[?(@.type==\"Opaque\")].metadata.name}'")).split()
  for existing_secret in existing_secrets:
    if existing_secret in required_secrets:
      required_secrets.remove(existing_secret)

  for secret in required_secrets:
    secretChartPath = secretChartPathMap.get(secret, '{secret}/templates/0-secret.yaml'.format(
      secret=secret,
    ))

    templatePath = 'charts/{secretChartPath}'.format(
      secretChartPath=secretChartPath,
    )

    secretKey = secretHelmKeyMap.get(secret, '{}.secret.enabled'.format(secret))

    # Generate the secret and apply it to the cluster
    local('helm template {chartDir} --namespace default --set "{secretKey}=true" -s {templatePath} -f {baseConfig} -f {overrides} -g | kubectl --namespace=default apply --validate=0 --force -f -'.format(
      chartDir=getAbsoluteDir(tidepool_helm_chart_dir),
      templatePath=templatePath,
      secretKey=secretKey,
      baseConfig=tidepool_helm_values_file,
      overrides=tidepool_helm_overrides_file,
    ))
### Secrets End ###

### Config Maps Start ###
def provisionConfigMaps ():
  required_configmaps = [
    'dexcom',
  ]

  if getNested(config, 'shoreline.configmap.enabled'):
    required_configmaps.append('shoreline')
  if getNested(config, 'clinic.configmap.enabled'):
    required_configmaps.append('clinic')
  if getNested(config, 'clinic-worker.configmap.enabled'):
    required_configmaps.append('clinic-worker')

  # Skip configmaps already available on cluster
  existing_configmaps = str(local("kubectl get --ignore-not-found configmaps -o=jsonpath='{.items[].metadata.name}'")).split()
  for existing_configmap in existing_configmaps:
    if ','.join(required_configmaps).find(existing_configmap) >= 0:
      required_configmaps.remove(existing_configmap)

  for configmap in required_configmaps:
    configmapChartPath = '{configmap}/templates/0-configmap.yaml'.format(
      configmap=configmap,
    )

    templatePath = 'charts/{configmapChartPath}'.format(
      configmapChartPath=configmapChartPath,
    )

    # Generate the configmap and apply it to the cluster
    local('helm template {chartDir} --namespace default -s {templatePath} -f {baseConfig} -f {overrides} -g | kubectl --namespace=default apply --validate=0 --force -f -'.format(
      chartDir=getAbsoluteDir(tidepool_helm_chart_dir),
      baseConfig=tidepool_helm_values_file,
      overrides=tidepool_helm_overrides_file,
      templatePath=templatePath
    ))
### Config Maps End ###

### Service Overrides Start ###
def applyServiceOverrides(tidepool_helm_template_cmd):
  for service, overrides in config.items():
    if type(overrides) == 'dict' and overrides.get('hostPath') and getNested(overrides, 'deployment.image'):
      hostPath = getAbsoluteDir(overrides.get('hostPath'))
      containerPath = overrides.get('containerPath')
      dockerFile = overrides.get('dockerFile', 'Dockerfile')
      target = overrides.get('buildTarget', 'development')

      fallback_commands = []
      sync_commands = []
      run_commands = []
      build_deps = [hostPath]

      buildCommand = 'DOCKER_BUILDKIT=1 docker build --file {dockerFile} -t $EXPECTED_REF'.format(
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

      # Run yarn install in container whenever yarn.lock changes on host
      run_commands.append(run(
        'cd {} && yarn install --silent --no-progress'.format(containerPath),
        trigger=[
          '{}/yarn.lock'.format(hostPath),
        ]
      ))

      # Sync the host path changes to the container path
      sync_commands.append(sync(hostPath, containerPath))

      if service == 'blip':
        # Force rebuild when webpack config changes
        fallback_commands.append(fall_back_on([
          '{}/{}'.format(hostPath, 'webpack.config.js'),
        ]))

        activeLinkedPackages = []

        # Blip builds use up available inodes in the file system very fast, so we remove any dangling
        # images or build cache artifacts after each build to help avoid a disk-pressure taint in Kubernetes.
        postBuildCommand = ' && {currentDir}/bin/tidepool server-docker images purge && {currentDir}/bin/tidepool server-docker builder prune -f'.format(
          currentDir=os.getcwd(),
        )

        for package in overrides.get('linkedPackages'):
          packageName = package.get('packageName')
          packageHostPath = getAbsoluteDir(package.get('hostPath'))
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
              'cd /app/packageMounts/{} && yarn install --silent --no-progress'.format(packageName),
              trigger=[
                '{}/yarn.lock'.format(packageHostPath),
              ]
            ))

            if not is_shutdown:
              # Copy the package source into the Dockerfile build context
              preBuildCommand += 'cd {hostPath} && mkdir -p packageMounts/{packageName} && rsync -a --delete --exclude "node_modules" --exclude "stub" --exclude ".git" --exclude "dist" --exclude "coverage" {packageHostPath}/ {hostPath}/packageMounts/{packageName};'.format(
                hostPath=hostPath,
                packageHostPath=packageHostPath,
                packageName=packageName,
              )

          else:
            if not is_shutdown:
              # Remove the package source from the Dockerfile build context
              preBuildCommand += 'cd {hostPath}/packageMounts/{packageName} && find . -type f -not -name \'stub\' -delete && find . -type d -empty -delete;'.format(
                hostPath=hostPath,
                packageName=packageName,
              )

        buildCommand += ' --build-arg LINKED_PKGS={linkedPackages} --build-arg ROLLBAR_POST_SERVER_TOKEN={rollbarPostServerToken} --build-arg LAUNCHDARKLY_CLIENT_TOKEN={launchDarklyClientToken} --build-arg REACT_APP_GAID={reactAppGAID} --build-arg PENDO_ENABLED={pendoEnabled} --build-arg I18N_ENABLED={i18nEnabled} --build-arg RX_ENABLED={rxEnabled}'.format(
          linkedPackages=','.join(activeLinkedPackages),
          rollbarPostServerToken=overrides.get('rollbarPostServerToken'),
          launchDarklyClientToken=overrides.get('launchDarklyClientToken'),
          reactAppGAID=overrides.get('reactAppGAID'),
          pendoEnabled=overrides.get('pendoEnabled'),
          i18nEnabled=overrides.get('i18nEnabled'),
          rxEnabled=overrides.get('rxEnabled'),
        )

      elif service == 'uploader':
        # Force rebuild when webpack config changes
        fallback_commands.append(fall_back_on([
          '{}/{}'.format(hostPath, 'webpack.config.web.dev.babel.js'),
        ]))

        buildCommand += ' --build-arg ROLLBAR_POST_SERVER_TOKEN={rollbarPostServerToken} --build-arg PENDO_ENABLED={pendoEnabled} --build-arg I18N_ENABLED={i18nEnabled} --build-arg RX_ENABLED={rxEnabled}'.format(
          rollbarPostServerToken=overrides.get('rollbarPostServerToken'),
          pendoEnabled=overrides.get('pendoEnabled'),
          i18nEnabled=overrides.get('i18nEnabled'),
          rxEnabled=overrides.get('rxEnabled'),
        )

      buildCommand += ' {}'.format(hostPath)

      # Apply any rebuild commands specified
      if overrides.get('rebuildCommand'):
        run_commands.append(run(overrides.get('rebuildCommand')))

      # Apply container process restart if specified
      entrypoint = overrides.get('restartContainerCommand', '');
      if overrides.get('restartContainerCommand'):
        run_commands.append(run('./tilt/restart.sh'))

      live_update_commands = fallback_commands + sync_commands + run_commands

      custom_build(
        ref=getNested(overrides, 'deployment.image'),
        entrypoint=entrypoint,
        command='{} {} {}'.format(preBuildCommand, buildCommand, postBuildCommand),
        deps=build_deps,
        disable_push=False,
        tag='tilt',
        live_update=live_update_commands
      )

  return tidepool_helm_template_cmd
### Service Overrides End ###

# Unleash the beast
main()
