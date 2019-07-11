{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}

{{- define "charts.name" -}}
{{- default .Chart.Name .Values.global.nameOverrideide | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "charts.host.internal.tp" -}} internal {{- end }}

{{- define "charts.host.external.tp" -}} 
{{- .Values.global.hosts.default.protocol -}}://{{- .Values.global.hosts.default.host -}}
{{- end }}

{{- define "charts.s3.url" -}} https://s3-{{.Values.global.aws.region}}.amazonaws.com {{- end }}

{{- define "charts.image.s3.bucket" -}}
{{- if (.Values.image.bucket) and (ne .Values.image.bucket "") -}}
.Values.image.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

{{- define "charts.blob.s3.bucket" -}}
{{- if (.Values.blob.bucket) and (ne .Values.blob.bucket "") -}}
.Values.blob.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

{{- define "charts.hydrophone.s3.bucket" -}}
{{- if (.Values.hydrophone.bucket) and (ne .Values.hydrophone.bucket "") -}}
.Values.hydrophone.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-asset
{{- end -}}
{{- end -}}

{{- define "charts.jellyfish.s3.bucket" -}}
{{- if (.Values.jellyfish.bucket) and (ne .Values.jellyfish.bucket "") -}}
.Values.jellyfish.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

{{- define "charts.image.s3.url" -}} {{include "charts.s3.url" .}}/{{include "charts.image.s3.bucket" .}} {{- end }}
{{- define "charts.blob.s3.url" -}} {{include "charts.s3.url" .}}/{{include "charts.blob.s3.bucket" .}} {{- end }}
{{- define "charts.hydrophone.s3.url" -}} {{include "charts.s3.url" .}}/{{include "charts.hydrophone.s3.bucket" .}} {{- end }}

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

{{/*
Create environment variables used by all platform services.
*/}}

{{ define "charts.platform.env.dexcom" }}
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_AUTHORIZE_URL
          value: '{{.Values.global.provider.dexcom.authorize.url}}'
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_REDIRECT_URL
          value: {{include "charts.host.external.tp" .}}/v1/oauth/dexcom/redirect
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_SCOPES
          value: offline_access
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_TOKEN_URL
          value: '{{.Values.global.provider.dexcom.token.url}}'
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: dexcom-api
              key: ClientId
              optional: true
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name: dexcom-api
              key: ClientSecret
              optional: true
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_STATE_SALT
          valueFrom:
            secretKeyRef:
              name: dexcom-api
              key: StateSalt
              optional: true
{{ end }}

{{ define "charts.platform.env.clients" }}
        - name: TIDEPOOL_AUTH_CLIENT_ADDRESS
          value: http://auth:{{.Values.global.ports.auth}}
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_ADDRESS
          value: http://{{include "charts.host.internal.tp" .}}.{{.Release.Namespace}}
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_SERVER_SESSION_TOKEN_SECRET
          valueFrom:
            secretKeyRef:
              name: tidepool-server-secret
              key: ServiceAuth
        - name: TIDEPOOL_BLOB_CLIENT_ADDRESS
          value: http://blob:{{.Values.global.ports.blob}}
        - name: TIDEPOOL_DATA_CLIENT_ADDRESS
          value: http://data:{{.Values.global.ports.data}}
        - name: TIDEPOOL_DATA_SOURCE_CLIENT_ADDRESS
          value: http://data:{{.Values.global.ports.data}}
        - name: TIDEPOOL_DEXCOM_CLIENT_ADDRESS
          value: '{{.Values.global.provider.dexcom.client.url}}'
        - name: TIDEPOOL_IMAGE_CLIENT_ADDRESS
          value: http://image:{{.Values.global.ports.image}}
        - name: TIDEPOOL_METRIC_CLIENT_ADDRESS
          value: http://{{include "charts.host.internal.tp" .}}.{{.Release.Namespace}}
        - name: TIDEPOOL_NOTIFICATION_CLIENT_ADDRESS
          value: http://notification:{{.Values.global.ports.notification}}
        - name: TIDEPOOL_PERMISSION_CLIENT_ADDRESS
          value: http://gatekeeper:{{.Values.global.ports.gatekeeper}}
        - name: TIDEPOOL_TASK_CLIENT_ADDRESS
          value: http://task:{{.Values.global.ports.task}}
        - name: TIDEPOOL_USER_CLIENT_ADDRESS
          value: http://{{include "charts.host.internal.tp" .}}.{{.Release.Namespace}}
{{ end }}

{{ define "charts.platform.env.misc" }}
        - name: TIDEPOOL_ENV
          value: local
        - name: TIDEPOOL_LOGGER_LEVEL
          value: debug
        - name: TIDEPOOL_SERVER_TLS
          value: "false"
        - name: TIDEPOOL_AUTH_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: auth
              key: ServiceAuth
{{ end }}

{{ define "charts.mongo.params" }}
        - name: TIDEPOOL_STORE_SCHEME
          value: '{{ .Values.global.mongo.scheme }}'
        - name: TIDEPOOL_STORE_USERNAME
          value: '{{ .Values.global.mongo.username }}'
        - name: TIDEPOOL_STORE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongo
              key: password
              optional: true
        - name: TIDEPOOL_STORE_ADDRESSES
          value: '{{ .Values.global.mongo.hosts }}'
        - name: TIDEPOOL_STORE_OPT_PARAMS
          value: '{{.Values.global.mongo.optParams}}'
        - name: TIDEPOOL_STORE_TLS
          value: '{{.Values.global.mongo.ssl}}'
{{ end }}

{{ define "charts.platform.env.mongo" }}
{{ include "charts.mongo.params" . }}
          value: '{{.Values.global.mongo.ssl}}'
        - name: TIDEPOOL_STORE_DATABASE
          value: tidepool
{{ end }}        

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
