{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}

{{- define "charts.default.host" -}}
{{- if eq .Values.global.environment.hosts.default.protocol "http" -}}
{{- .Values.global.environment.hosts.http.dnsNames | first -}}
{{- else -}}
{{- .Values.global.environment.hosts.https.dnsNames | first -}}
{{- end -}}
{{- end }}

{{- define "charts.host.external.tp" -}} 
{{- .Values.global.environment.hosts.default.protocol }}://{{ include "charts.default.host" . -}}
{{- end }}

{{- define "charts.certificate.secretName" -}}
{{- $.Release.Namespace -}}-tls-secret
{{- end -}}

{{- define "charts.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "charts.externalSecrets.role" -}}
{{ .Values.global.cluster.name }}-{{ .Release.Namespace}}-secrets-role
{{- end -}}

{{- define "charts.roles.permitted" -}}
{{- .Release.Namespace -}}/.*
{{- end -}}

{{- define "charts.worker.role" -}}
{{ .Values.global.cluster.name }}-{{ .Release.Namespace}}-worker-role
{{- end -}}

{{- define "charts.host.internal.tp" -}} internal {{- end }}

{{ define "charts.host.internal.address" -}}
http://internal.{{.Release.Namespace}}
{{- end }}

{{- define "charts.s3.url" -}} https://s3-{{.Values.global.cluster.region}}.amazonaws.com {{- end }}

{{- define "charts.image.s3.bucket" -}}
{{- if (.Values.image.deployment.env.bucket) and (ne .Values.image.deployment.env.bucket "") -}}
{{ .Values.image.deployment.env.bucket }}
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

{{- define "charts.blob.s3.bucket" -}}
{{- if (.Values.blob.deployment.env.bucket) and (ne .Values.blob.deployment.env.bucket "") -}}
{{ .Values.blob.deployment.env.bucket }}
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

{{- define "charts.hydrophone.s3.bucket" -}}
{{- if (.Values.hydrophone.deployment.env.bucket) and (ne .Values.hydrophone.deployment.env.bucket "") -}}
{{ .Values.hydrophone.deployment.env.bucket }}
{{- else -}}
tidepool-{{ .Release.Namespace }}-asset
{{- end -}}
{{- end -}}

{{- define "charts.jellyfish.s3.bucket" -}}
{{- if (.Values.jellyfish.deployment.env.bucket) and (ne .Values.jellyfish.deployment.env.bucket "") -}}
{{ .Values.jellyfish.deployment.env.bucket }}
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
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
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

{{- define "charts.secret.prefix" -}}
{{ .Values.global.cluster.name }}/{{ .Release.Namespace }}
{{- end -}}

{{/*
Create environment variables used by all platform services.
*/}}
}

{{ define "charts.platform.env.clients" }}
        - name: TIDEPOOL_AUTH_CLIENT_ADDRESS
          value: http://auth:{{.Values.auth.service.port}}
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_ADDRESS
          value: "{{ include "charts.host.internal.address" .}}"
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_SERVER_SESSION_TOKEN_SECRET
          valueFrom:
            secretKeyRef:
              name: server
              key: ServiceAuth
        - name: TIDEPOOL_BLOB_CLIENT_ADDRESS
          value: http://blob:{{.Values.blob.service.port}}
        - name: TIDEPOOL_DATA_CLIENT_ADDRESS
          value: http://data:{{.Values.data.service.port}}
        - name: TIDEPOOL_DATA_SOURCE_CLIENT_ADDRESS
          value: http://data:{{.Values.data.service.port}}
        - name: TIDEPOOL_DEXCOM_CLIENT_ADDRESS
          valueFrom:
            configMapKeyRef:
              name: dexcom
              key: ClientURL
        - name: TIDEPOOL_SERVICE_PROVIDER_DEXCOM_AUTHORIZE_URL
          valueFrom:
            configMapKeyRef:
              name: dexcom
              key: AuthorizeURL
        - name: TIDEPOOL_IMAGE_CLIENT_ADDRESS
          value: http://image:{{.Values.image.service.port}}
        - name: TIDEPOOL_METRIC_CLIENT_ADDRESS
          value: "{{ include "charts.host.internal.address" .}}"
        - name: TIDEPOOL_NOTIFICATION_CLIENT_ADDRESS
          value: http://notification:{{.Values.notification.service.port}}
        - name: TIDEPOOL_PERMISSION_CLIENT_ADDRESS
          value: http://gatekeeper:{{.Values.gatekeeper.service.port}}
        - name: TIDEPOOL_TASK_CLIENT_ADDRESS
          value: http://task:{{.Values.task.service.port}}
        - name: TIDEPOOL_USER_CLIENT_ADDRESS
          value: "{{ include "charts.host.internal.address" .}}"
{{ end }}

{{ define "charts.platform.env.misc" }}
        - name: TIDEPOOL_ENV
          value: local
        - name: TIDEPOOL_LOGGER_LEVEL
          value: {{ .Values.global.cluster.logLevel }}
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
          valueFrom:
            secretKeyRef:
              name: mongo
              key: Scheme
        - name: TIDEPOOL_STORE_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongo
              key: Username
        - name: TIDEPOOL_STORE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongo
              key: Password
              optional: true
        - name: TIDEPOOL_STORE_ADDRESSES
          valueFrom:
            secretKeyRef:
              name: mongo
              key: Addresses
        - name: TIDEPOOL_STORE_OPT_PARAMS
          valueFrom:
            secretKeyRef:
              name: mongo
              key: Optparams
        - name: TIDEPOOL_STORE_TLS
          valueFrom:
            secretKeyRef:
              name: mongo
              key: Tls
{{ end }}

{{ define "charts.platform.env.mongo" }}
{{ include "charts.mongo.params" . }}
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
{{- define "charts.init.shoreline" -}}
      - name: init-shoreline
        image: busybox
        command: ['sh', '-c', 'until nc -zvv shoreline {{.Values.shoreline.service.port}}; do echo waiting for shoreline; sleep 2; done;']
{{- end -}} 

{{- define "charts.labels.standard" -}}
    cluster: {{ .Values.global.cluster.eks.name }}
    helm.sh/chart: {{ include "charts.chart" . }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/name: {{ include "charts.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
{{ end }}
