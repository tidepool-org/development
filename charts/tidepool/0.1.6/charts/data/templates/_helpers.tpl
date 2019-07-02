{{ define "charts.data.env" }}
        - name: TIDEPOOL_DATA_CLIENT_ADDRESS
          value: http://data:{{.Values.global.ports.data}}
        - name: TIDEPOOL_DATA_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: data
        - name: TIDEPOOL_DATA_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.data}}
        - name: TIDEPOOL_DATA_SOURCE_CLIENT_ADDRESS
          value: http://data:{{.Values.global.ports.data}}
{{ end }}

