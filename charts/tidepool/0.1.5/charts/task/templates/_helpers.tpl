{{ define "charts.task.env" }}
        - name: TIDEPOOL_TASK_CLIENT_ADDRESS
          value: http://task:{{.Values.global.ports.task}}
        - name: TIDEPOOL_TASK_QUEUE_DELAY
          value: "5"
        - name: TIDEPOOL_TASK_QUEUE_WORKERS
          value: "5"
        - name: TIDEPOOL_TASK_SERVICE_SECRET
          valueFrom:
            secretKeyRef:
              name: server-secret
              key: task
        - name: TIDEPOOL_TASK_SERVICE_SERVER_ADDRESS
          value: :{{.Values.global.ports.task}}
{{ end }}
