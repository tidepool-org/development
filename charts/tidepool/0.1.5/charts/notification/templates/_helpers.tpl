{{ define "charts.notification.env" }}
        - name: TIDEPOOL_NOTIFICATION_CLIENT_ADDRESS
          value: http://notification:{{.Values.global.ports.notification}}
        - name: TIDEPOOL_NOTIFICATION_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: notification
        - name: TIDEPOOL_NOTIFICATION_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.notification}}
{{ end }}
