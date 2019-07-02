{{ define "charts.user.env" }}
        - name: TIDEPOOL_USER_CLIENT_ADDRESS
          value: http://{{include "charts.host.internal.tp" .}}.{{.Release.Namespace}}
        - name: TIDEPOOL_USER_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: user
        - name: TIDEPOOL_USER_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.user}}
        - name: TIDEPOOL_USER_STORE_DATABASE
          value: user
        - name: TIDEPOOL_USER_STORE_PASSWORD_SALT
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: shoreline
{{ end }}
