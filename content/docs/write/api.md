---
title: 写入 API
weight: 1
---

## 单机版

How to send data from DataDog agent #
VictoriaMetrics accepts data from DataDog agent, DogStatsD and DataDog Lambda Extension via “submit metrics” API at /datadog/api/v2/series or via “sketches” API at /datadog/api/beta/sketches.

Sending metrics to VictoriaMetrics #
DataDog agent allows configuring destinations for metrics sending via ENV variable DD_DD_URL or via configuration file in section dd_url.

DD to VM
To configure DataDog agent via ENV variable add the following prefix:

DD_DD_URL=http://victoriametrics:8428/datadog
Shell
Choose correct URL for VictoriaMetrics here.

To configure DataDog agent via configuration file add the following line:

dd_url: http://victoriametrics:8428/datadog
YAML
vmagent also can accept DataDog metrics format. Depending on where vmagent will forward data, pick single-node or cluster URL formats.

Sending metrics to DataDog and VictoriaMetrics #
DataDog allows configuring Dual Shipping for metrics sending via ENV variable DD_ADDITIONAL_ENDPOINTS or via configuration file additional_endpoints.

DD to VM
Run DataDog using the following ENV variable with VictoriaMetrics as additional metrics receiver:

DD_ADDITIONAL_ENDPOINTS='{\"http://victoriametrics:8428/datadog\": [\"apikey\"]}'
Shell
Choose correct URL for VictoriaMetrics here.

To configure DataDog Dual Shipping via configuration file add the following line:

additional_endpoints:
  "http://victoriametrics:8428/datadog":
  - apikey
YAML
Send metrics via Serverless DataDog plugin #
Disable logs (logs ingestion is not supported by VictoriaMetrics) and set a custom endpoint in serverless.yaml:

custom:
  datadog:
    enableDDLogs: false             # Disabled not supported DD logs
    apiKey: fakekey                 # Set any key, otherwise plugin fails
provider:
  environment:
    DD_DD_URL: <<vm-url>>/datadog   # VictoriaMetrics endpoint for DataDog
Send via cURL #
See how to send data to VictoriaMetrics via DataDog “submit metrics” API here.

The imported data can be read via export API.

Additional details #
VictoriaMetrics automatically sanitizes metric names for the data ingested via DataDog protocol according to DataDog metric naming recommendations. If you need accepting metric names as is without sanitizing, then pass -datadog.sanitizeMetricName=false command-line flag to VictoriaMetrics.

Extra labels may be added to all the written time series by passing extra_label=name=value query args. For example, /datadog/api/v2/series?extra_label=foo=bar would add {foo="bar"} label to all the ingested metrics.

DataDog agent sends the configured tags to undocumented endpoint - /datadog/intake. This endpoint isn’t supported by VictoriaMetrics yet. This prevents from adding the configured tags to DataDog agent data sent into VictoriaMetrics. The workaround is to run a sidecar vmagent alongside every DataDog agent, which must run with DD_DD_URL=http://localhost:8429/datadog environment variable. The sidecar vmagent must be configured with the needed tags via -remoteWrite.label command-line flag and must forward incoming data with the added tags to a centralized VictoriaMetrics specified via -remoteWrite.url command-line flag.

See these docs for details on how to add labels to metrics at vmagent.

How to send data from InfluxDB-compatible agents such as Telegraf #
Use http://<victoriametrics-addr>:8428 url instead of InfluxDB url in agents’ configs. For instance, put the following lines into Telegraf config, so it sends data to VictoriaMetrics instead of InfluxDB:

[[outputs.influxdb]]
  urls = ["http://<victoriametrics-addr>:8428"]
TOML
Another option is to enable TCP and UDP receiver for InfluxDB line protocol via -influxListenAddr command-line flag and stream plain InfluxDB line protocol data to the configured TCP and/or UDP addresses.

VictoriaMetrics performs the following transformations to the ingested InfluxDB data:

db query arg is mapped into db label value unless db tag exists in the InfluxDB line. The db label name can be overridden via -influxDBLabel command-line flag. If more strict data isolation is required, read more about multi-tenancy here.
Field names are mapped to time series names prefixed with {measurement}{separator} value, where {separator} equals to _ by default. It can be changed with -influxMeasurementFieldSeparator command-line flag. See also -influxSkipSingleField command-line flag. If {measurement} is empty or if -influxSkipMeasurement command-line flag is set, then time series names correspond to field names.
Field values are mapped to time series values.
Tags are mapped to Prometheus labels as-is.
If -usePromCompatibleNaming command-line flag is set, then all the metric names and label names are normalized to Prometheus-compatible naming by replacing unsupported chars with _. For example, foo.bar-baz/1 metric name or label name is substituted with foo_bar_baz_1.
For example, the following InfluxDB line:

foo,tag1=value1,tag2=value2 field1=12,field2=40
Influx Text Metric
is converted into the following Prometheus data points:

foo_field1{tag1="value1", tag2="value2"} 12
foo_field2{tag1="value1", tag2="value2"} 40
Prometheus Text Metric
Example for writing data with InfluxDB line protocol to local VictoriaMetrics using curl:

curl -d 'measurement,tag1=value1,tag2=value2 field1=123,field2=1.23' -X POST 'http://localhost:8428/write'
Shell
An arbitrary number of lines delimited by ‘\n’ (aka newline char) can be sent in a single request. After that the data may be read via /api/v1/export endpoint:

curl -G 'http://localhost:8428/api/v1/export' -d 'match={__name__=~"measurement_.*"}'
Shell
The /api/v1/export endpoint should return the following response:

