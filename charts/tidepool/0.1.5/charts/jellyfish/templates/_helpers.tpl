{{- define "charts.jellyfish.s3.bucket" -}}
{{- if (.Values.jellyfish.bucket) and (ne .Values.jellyfish.bucket "") -}}
.Values.jellyfish.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

