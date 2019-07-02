{{- define "charts.blob.s3.bucket" -}}
{{- if (.Values.blob.service.unstructured.store.s3.bucket) and (ne .Values.blob.service.unstructured.store.s3.bucket "") -}}
.Values.blob.service.unstructured.store.s3.bucket
{{- else -}}
tidepool-{{ .Release.Namespace }}-data
{{- end -}}
{{- end -}}

{{- define "charts.blob.s3.url" -}} {{include "charts.s3.url" .}}/{{include "charts.blob.s3.bucket" .}} {{- end }}

{{ define "charts.blob.env" }}
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
{{ end }}

