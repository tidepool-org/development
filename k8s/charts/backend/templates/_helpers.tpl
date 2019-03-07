{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "charts.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

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
          value: http://{{.Values.platformAuth.host}}:{{.Values.platformAuth.port}}
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_ADDRESS
          value: http://{{.Values.api.host}}:{{.Values.api.port}}
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_SERVER_SESSION_TOKEN_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: secret
        - name: TIDEPOOL_AUTH_SERVICE_DOMAIN
          value: '{{.Values.api.host}}'
        - name: TIDEPOOL_AUTH_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: auth
        - name: TIDEPOOL_AUTH_SERVICE_SERVER_ADDRESS
          value: :{{.Values.platformAuth.port}}
        - name: TIDEPOOL_BLOB_CLIENT_ADDRESS
          value: http://{{.Values.platformBlob.host}}:{{.Values.platformBlob.port}}
        - name: TIDEPOOL_BLOB_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: blob
        - name: TIDEPOOL_BLOB_SERVICE_SERVER_ADDRESS
          value: :{{.Values.platformBlob.port}}
        - name: TIDEPOOL_BLOB_SERVICE_UNSTRUCTURED_STORE_FILE_DIRECTORY
          value: '{{.Values.platformBlob.service.unstructured.store.file.directory}}'
        - name: TIDEPOOL_BLOB_SERVICE_UNSTRUCTURED_STORE_S3_BUCKET
          value: '{{.Values.platformBlob.service.unstructured.store.s3.bucket}}'
        - name: TIDEPOOL_BLOB_SERVICE_UNSTRUCTURED_STORE_S3_PREFIX
          value: '{{.Values.platformBlob.service.unstructured.store.s3.prefix}}'
        - name: TIDEPOOL_BLOB_SERVICE_UNSTRUCTURED_STORE_TYPE
          value: '{{.Values.platformBlob.service.unstructured.store.type}}'
        - name: TIDEPOOL_CONFIRMATION_STORE_DATABASE
          value: confirm
        - name: TIDEPOOL_DATA_CLIENT_ADDRESS
          value: http://{{.Values.platformData.host}}:{{.Values.platformData.port}}
        - name: TIDEPOOL_DATA_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: data
        - name: TIDEPOOL_DATA_SERVICE_SERVER_ADDRESS
          value: :{{.Values.platformData.port}}
        - name: TIDEPOOL_DATA_SOURCE_CLIENT_ADDRESS
          value: http://{{.Values.platformData.host}}:{{.Values.platformData.port}}
        - name: TIDEPOOL_DEPRECATED_DATA_STORE_DATABASE
          value: data
        - name: TIDEPOOL_DEXCOM_CLIENT_ADDRESS
          value: '{{.Values.service.provider.dexcom.client.address}}'
        - name: TIDEPOOL_ENV
          value: local
        - name: TIDEPOOL_LOGGER_LEVEL
          value: debug
        - name: TIDEPOOL_MESSAGE_STORE_DATABASE
          value: messages
        - name: TIDEPOOL_METRIC_CLIENT_ADDRESS
          value: http://{{.Values.api.host}}:{{.Values.api.port}}
        - name: TIDEPOOL_NOTIFICATION_CLIENT_ADDRESS
          value: http://{{.Values.platformNotification.host}}:{{.Values.platformNotification.port}}
        - name: TIDEPOOL_NOTIFICATION_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: notification
        - name: TIDEPOOL_NOTIFICATION_SERVICE_SERVER_ADDRESS
          value: :{{.Values.platformNotification.port}}
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
          value: '{{.Values.service.provider.dexcom.client.id}}'
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_CLIENT_SECRET
          value: '{{.Values.service.provider.dexcom.client.secret}}'
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_REDIRECT_URL
          value: http://{{.Values.api.host}}:{{.Values.api.port}}/v1/oauth/dexcom/redirect
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_SCOPES
          value: offline_access
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_STATE_SALT
          value: '{{.Values.service.provider.dexcom.state.salt}}'
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_TOKEN_URL
          value: '{{.Values.service.provider.dexcom.token.url}}'
        - name: TIDEPOOL_SESSION_STORE_DATABASE
          value: user
        - name: TIDEPOOL_STORE_ADDRESSES
          value: '{{.Values.mongo.host}}:{{.Values.mongo.port}}'
        - name: TIDEPOOL_STORE_DATABASE
          value: tidepool
        - name: TIDEPOOL_STORE_TLS
          value: '{{.Values.mongo.tls}}'
        - name: TIDEPOOL_SYNC_TASK_STORE_DATABASE
          value: data
        - name: TIDEPOOL_TASK_CLIENT_ADDRESS
          value: http://{{.Values.platformTask.host}}:{{.Values.platformTask.port}}
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
          value: :{{.Values.platformTask.port}}
        - name: TIDEPOOL_USER_CLIENT_ADDRESS
          value: http://{{.Values.api.host}}:{{.Values.api.port}}
        - name: TIDEPOOL_USER_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: user
        - name: TIDEPOOL_USER_SERVICE_SERVER_ADDRESS
          value: :{{.Values.platformUser.port}}
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
          value: :{{.Values.platformImage.port}}
        - name: TIDEPOOL_IMAGE_CLIENT_ADDRESS
          value: http://{{.Values.platformImage.host}}:{{.Values.platformImage.port}}
        - name: TIDEPOOL_IMAGE_SERVICE_UNSTRUCTURED_STORE_TYPE
          value: '{{.Values.platformImage.service.unstructured.store.type}}'
        - name: TIDEPOOL_IMAGE_SERVICE_UNSTRUCTURED_STORE_FILE_DIRECTORY
          value: '{{.Values.platformImage.service.unstructured.store.file.directory}}'
        - name: TIDEPOOL_IMAGE_SERVICE_UNSTRUCTURED_STORE_S3_BUCKET
          value: '{{.Values.platformImage.service.unstructured.store.s3.bucket}}'
        - name: TIDEPOOL_IMAGE_SERVICE_UNSTRUCTURED_STORE_S3_PREFIX
          value: '{{.Values.platformImage.service.unstructured.store.s3.prefix}}'
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
