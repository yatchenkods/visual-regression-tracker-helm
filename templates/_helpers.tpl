{{/*
Expand the name of the chart.
*/}}
{{- define "vrt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "vrt.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "vrt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vrt.labels" -}}
helm.sh/chart: {{ include "vrt.chart" . }}
{{ include "vrt.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vrt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vrt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vrt.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "vrt.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Database URL
*/}}
{{- define "vrt.databaseUrl" -}}
postgresql://{{ .Values.postgres.username }}:{{ .Values.postgres.persistence.enabled | ternary "$(POSTGRES_PASSWORD)" "" }}@{{ include "vrt.postgres.host" . }}:{{ .Values.postgres.port }}/{{ .Values.postgres.database }}
{{- end }}

{{/*
Postgres Host
*/}}
{{- define "vrt.postgres.host" -}}
{{- if .Values.postgres.enabled }}
{{ include "vrt.fullname" . }}-postgres
{{- else }}
{{ .Values.postgres.externalHost | default "postgres" }}
{{- end }}
{{- end }}

{{/*
API URL for frontend
*/}}
{{- define "vrt.apiUrl" -}}
{{- if .Values.ingress.enabled }}
{{ .Values.global.protocol }}://{{ (index .Values.ingress.hosts 0).host }}/api
{{- else }}
http://{{ include "vrt.fullname" . }}-api:{{ .Values.api.service.port }}
{{- end }}
{{- end }}
