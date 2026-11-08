{{- define "freeze.name" -}}{{ .Release.Name }}{{- end -}}
{{- define "freeze.labels" -}}
app.kubernetes.io/name: tatarnetes-freeze
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "freeze.selector" -}}
app.kubernetes.io/name: tatarnetes-freeze
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "freeze.dns" -}}{{ include "freeze.name" . }}.{{ .Release.Namespace }}.svc{{- end -}}
