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

{{- define "charts.mongo.connectionstring" -}}
mongodb://{{ include "charts.mongo.start" . }}{{ include "charts.mongo.end . }}
{{- end -}}
