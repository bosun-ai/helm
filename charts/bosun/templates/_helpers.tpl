{{- define "bosun.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bosun.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "bosun.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "bosun.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "bosun.labels" -}}
helm.sh/chart: {{ include "bosun.chart" . }}
app.kubernetes.io/name: {{ include "bosun.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.global.labels }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end -}}

{{- define "bosun.namespace" -}}
{{- default .Release.Namespace .Values.global.namespace -}}
{{- end -}}

{{- define "bosun.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bosun.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "bosun.componentFullname" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- printf "%s-%s" (include "bosun.fullname" $root) $component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bosun.quak.serviceAccountName" -}}
{{- if .Values.quak.serviceAccountName -}}
{{- .Values.quak.serviceAccountName -}}
{{- else if .Values.quak.rbac.enabled -}}
{{- include "bosun.componentFullname" (dict "root" . "component" "quak") -}}
{{- end -}}
{{- end -}}