{"metric":{"__name__":"measurement_field1","tag1":"value1","tag2":"value2"},"values":[123],"timestamps":[1560272508147]}
{"metric":{"__name__":"measurement_field2","tag1":"value1","tag2":"value2"},"values":[1.23],"timestamps":[1560272508147]}
JSON
Note that InfluxDB line protocol expects timestamps in nanoseconds by default, while VictoriaMetrics stores them with milliseconds precision. It is allowed to ingest timestamps with seconds, microseconds or nanoseconds precision - VictoriaMetrics will automatically convert them to milliseconds.

Extra labels may be added to all the written time series by passing extra_label=name=value query args. For example, /write?extra_label=foo=bar would add {foo="bar"} label to all the ingested metrics.

Some plugins for Telegraf such as fluentd, Juniper/open-nti or Juniper/jitmon send SHOW DATABASES query to /query and expect a particular database name in the response. Comma-separated list of expected databases can be passed to VictoriaMetrics via -influx.databaseNames command-line flag.

How to send data in InfluxDB v2 format #
VictoriaMetrics exposes endpoint for InfluxDB v2 HTTP API at /influx/api/v2/write and /api/v2/write.

In order to write data with InfluxDB line protocol to local VictoriaMetrics using curl:

curl -d 'measurement,tag1=value1,tag2=value2 field1=123,field2=1.23' -X POST 'http://localhost:8428/api/v2/write'
Shell
The /api/v1/export endpoint should return the following response:

{"metric":{"__name__":"measurement_field1","tag1":"value1","tag2":"value2"},"values":[123],"timestamps":[1695902762311]}
{"metric":{"__name__":"measurement_field2","tag1":"value1","tag2":"value2"},"values":[1.23],"timestamps":[1695902762311]}
JSON
How to send data from Graphite-compatible agents such as StatsD #
Enable Graphite receiver in VictoriaMetrics by setting -graphiteListenAddr command line flag. For instance, the following command will enable Graphite receiver in VictoriaMetrics on TCP and UDP port 2003:

/path/to/victoria-metrics-prod -graphiteListenAddr=:2003
Shell
Use the configured address in Graphite-compatible agents. For instance, set graphiteHost to the VictoriaMetrics host in StatsD configs.

Example for writing data with Graphite plaintext protocol to local VictoriaMetrics using nc:

echo "foo.bar.baz;tag1=value1;tag2=value2 123 `date +%s`" | nc -N localhost 2003
Shell
The ingested metrics can be sanitized according to Prometheus naming convention by passing -graphite.sanitizeMetricName command-line flag to VictoriaMetrics. The following modifications are applied to the ingested samples when this flag is passed to VictoriaMetrics:

remove redundant dots, e.g: metric..name => metric.name
replace characters not matching a-zA-Z0-9:_. chars with _
VictoriaMetrics sets the current time to the ingested samples if the timestamp is omitted.

An arbitrary number of lines delimited by \n (aka newline char) can be sent in one go. After that the data may be read via /api/v1/export endpoint:

curl -G 'http://localhost:8428/api/v1/export' -d 'match=foo.bar.baz'
Shell
The /api/v1/export endpoint should return the following response:

{"metric":{"__name__":"foo.bar.baz","tag1":"value1","tag2":"value2"},"values":[123],"timestamps":[1560277406000]}
JSON
Graphite relabeling can be used if the imported Graphite data is going to be queried via MetricsQL.


## 集群版

URLs for data ingestion: http://<vminsert>:8480/insert/<accountID>/<suffix>, where:

<accountID> is an arbitrary 32-bit integer identifying namespace for data ingestion (aka tenant). It is possible to set it as accountID:projectID, where projectID is also arbitrary 32-bit integer. If projectID isn’t set, then it equals to 0. See multitenancy docs for more details. The <accountID> can be set to multitenant string, e.g. http://<vminsert>:8480/insert/multitenant/<suffix>. Such urls accept data from multiple tenants specified via vm_account_id and vm_project_id labels. See multitenancy via labels for more details.
<suffix> may have the following values:
prometheus and prometheus/api/v1/write - for ingesting data with Prometheus remote write API.
prometheus/api/v1/import - for importing data obtained via api/v1/export at vmselect (see below), JSON line format.
prometheus/api/v1/import/native - for importing data obtained via api/v1/export/native on vmselect (see below).
prometheus/api/v1/import/csv - for importing arbitrary CSV data. See these docs for details.
prometheus/api/v1/import/prometheus - for importing data in Prometheus text exposition format and in OpenMetrics format. This endpoint also supports Pushgateway protocol. See these docs for details.
opentelemetry/v1/metrics - for ingesting data via OpenTelemetry protocol for metrics. See these docs.
datadog/api/v1/series - for ingesting data with DataDog submit metrics API v1. See these docs for details.
datadog/api/v2/series - for ingesting data with DataDog submit metrics API. See these docs for details.
datadog/api/beta/sketches - for ingesting data with DataDog lambda extension.
influx/write and influx/api/v2/write - for ingesting data with InfluxDB line protocol. TCP and UDP receiver is disabled by default. It is exposed on a distinct TCP address set via -influxListenAddr command-line flag. See these docs for details.
newrelic/infra/v2/metrics/events/bulk - for accepting data from NewRelic infrastructure agent. See these docs for details.
opentsdb/api/put - for accepting OpenTSDB HTTP /api/put requests. This handler is disabled by default. It is exposed on a distinct TCP address set via -opentsdbHTTPListenAddr command-line flag. See these docs for details.