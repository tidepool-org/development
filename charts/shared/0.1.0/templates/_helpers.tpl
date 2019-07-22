{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "shared.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "shared.fullname" -}}
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
{{- define "shared.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "shared.labels" -}}
app.kubernetes.io/name: {{ include "shared.name" . }}
helm.sh/chart: {{ include "shared.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{ define "charts.thanos.secret" }}
    type: S3
    config:
      bucket: {{ .Values.thanos.bucket | quote }}
      endpoint: {{ printf "s3.%s.amazonaws.com" .Values.global.awsRegion | quote }}
      region: {{ .Values.global.awsRegion | quote }}
      insecure: false
      signature_version2: false
      encrypt_sse: false
      put_user_metadata: {}
      http_config:
        idle_conn_timeout: 0s
        response_header_timeout: 0s
        insecure_skip_verify: false
      trace:
        enable: false
{{ end }}

{{ define "charts.autoscaler.role" }}
{{ printf "/cluster/%s/autoscaler-role"  .Values.global.clusterName | quote }}
{{ end }}

{{ define "charts.certmanager.role" }}
{{ printf "/cluster/%s/certmanager-role"  .Values.global.clusterName | quote }}
{{ end }}

{{ define "charts.externalDNS.role" }}
{{ printf "/cluster/%s/externalDNS-role"  .Values.global.clusterName | quote }}
{{ end }}

{{ define "charts.fluxcloud.github" }}
{{ printf "https://github.com/tidepool-org/cluster-%s" .Values.global.clusterName | quote }}
{{ end }}

{{ define "charts.fluxcloud.slack.channel" }}
{{ printf "#flux-%s" .Values.global.clusterName | quote }}
{{ end }}

{{ define "charts.kiam.arn" }}
{{ printf "arn:aws:iam::%s:role/cluster/%s/kiam-server-role" .Values.global.id .Values.global.clusterName | quote }}
{{ end }}

