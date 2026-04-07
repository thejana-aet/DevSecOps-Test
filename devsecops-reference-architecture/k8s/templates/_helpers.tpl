{{- define "backend.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "backend.fullname" -}}
{{- printf "%s" (include "backend.name" .) -}}
{{- end -}}

{{- define "backend.labels" -}}
app.kubernetes.io/name: {{ include "backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: backend
component: api
{{- end -}}

{{- define "backend.selectorLabels" -}}
app: backend
component: api
{{- end -}}
