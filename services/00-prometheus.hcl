job "prometheus" {
  datacenters = ["dc1"]

  type = "service"

  group "prometheus" {
    count = 1

    ephemeral_disk {
      sticky = true
      migrate = true
      size = 10240
    }

    network {
      mode= "bridge"

      port "http" {
        to="9090"
        static="9090"
      }
    }

    service {
      name = "prometheus"
      port = "9090"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "alertmanager"
              local_bind_port  = 9093
            }
          }
        }
      }
    }

    task "prometheus" {
      driver = "docker"
      user="root"

      config {
        image = "prom/prometheus:v2.13.1"
        args= ["--storage.tsdb.path","/local/data","--config.file","/local/prometheus.yml","--web.enable-lifecycle"]
      }

      resources {
        cpu    = 500
        memory = 2048
      }

      template {
        destination   = "local/prometheus.yml"
        change_mode   = "signal"
        change_signal = "SIGHUP"

        data = <<EOF
global:
  scrape_interval: 5s
rule_files:
  - 'alert.rules'
scrape_configs:
  - job_name: 'services'
    consul_sd_configs:
      - server: '{{env "attr.unique.network.ip-address"}}:8500'
    relabel_configs:
      - source_labels: [__meta_consul_tags]
        regex: .*,prometheus,.*
        action: keep
      - source_labels: [__meta_consul_service]
        regex: .*-sidecar-proxy
        action: drop
      - source_labels: [__meta_consul_service]
        target_label: job
      - source_labels: [__meta_consul_tags]
        regex: .*,prometheus.metrics_path=([^,]+),.*
        replacement: '${1}'
        target_label: __metrics_path__
alerting:
  alertmanagers:
    - static_configs:
      - targets:
        - {{ env "NOMAD_UPSTREAM_ADDR_alertmanager" }}
        EOF
      }

      template {
        destination   = "local/alert.rules"
        change_mode   = "signal"
        change_signal = "SIGHUP"

        data = <<EOF
groups:
- name: prometheus/alert.rules
  rules:
  - alert: service_down
    expr: up == 0
  - alert: APIHighInvocationRate
    expr: sum(rate(gateway_function_invocation_total{code="200"}[10s])) by (function_name) / sum(gateway_service_count) by (function_name) > 5
    for: 5s
    labels:
      service: gateway
      severity: major
    annotations:
      description: High invocation total on {{ "{{" }} $labels.function_name {{ "}}" }}
      summary: High invocation total on {{ "{{" }} $labels.function_name {{ "}}" }}
        EOF
      }
    }
  }
}
