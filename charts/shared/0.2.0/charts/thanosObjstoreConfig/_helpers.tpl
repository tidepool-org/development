{{ define "charts.thanos.secret" }}
    type: S3
    config:
      bucket: {{ .Values.bucket | quote }}
      endpoint: {{ printf "s3.%s.amazonaws.com" .Values.global.cluster.region | quote }}
      region: {{ .Values.global.cluster.region | quote }}
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
