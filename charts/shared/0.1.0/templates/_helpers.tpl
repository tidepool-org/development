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
Common labels
*/}}
{{- define "charts.labels" -}}
app.kubernetes.io/name: {{ include "charts.name" . }}
helm.sh/chart: {{ include "charts.chart" . }}
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
      endpoint: {{ printf "s3.%s.amazonaws.com" .Values.cluster.eks.region | quote }}
      region: {{ .Values.cluster.eks.region | quote }}
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

{{- define "charts.autoscaler.role" -}}
{{- printf "%s-autoscaler-role"  .Values.cluster.eks.name | quote -}}
{{- end -}}

{{- define "charts.certmanager.role" -}}
{{- printf "%s-certmanager-role"  .Values.cluster.eks.name | quote -}}
{{- end -}}

{{- define "charts.externalDNS.role" -}}
{{- printf "%s-externalDNS-role"  .Values.cluster.eks.name | quote -}}
{{- end -}}

{{- define "charts.externalSecrets.role" -}}
{{- printf "%s-secrets-role"  .Values.cluster.eks.name | quote -}}
{{- end -}}

{{- define "charts.fluxcloud.github" -}}
{{- if .Values.cluster.repo.name -}}
{{- printf "https://github.com/%s/%s" .Values.github.account .Values.cluster.repo.name | quote -}}
{{- else -}}
{{- printf "https://github.com/%s/cluster-%s" .Values.github.account .Values.cluster.eks.name | quote -}}
{{- end -}}
{{- end -}}

{{- define "charts.fluxcloud.slack.channel" -}}
{{- printf "#flux-%s" .Values.cluster.eks.name | quote -}}
{{- end -}}

{{- define "charts.mesh.labels" -}}
{{- if .Values.cluster.mesh.enabled }}
{{- if eq .Values.cluster.mesh.name "istio" }}
    istio-injection: disabled
{{- end }}
{{- if eq .Values.cluster.mesh.name "linkerd" }}
    linkerd.io/inject: disabled
{{- end -}}
{{ else }}
    mesh: disabled
{{- end -}}
{{- end }}
