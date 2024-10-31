---
title: "vmagent"
date: 2024-10-28T23:06:54+08:00
weight: 1
---

`vmagent` is a tiny agent which helps you collect metrics from various sources, [relabel and filter the collected metrics](https://docs.victoriametrics.com/vmagent/#relabeling) and store them in [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics) or any other storage systems via Prometheus `remote_write` protocol or via [VictoriaMetrics `remote_write` protocol](https://docs.victoriametrics.com/vmagent/#victoriametrics-remote-write-protocol).

See [Quick Start](https://docs.victoriametrics.com/vmagent/#quick-start) for details.

[![vmagent](https://docs.victoriametrics.com/vmagent.webp)](https://docs.victoriametrics.com/vmagent.webp)

## Motivation
--------------------------------------------------------------------

While VictoriaMetrics provides an efficient solution to store and observe metrics, our users needed something fast and RAM friendly to scrape metrics from Prometheus-compatible exporters into VictoriaMetrics. Also, we found that our user’s infrastructure are like snowflakes in that no two are alike. Therefore, we decided to add more flexibility to `vmagent` such as the ability to [accept metrics via popular push protocols](https://docs.victoriametrics.com/vmagent/#how-to-push-data-to-vmagent) additionally to [discovering Prometheus-compatible targets and scraping metrics from them](https://docs.victoriametrics.com/vmagent/#how-to-collect-metrics-in-prometheus-format).

## Features 

*   Can be used as a drop-in replacement for Prometheus for discovering and scraping targets such as [node_exporter](https://github.com/prometheus/node_exporter). Note that single-node VictoriaMetrics can also discover and scrape Prometheus-compatible targets in the same way as `vmagent` does - see [these docs](https://docs.victoriametrics.com/#how-to-scrape-prometheus-exporters-such-as-node-exporter).
    
*   Can add, remove and modify labels (aka tags) via Prometheus relabeling. Can filter data before sending it to remote storage. See [these docs](https://docs.victoriametrics.com/vmagent/#relabeling) for details.
    
*   Can accept data via all the ingestion protocols supported by VictoriaMetrics - see [these docs](https://docs.victoriametrics.com/vmagent/#how-to-push-data-to-vmagent).
    
*   Can aggregate incoming samples by time and by labels before sending them to remote storage - see [these docs](https://docs.victoriametrics.com/stream-aggregation/).
    
*   Can replicate collected metrics simultaneously to multiple Prometheus-compatible remote storage systems - see [these docs](https://docs.victoriametrics.com/vmagent/#replication-and-high-availability).
    
*   Can save egress network bandwidth usage costs when [VictoriaMetrics remote write protocol](https://docs.victoriametrics.com/vmagent/#victoriametrics-remote-write-protocol) is used for sending the data to VictoriaMetrics.
    
*   Works smoothly in environments with unstable connections to remote storage. If the remote storage is unavailable, the collected metrics are buffered at `-remoteWrite.tmpDataPath`. The buffered metrics are sent to remote storage as soon as the connection to the remote storage is repaired. The maximum disk usage for the buffer can be limited with `-remoteWrite.maxDiskUsagePerURL`.
    
*   Uses lower amounts of RAM, CPU, disk IO and network bandwidth than Prometheus.
    
*   Scrape targets can be spread among multiple `vmagent` instances when big number of targets must be scraped. See [these docs](https://docs.victoriametrics.com/vmagent/#scraping-big-number-of-targets).
    
*   Can load scrape configs from multiple files. See [these docs](https://docs.victoriametrics.com/vmagent/#loading-scrape-configs-from-multiple-files).
    
*   Can efficiently scrape targets that expose millions of time series such as [/federate endpoint in Prometheus](https://prometheus.io/docs/prometheus/latest/federation/). See [these docs](https://docs.victoriametrics.com/vmagent/#stream-parsing-mode).
    
*   Can deal with [high cardinality](https://docs.victoriametrics.com/faq/#what-is-high-cardinality) and [high churn rate](https://docs.victoriametrics.com/faq/#what-is-high-churn-rate) issues by limiting the number of unique time series at scrape time and before sending them to remote storage systems. See [these docs](https://docs.victoriametrics.com/vmagent/#cardinality-limiter).
    
*   Can write collected metrics to multiple tenants. See [these docs](https://docs.victoriametrics.com/vmagent/#multitenancy).
    
*   Can read and write data from / to Kafka. See [these docs](https://docs.victoriametrics.com/vmagent/#kafka-integration).
    
*   Can read and write data from / to Google PubSub. See [these docs](https://docs.victoriametrics.com/vmagent/#google-pubsub-integration).
    

## Quick Start

Please download `vmutils-*` archive from [releases page](https://github.com/VictoriaMetrics/VictoriaMetrics/releases/latest) ( `vmagent` is also available in [docker images](https://hub.docker.com/r/victoriametrics/vmagent/tags)), unpack it and pass the following flags to the `vmagent` binary in order to start scraping Prometheus-compatible targets and sending the data to the Prometheus-compatible remote storage:

*   `-promscrape.config` with the path to [Prometheus config file](https://docs.victoriametrics.com/sd_configs/) (usually located at `/etc/prometheus/prometheus.yml`). The path can point either to local file or to http url. See [scrape config examples](https://docs.victoriametrics.com/scrape_config_examples/). `vmagent` doesn’t support some sections of Prometheus config file, so you may need either to delete these sections or to run `vmagent` with `-promscrape.config.strictParse=false` command-line flag. In this case `vmagent` ignores unsupported sections. See [the list of unsupported sections](https://docs.victoriametrics.com/vmagent/#unsupported-prometheus-config-sections).
    
*   `-remoteWrite.url` with Prometheus-compatible remote storage endpoint such as VictoriaMetrics, where to send the data to. The `-remoteWrite.url` may refer to [DNS SRV](https://en.wikipedia.org/wiki/SRV_record) address. See [these docs](https://docs.victoriametrics.com/vmagent/#srv-urls) for details.
    

Example command for writing the data received via [supported push-based protocols](https://docs.victoriametrics.com/vmagent/#how-to-push-data-to-vmagent) to [single-node VictoriaMetrics](https://docs.victoriametrics.com/) located at `victoria-metrics-host:8428`:

```sh
/path/to/vmagent -remoteWrite.url=https://victoria-metrics-host:8428/api/v1/write
```


See [these docs](https://docs.victoriametrics.com/cluster-victoriametrics/#url-format) if you need writing the data to [VictoriaMetrics cluster](https://docs.victoriametrics.com/cluster-victoriametrics/).

Example command for scraping Prometheus targets and writing the data to single-node VictoriaMetrics:

```sh
/path/to/vmagent -promscrape.config=/path/to/prometheus.yml -remoteWrite.url=https://victoria-metrics-host:8428/api/v1/write
```


See [how to scrape Prometheus-compatible targets](https://docs.victoriametrics.com/vmagent/#how-to-collect-metrics-in-prometheus-format) for more details.

If you use single-node VictoriaMetrics, then you can discover and scrape Prometheus-compatible targets directly from VictoriaMetrics without the need to use `vmagent` \- see [these docs](https://docs.victoriametrics.com/#how-to-scrape-prometheus-exporters-such-as-node-exporter).

`vmagent` can save network bandwidth usage costs under high load when [VictoriaMetrics remote write protocol is used](https://docs.victoriametrics.com/vmagent/#victoriametrics-remote-write-protocol).

See [troubleshooting docs](https://docs.victoriametrics.com/vmagent/#troubleshooting) if you encounter common issues with `vmagent`.

See [various use cases](https://docs.victoriametrics.com/vmagent/#use-cases) for vmagent.

Pass `-help` to `vmagent` in order to see [the full list of supported command-line flags with their descriptions](https://docs.victoriametrics.com/vmagent/#advanced-usage).

## How to push data to vmagent

`vmagent` supports [the same set of push-based data ingestion protocols as VictoriaMetrics does](https://docs.victoriametrics.com/#how-to-import-time-series-data) in addition to the pull-based Prometheus-compatible targets’ scraping:

*   DataDog “submit metrics” API. See [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-send-data-from-datadog-agent).
    
*   InfluxDB line protocol via `http://<vmagent>:8429/write`. See [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-send-data-from-influxdb-compatible-agents-such-as-telegraf).
    
*   Graphite plaintext protocol if `-graphiteListenAddr` command-line flag is set. See [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-send-data-from-graphite-compatible-agents-such-as-statsd).
    
*   OpenTelemetry http API. See [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#sending-data-via-opentelemetry).
    
*   NewRelic API. See [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-send-data-from-newrelic-agent).
    
*   OpenTSDB telnet and http protocols if `-opentsdbListenAddr` command-line flag is set. See [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-send-data-from-opentsdb-compatible-agents).
    
*   Prometheus remote write protocol via `http://<vmagent>:8429/api/v1/write`.
    
*   JSON lines import protocol via `http://<vmagent>:8429/api/v1/import`. See [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-import-data-in-json-line-format).
    
*   Native data import protocol via `http://<vmagent>:8429/api/v1/import/native`. See [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-import-data-in-native-format).
    
*   Prometheus exposition format via `http://<vmagent>:8429/api/v1/import/prometheus`. See [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-import-data-in-prometheus-exposition-format) for details.
    
*   Arbitrary CSV data via `http://<vmagent>:8429/api/v1/import/csv`. See [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#how-to-import-csv-data).
    

## Configuration update

`vmagent` should be restarted in order to update config options set via command-line args. `vmagent` supports multiple approaches for reloading configs from updated config files such as `-promscrape.config`, `-remoteWrite.relabelConfig`, `-remoteWrite.urlRelabelConfig`, `-streamAggr.config` and `-remoteWrite.streamAggr.config`:

*   Sending `SIGHUP` signal to `vmagent` process:
    
    ```
    kill -SIGHUP \`pidof vmagent\`
    ```
    
    ShellCopy
    
*   Sending HTTP request to `http://vmagent:8429/-/reload` endpoint. This endpoint can be protected with `-reloadAuthKey` command-line flag.
    

There is also `-promscrape.configCheckInterval` command-line flag, which can be used for automatic reloading configs from updated `-promscrape.config` file.