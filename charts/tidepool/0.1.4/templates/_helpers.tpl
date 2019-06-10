{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}

{{- define "charts.name" -}}
{{- default .Chart.Name .Values.global.nameOverrideide | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "charts.mongo.start" -}}
{{- if .Values.global.mongo.username -}}
{{- .Values.global.mongo.username -}}
{{- if .Values.global.mongo.password -}}
:{{- .Values.global.mongo.password -}}
{{- end -}}
@
{{- end -}}
{{- .Values.global.mongo.host -}}:{{.Values.global.mongo.port}}
{{- end -}}

{{- define "charts.mongo.end" -}}
?ssl={{ .Values.global.mongo.tls}}
{{- if .Values.global.mongo.replicaSetName -}}
&replicaSet={{.Values.global.mongo.replicaSetName}}
{{- end -}}
{{- end -}}

{{- define "charts.host.internal.tp" -}} internal {{- end }}

{{- define "charts.host.external.tp" -}}
{{- if .Values.global.hostnameOverride -}}
.Values.global.hostnameOverride
{{- else -}}
{{ .Release.Namespace }}.{{- .Values.global.gateway.domain.name -}}
{{- end -}}
{{- end }}

{{- define "charts.hosts" -}}
{{- if .Values.global.singleEnvironment -}}
*
{{- else -}}
{{- include "charts.host.external.tp" . -}}
{{- end -}}
{{- end -}}

{{- define "charts.s3.url" -}} https://s3-{{.Values.global.aws.region}}.amazonaws.com {{- end }}

{{- define "charts.image.s3.bucket" -}}
{{- if (.Values.image.service.unstructured.store.s3.bucket) and (ne .Values.image.service.unstructured.store.s3.bucket "") -}}
.Values.image.service.unstructured.store.s3.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

{{- define "charts.blob.s3.bucket" -}}
{{- if (.Values.blob.service.unstructured.store.s3.bucket) and (ne .Values.blob.service.unstructured.store.s3.bucket "") -}}
.Values.blob.service.unstructured.store.s3.bucket
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

