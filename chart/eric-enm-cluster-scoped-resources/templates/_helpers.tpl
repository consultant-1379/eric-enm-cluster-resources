{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "eric-enm-cluster-resources.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "eric-enm-cluster-resources.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create ClusterRole for ddc kube-state-metrics pm-server
*/}}
{{- define "monitoring-integration.Cluster" -}}
{{- if .Values.ClusterRole.enable  -}}
{{- print .Values.ClusterRole.enable -}}
{{- else -}}
{{- print "eric-enm-monitoring" -}}
{{- end -}}
{{- end -}}

{{/*
Create ClusterRolebinding for oss ddc
*/}}
{{- define "eric-oss-ddc.cluster" -}}
{{- if .Values.ClusterRole.enable -}}
{{- print .Values.ClusterRole.enable -}}
{{- else -}}
{{- print "eric-oss-ddc" -}}
{{- end -}}
{{- end -}}

{{/*
Create ClusterRolebinding for pm sever
*/}}
{{- define "pm-server.cluster" -}}
{{- if .Values.ClusterRole.enable -}}
{{- print .Values.ClusterRole.enable -}}
{{- else -}}
{{- print "eric-pm-server" -}}
{{- end -}}
{{- end -}}

{{/*
Create troubleshooting utils
*/}}
{{- define "troubleshooting-utils.cluster" -}}
{{- if .Values.serviceAccountName -}}
{{- print .Values.ClusterRole.enable -}}
{{- else -}}
{{- print "troubleshooting-utils" -}}
{{- end -}}
{{- end -}}


{{/*
Create ClusterRole and ClusterRolebinding for kubestatemetrics
*/}}
{{- define "kube-state-metrics.cluster" -}}
{{- if .Values.ClusterRole.enable -}}
{{- print .Values.ClusterRole.enable -}}
{{- else -}}
{{- print "kube-state-metrics" -}}
{{- end -}}
{{- end -}}

