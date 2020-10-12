# superset

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 1.0](https://img.shields.io/badge/AppVersion-1.0-informational?style=flat-square)

Apache Superset is a modern, enterprise-ready business intelligence web application

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Chuan-Yen Chiang | cychiang0823@gmail.com | https://github.com/cychiang |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| additionalRequirements[0] | string | `"psycopg2==2.8.5"` |  |
| additionalRequirements[1] | string | `"redis==3.2.1"` |  |
| affinity | object | `{}` |  |
| configFromSecret | string | `"{{ template \"superset.fullname\" . }}-config"` |  |
| configMountPath | string | `"/app/pythonpath"` |  |
| envFromSecret | string | `"{{ template \"superset.fullname\" . }}-env"` |  |
| extraEnv | object | `{}` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"preset/superset"` |  |
| image.tag | string | `"latest"` |  |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0] | string | `"chart-example.local"` |  |
| ingress.path | string | `"/"` |  |
| ingress.tls | list | `[]` |  |
| init.command[0] | string | `"/bin/sh"` |  |
| init.command[1] | string | `"-c"` |  |
| init.command[2] | string | `". {{ .Values.configMountPath }}/superset_bootstrap.sh; . {{ .Values.configMountPath }}/superset_init.sh"` |  |
| init.enabled | bool | `true` |  |
| init.initContainers[0].command[0] | string | `"/bin/sh"` |  |
| init.initContainers[0].command[1] | string | `"-c"` |  |
| init.initContainers[0].command[2] | string | `"until nc -zv $DB_HOST $DB_PORT -w1; do echo 'waiting for db'; sleep 1; done"` |  |
| init.initContainers[0].envFrom[0].secretRef.name | string | `"{{ tpl .Values.envFromSecret . }}"` |  |
| init.initContainers[0].image | string | `"busybox:latest"` |  |
| init.initContainers[0].imagePullPolicy | string | `"IfNotPresent"` |  |
| init.initContainers[0].name | string | `"wait-for-postgres"` |  |
| init.initscript | string | `"#!/bin/sh\necho \"Upgrading DB schema...\"\nsuperset db upgrade\necho \"Initializing roles...\"\nsuperset init\necho \"Creating admin user...\"\nsuperset fab create-admin \\\n                --username admin \\\n                  --firstname Superset \\\n                  --lastname Admin \\\n                  --email admin@superset.com \\\n                  --password admin || true\n{{ if .Values.init.loadExamples }}\necho \"Loading examples...\"\nsuperset load_examples\n{{- end }}"` |  |
| init.loadExamples | bool | `false` |  |
| nodeSelector | object | `{}` |  |
| postgresql.enabled | bool | `false` |  |
| postgresql.existingSecret | string | `nil` |  |
| postgresql.existingSecretKey | string | `"postgresql-password"` |  |
| postgresql.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| postgresql.persistence.enabled | bool | `true` |  |
| postgresql.postgresqlDatabase | string | `"superset"` |  |
| postgresql.postgresqlPassword | string | `"superset"` |  |
| postgresql.postgresqlUsername | string | `"superset"` |  |
| postgresql.service.port | int | `5432` |  |
| redis.cluster.enabled | bool | `false` |  |
| redis.enabled | bool | `false` |  |
| redis.existingSecret | string | `nil` |  |
| redis.existingSecretKey | string | `"redis-password"` |  |
| redis.master.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| redis.master.persistence.enabled | bool | `false` |  |
| redis.password | string | `"superset"` |  |
| redis.usePassword | bool | `false` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| service.port | int | `8088` |  |
| service.type | string | `"NodePort"` |  |
| supersetNode.command[0] | string | `"/bin/sh"` |  |
| supersetNode.command[1] | string | `"-c"` |  |
| supersetNode.command[2] | string | `". {{ .Values.configMountPath }}/superset_bootstrap.sh; /usr/bin/docker-entrypoint.sh"` |  |
| supersetNode.connections.db_host | string | `"{{ template \"superset.fullname\" . }}-postgresql"` |  |
| supersetNode.connections.db_name | string | `"superset"` |  |
| supersetNode.connections.db_pass | string | `"superset"` |  |
| supersetNode.connections.db_port | string | `"5432"` |  |
| supersetNode.connections.db_user | string | `"superset"` |  |
| supersetNode.connections.redis_host | string | `"{{ template \"superset.fullname\" . }}-redis-headless"` |  |
| supersetNode.connections.redis_port | string | `"6379"` |  |
| supersetNode.initContainers[0].command[0] | string | `"/bin/sh"` |  |
| supersetNode.initContainers[0].command[1] | string | `"-c"` |  |
| supersetNode.initContainers[0].command[2] | string | `"until nc -zv $DB_HOST $DB_PORT -w1; do echo 'waiting for db'; sleep 1; done"` |  |
| supersetNode.initContainers[0].envFrom[0].secretRef.name | string | `"{{ tpl .Values.envFromSecret . }}"` |  |
| supersetNode.initContainers[0].image | string | `"busybox:latest"` |  |
| supersetNode.initContainers[0].imagePullPolicy | string | `"IfNotPresent"` |  |
| supersetNode.initContainers[0].name | string | `"wait-for-postgres"` |  |
| tolerations | list | `[]` |  |