{{- define "charts.protocol" -}}
{{ if .Values.global.gateway.https.enabled }}https {{- else -}} http {{- end -}} {{- end -}}


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
{{- define "charts.platform.env" -}}

        - name: TIDEPOOL_AUTH_CLIENT_ADDRESS
          value: http://auth:{{.Values.global.ports.auth}}
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_ADDRESS
          value: http://{{include "charts.host.internal.tp" .}}.{{.Release.Namespace}}
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_SERVER_SESSION_TOKEN_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: secret
        - name: TIDEPOOL_AUTH_SERVICE_DOMAIN
          value: {{include "charts.host.internal.tp" .}}.{{.Release.Namespace}}
        - name: TIDEPOOL_AUTH_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: auth
        - name: TIDEPOOL_AUTH_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.auth}}
        - name: TIDEPOOL_BLOB_CLIENT_ADDRESS
          value: http://blob:{{.Values.global.ports.blob}}
        - name: TIDEPOOL_BLOB_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: blob
        - name: TIDEPOOL_BLOB_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.blob}}
        - name: TIDEPOOL_BLOB_SERVICE_UNSTRUCTURED_STORE_FILE_DIRECTORY
          value: '{{.Values.blob.service.unstructured.store.file.directory}}'
        - name: TIDEPOOL_BLOB_SERVICE_UNSTRUCTURED_STORE_S3_BUCKET
          value: '{{include "charts.blob.s3.bucket" .}}'
        - name: TIDEPOOL_BLOB_SERVICE_UNSTRUCTURED_STORE_S3_PREFIX
          value: '{{.Values.blob.service.unstructured.store.s3.prefix}}'
        - name: TIDEPOOL_BLOB_SERVICE_UNSTRUCTURED_STORE_TYPE
          value: '{{.Values.blob.service.unstructured.store.type}}'
        - name: TIDEPOOL_CONFIRMATION_STORE_DATABASE
          value: confirm
        - name: TIDEPOOL_DATA_CLIENT_ADDRESS
          value: http://data:{{.Values.global.ports.data}}
        - name: TIDEPOOL_DATA_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: data
        - name: TIDEPOOL_DATA_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.data}}
        - name: TIDEPOOL_DATA_SOURCE_CLIENT_ADDRESS
          value: http://data:{{.Values.global.ports.data}}
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
        - name: TIDEPOOL_NOTIFICATION_CLIENT_ADDRESS
          value: http://notification:{{.Values.global.ports.notification}}
        - name: TIDEPOOL_NOTIFICATION_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: notification
        - name: TIDEPOOL_NOTIFICATION_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.notification}}
        - name: TIDEPOOL_PERMISSION_CLIENT_ADDRESS
          value: http://gatekeeper:{{.Values.global.ports.gatekeeper}}
        - name: TIDEPOOL_PERMISSION_STORE_DATABASE
          value: gatekeeper
        - name: TIDEPOOL_PERMISSION_STORE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: gatekeeper
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
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name: dexcom
              key: CLIENT_SECRET
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_REDIRECT_URL
          value: http://{{include "charts.host.internal.tp" .}}.{{.Release.Namespace}}/v1/oauth/dexcom/redirect
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_SCOPES
          value: offline_access
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_STATE_SALT
          valueFrom:
            secretKeyRef:
              name: dexcom
              key: STATE_SALT
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_TOKEN_URL
          value: '{{.Values.global.provider.dexcom.token.url}}'
        - name: TIDEPOOL_SESSION_STORE_DATABASE
          value: user
        - name: TIDEPOOL_STORE_ADDRESSES
          value: '{{.Values.global.mongo.host}}:{{.Values.global.mongo.port}}'
        - name: TIDEPOOL_STORE_DATABASE
          value: tidepool
        - name: TIDEPOOL_STORE_USERNAME
          value: '{{.Values.global.mongo.username}}'
        - name: TIDEPOOL_STORE_PASSWORD
          value: '{{.Values.global.mongo.password}}'
        - name: TIDEPOOL_STORE_TLS
          value: '{{.Values.global.mongo.tls}}'
        - name: TIDEPOOL_STORE_OPT_PARAMS
          value: '{{.Values.global.mongo.optParams}}'
        - name: TIDEPOOL_SYNC_TASK_STORE_DATABASE
          value: data
        - name: TIDEPOOL_TASK_CLIENT_ADDRESS
          value: http://task:{{.Values.global.ports.task}}
        - name: TIDEPOOL_TASK_QUEUE_DELAY
          value: "5"
        - name: TIDEPOOL_TASK_QUEUE_WORKERS
          value: "5"
        - name: TIDEPOOL_TASK_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: task
        - name: TIDEPOOL_TASK_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.task}}
        - name: TIDEPOOL_USER_CLIENT_ADDRESS
          value: http://{{include "charts.host.internal.tp" .}}.{{.Release.Namespace}}
        - name: TIDEPOOL_USER_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: user
        - name: TIDEPOOL_USER_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.user}}
        - name: TIDEPOOL_USER_STORE_DATABASE
          value: user
        - name: TIDEPOOL_USER_STORE_PASSWORD_SALT
          value: '{{.Values.shoreline.salt}}'
        - name: TIDEPOOL_IMAGE_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: image 
        - name: TIDEPOOL_IMAGE_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.image}}
        - name: TIDEPOOL_IMAGE_CLIENT_ADDRESS
          value: http://image:{{.Values.global.ports.image}}
        - name: TIDEPOOL_IMAGE_SERVICE_UNSTRUCTURED_STORE_TYPE
          value: '{{.Values.image.service.unstructured.store.type}}'
        - name: TIDEPOOL_IMAGE_SERVICE_UNSTRUCTURED_STORE_FILE_DIRECTORY
          value: '{{.Values.image.service.unstructured.store.file.directory}}'
        - name: TIDEPOOL_IMAGE_SERVICE_UNSTRUCTURED_STORE_S3_BUCKET
          value: '{{include "charts.blob.s3.bucket" .}}'
        - name: TIDEPOOL_IMAGE_SERVICE_UNSTRUCTURED_STORE_S3_PREFIX
          value: '{{.Values.image.service.unstructured.store.s3.prefix}}'
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
      initContainers:
      - name: init-mongo
        image: busybox
        command: ['sh', '-c', 'until nc -zvv {{.Values.global.mongo.host}} {{.Values.global.mongo.port}}; do echo waiting for mongo; sleep 2; done;']
{{- end -}} 
{{- define "charts.init.shoreline" -}}
      initContainers:
      - name: init-shoreline
        image: busybox
        command: ['sh', '-c', 'until nc -zvv shoreline {{.Values.global.ports.shoreline}}; do echo waiting for shoreline; sleep 2; done;']
{{- end -}} 
