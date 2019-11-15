job "openfaas-gateway" {
  datacenters = ["dc1"]

  type = "service"

  group "gateway" {
    count = 1

    network {
      mode= "bridge"

      port "http" {
        to=8080
      }
      port "metrics" {
        to=8082
      }
    }

    service {
      name = "gateway-fn"
      port = "http"
      tags =[
        "traefik.enable=true",
        "traefik.frontend.rule=PathPrefixStrip:/gateway/",
      ]
    }
    
    service {
      name = "gateway"
      port = "metrics"
      tags =[
        "prometheus"
      ]
    }

    service {
      name = "openfaas-gateway"
      port = 8080

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "openfaas-provider"
              local_bind_port  = 8081
            }
            upstreams {
              destination_name = "prometheus"
              local_bind_port  = 9090
            }
            upstreams {
              destination_name = "nats"
              local_bind_port  = 4222
            }
          }
        }
      }
    }

    task "gateway" {
      driver = "docker"

      template {
        env = true
        destination = "secrets/gateway.env"
        change_mode = "restart" 

        data = <<EOF
functions_provider_url="http://{{ env "NOMAD_UPSTREAM_ADDR_openfaas_provider" }}/"

faas_prometheus_host="{{ env "NOMAD_UPSTREAM_IP_prometheus" }}"
faas_prometheus_port="{{ env "NOMAD_UPSTREAM_PORT_prometheus"  }}"

faas_nats_address="{{ env "NOMAD_UPSTREAM_IP_nats"  }}"
faas_nats_port="{{ env "NOMAD_UPSTREAM_PORT_nats" }}"
EOF
      }

      config {
        image = "openfaas/gateway:0.18.2"
      }

      resources {
        cpu    = 500
        memory = 128
      }
    }
  }
}
