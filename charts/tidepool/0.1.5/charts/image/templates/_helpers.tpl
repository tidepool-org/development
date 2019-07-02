{{- define "charts.image.s3.bucket" -}}
{{- if (.Values.image.service.unstructured.store.s3.bucket) and (ne .Values.image.service.unstructured.store.s3.bucket "") -}}
.Values.image.service.unstructured.store.s3.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

{{- define "charts.image.s3.url" -}} {{include "charts.s3.url" .}}/{{include "charts.image.s3.bucket" .}} {{- end }}

{{ define "charts.image.env" }}
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
{{ end}}
