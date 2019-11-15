job "alertmanager" {
  datacenters = ["dc1"]

  type = "service"

  group "alertmanager" {
    count = 1

    network {
      mode= "bridge"
    }

    service {
      name = "alertmanager"
      port = "9093"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "openfaas-gateway"
              local_bind_port  = 8080
            }
          }
        }
      }
    }
    
    task "alertmanager" {
      driver = "docker"

      config {
        image = "prom/alertmanager:v0.19.0"

        args = [
          "--config.file=/etc/alertmanager/alertmanager.yml",
          "--storage.path=/alertmanager",
        ]

        volumes = [
          "etc/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml",
        ]
      }

      resources {
        cpu    = 100
        memory = 128
      }

      template {
        destination   = "/etc/alertmanager/alertmanager.yml"
        change_mode   = "signal"
        change_signal = "SIGINT"

        data = <<EOF
route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 5s
  group_interval: 10s
  repeat_interval: 30s
  receiver: scale-up
  routes:
  - match:
      service: gateway
      receiver: scale-up
      severity: major
inhibit_rules:
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  equal: ['alertname', 'cluster', 'service']
receivers:
- name: 'scale-up'
  webhook_configs:
    - url: http://{{ env "NOMAD_UPSTREAM_ADDR_openfaas_gateway" }}/system/alert
      send_resolved: true
EOF
      }
    }
  }  
}