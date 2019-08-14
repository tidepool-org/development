local config = import 'values.json';

local autoscaler = import 'autoscaler.jsonnet';
local certmanager = import 'certmanager.jsonnet';
local clusterconfig = import 'clusterconfig.jsonnet';
local datadog = import 'datadog.jsonnet';
local externalDNS = import 'externalDNS.jsonnet';
local fluxcloud = import 'fluxcloud.jsonnet';
local gloo = import 'gloo.jsonnet';
local kiam = import 'kiam.jsonnet';
local kubeStateMetrics = import 'kubeStateMetrics.jsonnet';
local metricsServer = import 'metricsServer.jsonnet';
local prometheusOperator = import 'prometheusOperator.jsonnet';
local reloader = import 'reloader.jsonnet';
local sumologic = import 'sumologic.jsonnet';
local tidepool = import 'tidepool.jsonnet';

std.prune(autoscaler(config)+
certmanager(config) +
clusterconfig(config) +
datadog(config) +
externalDNS(config) +
fluxcloud(config) +
gloo(config) +
kiam(config) +
kubeStateMetrics(config) +
metricsServer(config) +
prometheusOperator(config) +
reloader(config) +
sumologic(config) +
tidepool(config))
