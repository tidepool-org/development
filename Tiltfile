load('./Tiltfile.global', 'absolute_dir', 'getNested', 'tidepool_helm_overrides_file', 'config', 'tidepool_helm_charts_version', 'tidepool_helm_chart_dir', 'mongo_helm_chart_dir', 'is_shutdown')

### Main Start ###
def main():
  watch_file('./Tiltconfig.yaml')

  if read_file('./local/Tiltconfig.yaml'):
    watch_file('./local/Tiltconfig.yaml')

  # Set up tidepool helm template command
  tidepool_helm_template_cmd = 'helm template --name tidepool-tilt --namespace default '

  gateway_port_forwards = getNested(config,'gateway-proxy-v2.portForwards', ['3000'])
  gateway_port_forward_host_port = gateway_port_forwards[0].split(':')[0]

  mongodb_port_forwards = getNested(config,'mongodb.portForwards', ['27017'])
  mongodb_port_forward_host_port = mongodb_port_forwards[0].split(':')[0]

  if not is_shutdown:
    provisionGlooGatewayDependancies()
    provisionClusterRoleBindings()
    provisionGlooGateway()
    provisionServerSecrets()
    provisionConfigMaps()

  # Apply any service overrides
  tidepool_helm_template_cmd += '-f {} '.format(tidepool_helm_overrides_file)
  tidepool_helm_template_cmd = applyServiceOverrides(tidepool_helm_template_cmd)

  # Deploy and watch the helm charts
  k8s_yaml(local('{helmCmd} {chartDir}'.format(
    chartDir=tidepool_helm_chart_dir,
    helmCmd=tidepool_helm_template_cmd
  )))

  # Expose the gateway proxy on a host port
  gateway_port_forwards = getNested(config,'gateway-proxy-v2.portForwards', ['3000'])
  k8s_resource('gateway-proxy-v2', port_forwards=gateway_port_forwards)

  # Expose mongodb on a host port
  mongodb_port_forwards = getNested(config,'mongodb.portForwards', ['27017'])
  k8s_resource('mongodb', port_forwards=mongodb_port_forwards)

  watch_file(tidepool_helm_chart_dir)

  # Back out of actual provisioning for debugging purposes by uncommenting below
  # fail('NOT YET ;)')
### Main End ###


### Gloo Dependancies Start ###
def provisionGlooGatewayDependancies():
  gloo_helm_template_cmd = 'helm template --name tidepool-tilt --namespace default '

  for chart in listdir('{}/charts'.format(tidepool_helm_chart_dir)):
    if chart.find('gloo') >= 0:
      gloo_chart_dir = './local/charts'
      absolute_gloo_chart_dir = absolute_dir(gloo_chart_dir)
      local('mkdir -p {}'.format(absolute_gloo_chart_dir))
      local('tar -xzf {} -C {}'.format(chart, absolute_gloo_chart_dir));

      for template in listdir('{}/gloo/templates'.format(absolute_gloo_chart_dir)):
        if template.find('service-account') >= 0 or template.find('gateway-proxy-configmap') >= 0:
          k8s_yaml(local('{templateCmd} -x {template} -f {overridesFile} {chartDir}/gloo'.format(
            chartDir=absolute_gloo_chart_dir,
            templateCmd=gloo_helm_template_cmd,
            overridesFile=tidepool_helm_overrides_file,
            template=template,
          )))
### Gloo Dependancies End ###


