Local git ignored directory for storing k8s secrets, local mongo data, overriding tilt config and helm charts, etc.

# Private Docker Hub Repositories

To allow Tilt to pull images from a private Docker Hub repository it is necessary to specify Docker Hub credentials in 
each Deployment chart that uses a private repository.

## Enable Registry Secret

To maintain the Docker Hub credentials used to authenticate with Docker Hub, the `registry` Secret must be enabled and
the username and password specified. To do so, add the following to your `local/Tiltconfig.yaml`:

```
registry:
  secret:
    enabled: true
    username: <username>
    password: <personal-access-token>
```

Replace `<username>` with your Docker Hub username. Replace `<personal-access-token>` with a Personal Access Token from
Docker Hub. Docker Hub Personal Access Tokens can be created and managed at https://app.docker.com/settings/personal-access-tokens.

## Add Image Pull Secrets

To use the `registry` Secret containing the Docker Hub credentials the `imagePullSecrets` property must be specified
in each Deployment that uses a private Docker Hub repository.

This can be accomplished either globally (for all Deployments that require such) or per Deployment.

### Globally

Add the following to your `local/Tiltconfig.yaml`:

```
global:
  deployment:
    imagePullSecrets:
    - name: registry
```

This will add the image pull secret to every Deployment that currently requires access to a private Docker Hub repository. This is the recommended method.

### Per Deployment

Add the following to your `local/Tiltconfig.yaml`:

```
<deployment>:
  deployment:
    imagePullSecrets:
    - name: registry
```

Replace `<deployment>` with the name of the Deployment requiring the image pull secrets. For example:

```
prescription:
  deployment:
    imagePullSecrets:
    - name: registry
```

# OAuth Provider Configuration (Abbott/Dexcom)

To allow Tilt to use the Abbott and Dexcom OAuth providers it is necessary to enable the related Secret and
ConfigMap. To do so, add the following to your `local/Tiltconfig.yaml`, once for each provider you wish to enable:

```
<provider>:
  configmap:
    enabled: true
    redirectURL: "http://localhost:31500/v1/oauth/dexcom/redirect"
    tokenURL: "<provider-token-url>"
    authorizeURL: "<provider-authorize-url>"
    clientURL: "<provider-client-url>"
    scopes: "<provider-scopes>"
  secret:
    enabled: true
    data_:
      ClientId: "<provider-client-id>"
      ClientSecret: "<provider-client-secret>"
      StateSalt: "<provider-state-salt>"
```

The top-level `<provider>` should be replaced with `dexcom` or `abbott`, as appropriate. The other property values should
be changed to use the provider-specific settings. Multiple providers may be specified, if so desired.

## Provider-Specific Settings

Provider specific settings may be found in 1Password. Attached to the 1Password item are YAML configuration files for each environment. See below for provider-specific instructions. 

## Dexcom

Dexcom settings can be found attached to the `Dexcom Developer` item in the `Engineering` vault in 1Password. 

Use either:
- `sandbox.yaml` for connecting to the Dexcom Sandbox environment using the `tidepool-local` Dexcom client, or,
- `local.yaml` for connecting to the Dexcom Production environment using the `tidepool-dev` Dexcom client. 

**Do NOT use any other configuration file as that may cause conflict with the environment.**

## Abbott

Abbott settings can be found attached to the `Abbott Developer` item in the `Engineering` vault in 1Password.

Use the `local.yaml` for connecting to the Abbott Sandbox environment.
