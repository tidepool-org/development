{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}

{{- define "charts.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "charts.mongo.start" -}}
{{- if .Values.mongo.username -}}
{{- .Values.mongo.username -}}
{{- if .Values.mongo.password -}}
:{{- .Values.mongo.password -}}
{{- end -}}
@
{{- end -}}
{{- .Values.mongo.host -}}:{{.Values.mongo.port}}
{{- end -}}

{{- define "charts.mongo.end" -}}
?ssl={{ .Values.mongo.tls}}
{{- if .Values.mongo.replicaSetName -}}
&replicaSet={{.Values.mongo.replicaSetName}}
{{- end -}}
{{- end -}}

{{- define "charts.host.internal.api" -}} {{ .Release.Namespace }}-api-internal {{- end }}
{{- define "charts.host.internal.uploads" -}} {{ .Release.Namespace }}-uploads-internal {{- end }}
{{- define "charts.host.internal.app" -}} {{ .Release.Namespace }}-app-internal {{- end }}

{{- define "charts.host.external.api" -}} {{ .Release.Namespace }}-api.tidepool.org {{- end }}
{{- define "charts.host.external.uploads" -}} {{ .Release.Namespace }}-uploads.tidepool.org {{- end }}
{{- define "charts.host.external.app" -}} {{ .Release.Namespace }}-app.tidepool.org {{- end }}

{{- define "charts.s3.url" -}} https://s3-{{.Values.aws.region}}.amazonaws.com {{- end }}

{{- define "charts.image.s3.bucket" -}}
{{- if and .Values.image.service.unstructured.store.s3.bucket (ne .Values.image.service.unstructured.store.s3.bucket "") -}}
.Values.image.service.unstructured.store.s3.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

{{- define "charts.blob.s3.bucket" -}}
{{- if and .Values.blob.service.unstructured.store.s3.bucket (ne .Values.blob.service.unstructured.store.s3.bucket "") -}}
.Values.blob.service.unstructured.store.s3.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

{{- define "charts.hydrophone.s3.bucket" -}}
{{- if and .Values.hydrophone.bucket (ne .Values.hydrophone.bucket "") -}}
.Values.hydrophone.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-asset
{{- end -}}
{{- end -}}

{{- define "charts.jellyfish.s3.bucket" -}}
{{- if and .Values.jellyfish.bucket (ne .Values.jellyfish.bucket "") -}}
{{- if .Values.jellyfish.bucket -}}
.Values.jellyfish.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

{{- define "charts.image.s3.url" -}} {{include "charts.s3.url" .}}/{{include "charts.image.s3.bucket" .}} {{- end }}
{{- define "charts.blob.s3.url" -}} {{include "charts.s3.url" .}}/{{include "charts.blob.s3.bucket" .}} {{- end }}
{{- define "charts.hydrophone.s3.url" -}} {{include "charts.s3.url" .}}/{{include "charts.hydrophone.s3.bucket" .}} {{- end }}

{{- define "charts.protocol" -}}
{{ if .Values.gateway.https.enabled }}https {{- else -}} http {{- end -}} {{- end -}}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "charts.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
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
          value: http://{{.Values.auth.host}}:{{.Values.auth.port}}
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_ADDRESS
          value: http://{{include "charts.host.internal.api" .}}
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_SERVER_SESSION_TOKEN_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: secret
        - name: TIDEPOOL_AUTH_SERVICE_DOMAIN
          value: {{include "charts.host.internal.api" .}}
        - name: TIDEPOOL_AUTH_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: auth
        - name: TIDEPOOL_AUTH_SERVICE_SERVER_ADDRESS
          value: :{{.Values.auth.port}}
        - name: TIDEPOOL_BLOB_CLIENT_ADDRESS
          value: http://{{.Values.blob.host}}:{{.Values.blob.port}}
        - name: TIDEPOOL_BLOB_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: blob
        - name: TIDEPOOL_BLOB_SERVICE_SERVER_ADDRESS
          value: :{{.Values.blob.port}}
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
          value: http://{{.Values.data.host}}:{{.Values.data.port}}
        - name: TIDEPOOL_DATA_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: data
        - name: TIDEPOOL_DATA_SERVICE_SERVER_ADDRESS
          value: :{{.Values.data.port}}
        - name: TIDEPOOL_DATA_SOURCE_CLIENT_ADDRESS
          value: http://{{.Values.data.host}}:{{.Values.data.port}}
        - name: TIDEPOOL_DEPRECATED_DATA_STORE_DATABASE
          value: data
        - name: TIDEPOOL_DEXCOM_CLIENT_ADDRESS
          value: '{{.Values.service.provider.dexcom.client.url}}'
        - name: TIDEPOOL_ENV
          value: local
        - name: TIDEPOOL_LOGGER_LEVEL
          value: debug
        - name: TIDEPOOL_MESSAGE_STORE_DATABASE
          value: messages
        - name: TIDEPOOL_METRIC_CLIENT_ADDRESS
          value: http://{{include "charts.host.internal.api" .}}
        - name: TIDEPOOL_NOTIFICATION_CLIENT_ADDRESS
          value: http://{{.Values.notification.host}}:{{.Values.notification.port}}
        - name: TIDEPOOL_NOTIFICATION_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: notification
        - name: TIDEPOOL_NOTIFICATION_SERVICE_SERVER_ADDRESS
          value: :{{.Values.notification.port}}
        - name: TIDEPOOL_PERMISSION_CLIENT_ADDRESS
          value: http://{{.Values.gatekeeper.host}}:{{.Values.gatekeeper.port}}
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
          value: '{{.Values.service.provider.dexcom.authorize.url}}'
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
          value: http://{{include "charts.host.internal.api" .}}/v1/oauth/dexcom/redirect
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_SCOPES
          value: offline_access
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_STATE_SALT
          valueFrom:
            secretKeyRef:
              name: dexcom
              key: STATE_SALT
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_TOKEN_URL
          value: '{{.Values.service.provider.dexcom.token.url}}'
        - name: TIDEPOOL_SESSION_STORE_DATABASE
          value: user
        - name: TIDEPOOL_STORE_ADDRESSES
          value: '{{.Values.mongo.host}}:{{.Values.mongo.port}}'
        - name: TIDEPOOL_STORE_DATABASE
          value: tidepool
        - name: TIDEPOOL_STORE_USERNAME
          value: '{{.Values.mongo.username}}'
        - name: TIDEPOOL_STORE_PASSWORD
          value: '{{.Values.mongo.password}}'
        - name: TIDEPOOL_STORE_TLS
          value: '{{.Values.mongo.tls}}'
        - name: TIDEPOOL_STORE_OPT_PARAMS
          value: '{{.Values.mongo.optParams}}'
        - name: TIDEPOOL_SYNC_TASK_STORE_DATABASE
          value: data
        - name: TIDEPOOL_TASK_CLIENT_ADDRESS
          value: http://{{.Values.task.host}}:{{.Values.task.port}}
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
          value: :{{.Values.task.port}}
        - name: TIDEPOOL_USER_CLIENT_ADDRESS
          value: http://{{include "charts.host.internal.api" .}}
        - name: TIDEPOOL_USER_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: user
        - name: TIDEPOOL_USER_SERVICE_SERVER_ADDRESS
          value: :{{.Values.user.port}}
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
          value: :{{.Values.image.port}}
        - name: TIDEPOOL_IMAGE_CLIENT_ADDRESS
          value: http://{{.Values.image.host}}:{{.Values.image.port}}
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
            port: {{.port}}
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /status
            port: {{.port}}
          initialDelaySeconds: 5
          periodSeconds: 10
{{- end -}} 
{{- define "charts.init.mongo" -}}
      initContainers:
      - name: init-mongo
        image: busybox
        command: ['sh', '-c', 'until nc -zvv {{.Values.mongo.host}} {{.Values.mongo.port}}; do echo waiting for mongo; sleep 2; done;']
{{- end -}} 
{{- define "charts.init.shoreline" -}}
      initContainers:
      - name: init-shoreline
        image: busybox
        command: ['sh', '-c', 'until nc -zvv {{.Values.shoreline.host}} {{.Values.shoreline.port}}; do echo waiting for shoreline; sleep 2; done;']
{{- end -}} 