### Cluster Role Bindings Start ###
def provisionClusterRoleBindings():
  required_admin_clusterrolebindings = [
    'default',
    'apiserver-ui',
    'discovery',
    'gateway',
    'gateway-proxy',
    'gloo',
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


### Gloo Gateway Start ###
def provisionGlooGateway():
  gloo_chart_dir = './local/charts'
  absolute_gloo_chart_dir = absolute_dir(gloo_chart_dir)

  for template in listdir('{}/gloo/templates'.format(absolute_gloo_chart_dir)):
    if template.find('service-account') >= 0 or template.find('gateway-proxy-configmap') >= 0:
      local('rm {}'.format(template))

  gloo_helm_template_cmd = 'helm template --name tidepool-tilt --namespace default '

  k8s_yaml(local('{templateCmd} -f {overridesFile} {chartDir}/gloo'.format(
    chartDir=absolute_gloo_chart_dir,
    templateCmd=gloo_helm_template_cmd,
    overridesFile=tidepool_helm_overrides_file,
  )))
### Gloo Gateway End ###

### Secrets Start ###
def provisionServerSecrets ():
  required_secrets = [
    'auth',
    'blob',
    'carelink',
    'data',
    'dexcom',
    'export',
    'image',
    'jellyfish',
    'kissmetrics',
    'mailchimp',
    'mongo',
    'notification',
    'server',
    'shoreline',
    'task',
    'user',
    'userdata',
  ]

  # Skip secrets already available on cluster
  existing_secrets = str(local("kubectl get secrets -o=jsonpath='{.items[?(@.type==\"Opaque\")].metadata.name}'")).split()
  for existing_secret in existing_secrets:
    if required_secrets.index(existing_secret) >= 0:
      required_secrets.remove(existing_secret)

  for secret in required_secrets:
    secretChartPathMap = {
      'jellyfish': 'carelink/templates/carelink-secret.yaml',
      'kissmetrics': 'highwater/charts/kissmetrics/templates/kissmetrics-secret.yaml',
      'mailchimp': 'shoreline/charts/mailchimp/templates/mailchimp-secret.yaml',
    }

    secretChartPath = secretChartPathMap.get(secret, '{secret}/templates/{secret}-secret.yaml'.format(
      secret=secret,
    ))

    templatePath = '{chartDir}/charts/{secretChartPath}'.format(
      chartDir=absolute_dir(tidepool_helm_chart_dir),
      secretChartPath=secretChartPath,
    )

    # Generate the secret and apply it to the cluster
    local('helm template --namespace default --set "global.secret.enabled=true" -x {templatePath} -f {overrides} {chartDir} | kubectl --namespace=default apply --validate=0 --force -f -'.format(
      chartDir=absolute_dir(tidepool_helm_chart_dir),
      overrides=tidepool_helm_overrides_file,
      templatePath=templatePath
    ))
### Secrets End ###


### Config Maps Start ###
def provisionConfigMaps ():
  required_configmaps = [
    'dexcom',
  ]

  if getNested(config, 'shoreline.configmap.enabled'):
    required_configmaps.append('shoreline')

  # Skip configmaps already available on cluster
  existing_configmaps = str(local("kubectl get --ignore-not-found configmaps -o=jsonpath='{.items[].metadata.name}'")).split()
  for existing_configmap in existing_configmaps:
    if ','.join(required_configmaps).find(existing_configmap) >= 0:
      required_configmaps.remove(existing_configmap)

  for configmap in required_configmaps:
    configmapChartPath = '{configmap}/templates/{configmap}-configmap.yaml'.format(
      configmap=configmap,
    )

    templatePath = '{chartDir}/charts/{configmapChartPath}'.format(
      chartDir=absolute_dir(tidepool_helm_chart_dir),
      configmapChartPath=configmapChartPath,
    )

    # Generate the configmap and apply it to the cluster
    local('helm template --namespace default -x {templatePath} -f {overrides} {chartDir} | kubectl --namespace=default apply --validate=0 --force -f -'.format(
      chartDir=absolute_dir(tidepool_helm_chart_dir),
      overrides=tidepool_helm_overrides_file,
      templatePath=templatePath
    ))
### Config Maps End ###


### Service Overrides Start ###
def applyServiceOverrides(tidepool_helm_template_cmd):
  for service, overrides in config.items():
    if type(overrides) == 'dict' and overrides.get('hostPath') and getNested(overrides, 'deployment.image'):
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

      # Run yarn install in container whenever yarn.lock changes on host
      run_commands.append(run(
        'cd {} && yarn install --silent'.format(containerPath),
        trigger=[
          '{}/yarn.lock'.format(hostPath),
          '{}/package-lock.json'.format(hostPath),
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
