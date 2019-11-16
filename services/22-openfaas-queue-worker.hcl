job "openfaas-queue-worker" {
  datacenters = ["dc1"]

  type = "service"

  group "gateway" {
    count = 1

    network {
      mode= "bridge"
    }

    service {
      name = "openfaas-gateway"
      port = 9999

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "gateway-fn"
              local_bind_port  = 8080
            }
            upstreams {
              destination_name = "nats"
              local_bind_port  = 4222
            }
          }
        }
      }
    }

    task "worker" {
      driver = "docker"

      template {
        env = true
        destination = "secrets/worker.env"
        change_mode = "restart" 

        data = <<EOF
gateway_invoke=true
faas_gateway_address={{ env "NOMAD_UPSTREAM_IP_gateway_fn" }}
faas_nats_address={{ env "NOMAD_UPSTREAM_IP_nats" }}
EOF
      }

      config {
        image = "openfaas/queue-worker:0.8.1"
      }

      resources {
        cpu    = 500
        memory = 128
      }
    }
  }
}
