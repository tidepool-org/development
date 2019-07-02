{{ define "charts.auth.env" }}
        - name: TIDEPOOL_AUTH_CLIENT_ADDRESS
          value: http://auth:{{.Values.global.ports.auth}}
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_ADDRESS
          value: http://{{include "charts.host.internal.tp" .}}.{{.Release.Namespace}}
        - name: TIDEPOOL_AUTH_CLIENT_EXTERNAL_SERVER_SESSION_TOKEN_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: secret
        - name: TIDEPOOL_AUTH_SERVICE_DOMAIN
          value: {{include "charts.host.internal.tp" .}}.{{.Release.Namespace}}
        - name: TIDEPOOL_AUTH_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: auth
        - name: TIDEPOOL_AUTH_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.auth}}
{{ end }}
