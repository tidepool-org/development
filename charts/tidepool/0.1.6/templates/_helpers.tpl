{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}

{{- define "charts.name" -}}
{{- default .Chart.Name .Values.global.nameOverrideide | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "charts.fullname" -}}
{{- if .Values.global.fullnameOverride -}}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.global.nameOverrideide -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "charts.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "charts.mongo.params" -}}
{{ if .Values.global.mongo.username }}
- name: MONGO_USER
  value: '{{ .Values.global.mongo.username }}'
{{ end }}
- name: MONGO_PASSWORD
  valueFrom:
    secretKeyRef:
      name: mongo
      key: password
      optional: true
{{ if .Values.global.mongo.hosts }}
- name: MONGO_HOSTS
  value: '{{ .Values.global.mongo.hosts }}'
{{ end }}
{{ if .Values.global.mongo.optParams }}
- name: MONGO_OPT_PARAMS
  value: '{{ .Values.global.mongo.optParams }}'
{{ end }}
{{ if .Values.global.mongo.ssl }}
- name: MONGO_SSL
  value: '{{ .Values.global.mongo.ssl }}'
{{ end }}
{{ end }}

{{- define "charts.host.internal.tp" -}} internal {{- end }}

{{- define "charts.host.external.tp" -}} 
{{- .Values.global.hosts.default.protocol -}}://{{- .Values.global.hosts.default.host -}}
{{- end }}

{{- define "charts.s3.url" -}} https://s3-{{.Values.global.aws.region}}.amazonaws.com {{- end }}

{{/*
Create environment variables used by all services.
*/}}

{{- define "charts.platform.env" -}}
- name: TIDEPOOL_CONFIRMATION_STORE_DATABASE
  value: confirm
- name: TIDEPOOL_DEPRECATED_DATA_STORE_DATABASE
  value: data
- name: TIDEPOOL_DEXCOM_CLIENT_ADDRESS
  value: '{{.Values.global.provider.dexcom.client.url}}'
- name: TIDEPOOL_ENV
  value: local
- name: TIDEPOOL_LOGGER_LEVEL
  value: debug
- name: TIDEPOOL_MESSAGE_STORE_DATABASE
  value: messages
- name: TIDEPOOL_METRIC_CLIENT_ADDRESS
  value: http://{{include "charts.host.internal.tp" .}}.{{.Release.Namespace}}
- name: TIDEPOOL_PROFILE_STORE_DATABASE
  value: seagull
- name: TIDEPOOL_SERVER_TLS
  value: "false"
- name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_AUTHORIZE_URL
  value: '{{.Values.global.provider.dexcom.authorize.url}}'
- name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: dexcom
      key: CLIENT_ID
      optional: true
- name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: dexcom
      key: CLIENT_SECRET
      optional: true
- name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_REDIRECT_URL
  value: {{include "charts.host.external.tp" .}}/v1/oauth/dexcom/redirect
- name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_SCOPES
  value: offline_access
- name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_STATE_SALT
  valueFrom:
    secretKeyRef:
      name: dexcom
      key: STATE_SALT
      optional: true
- name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_TOKEN_URL
  value: '{{.Values.global.provider.dexcom.token.url}}'
- name: TIDEPOOL_SESSION_STORE_DATABASE
  value: user
- name: TIDEPOOL_STORE_ADDRESSES
  value: '{{ .Values.global.mongo.hosts }}'
- name: TIDEPOOL_STORE_DATABASE
  value: tidepool
- name: TIDEPOOL_STORE_USERNAME
  value: '{{.Values.global.mongo.username}}'
- name: TIDEPOOL_STORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: mongo
      key: password
      optional: true
- name: TIDEPOOL_STORE_TLS
  value: '{{.Values.global.mongo.ssl}}'
- name: TIDEPOOL_STORE_OPT_PARAMS
  value: '{{.Values.global.mongo.optParams}}'
- name: TIDEPOOL_SYNC_TASK_STORE_DATABASE
  value: data
{{- end -}}        

{{/*
Create liveness and readiness probes for platform services.
*/}}
{{- define "charts.platform.probes" -}}
        livenessProbe:
          httpGet:
            path: /status
            port: {{.}}
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /status
            port: {{.}}
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 5
{{- end -}} 
{{- define "charts.init.mongo" -}}
- name: init-mongo
  image: busybox
  command: ['sh', '-c', 'until nc -zvv {{ (split "," .Values.global.mongo.hosts)._0 }} {{.Values.global.mongo.port}}; do echo waiting for mongo; sleep 2; done;']
{{- end -}} 
{{- define "charts.init.shoreline" -}}
- name: init-shoreline
  image: busybox
  command: ['sh', '-c', 'until nc -zvv shoreline {{.Values.global.ports.shoreline}}; do echo waiting for shoreline; sleep 2; done;']
{{- end -}} 
