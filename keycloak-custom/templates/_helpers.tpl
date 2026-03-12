{{/*
Expand the name of the chart.
*/}}
{{- define "keycloak-custom.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this.
*/}}
{{- define "keycloak-custom.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart label value.
*/}}
{{- define "keycloak-custom.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to all resources.
*/}}
{{- define "keycloak-custom.labels" -}}
helm.sh/chart: {{ include "keycloak-custom.chart" . }}
{{ include "keycloak-custom.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "keycloak-custom.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keycloak-custom.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Resolve the namespace to deploy resources into.
Falls back to .Release.Namespace when global.namespace is empty.
*/}}
{{- define "keycloak-custom.namespace" -}}
{{- coalesce .Values.global.namespace .Release.Namespace }}
{{- end }}

{{/*
Fully-qualified name of the PostgreSQL cluster created by the Zalando operator.
Convention: <teamId>-<clusterName>
*/}}
{{- define "keycloak-custom.postgresClusterName" -}}
{{- printf "%s-%s" .Values.postgresql.teamId .Values.postgresql.clusterName }}
{{- end }}

{{/*
Name of the database credentials secret auto-created by the Zalando operator.
Convention: <user>.<teamId>-<clusterName>
*/}}
{{- define "keycloak-custom.zalandoCredentialSecret" -}}
{{- printf "%s.%s" .Values.postgresql.user (include "keycloak-custom.postgresClusterName" .) }}
{{- end }}

{{/*
Keycloak image tag – falls back to .Chart.AppVersion.
*/}}
{{- define "keycloak-custom.imageTag" -}}
{{- default .Chart.AppVersion .Values.keycloak.image.tag }}
{{- end }}
