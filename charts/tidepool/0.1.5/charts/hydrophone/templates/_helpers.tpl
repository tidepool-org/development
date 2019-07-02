{{- define "charts.hydrophone.s3.bucket" -}}
{{- if (.Values.hydrophone.bucket) and (ne .Values.hydrophone.bucket "") -}}
.Values.hydrophone.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-asset
{{- end -}}
{{- end -}}

{{- define "charts.hydrophone.s3.url" -}} {{include "charts.s3.url" .}}/{{include "charts.hydrophone.s3.bucket" .}} {{- end }}

