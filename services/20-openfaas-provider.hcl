job "openfaas-provider" {
  datacenters = ["dc1"]

  type = "system"

  group "provider" {
    count = 1

    network {
      mode= "bridge"
    }

    service {
      name = "openfaas-provider"
      port = 8080

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "statsd-server"
              local_bind_port  = 9125
            }
          }
        }
      }
    }

    task "provider" {
      driver = "docker"

      config {
        image = "quay.io/nicholasjackson/faas-nomad:v0.4.3-rc2"

        args = [
          "-nomad_region", "${NOMAD_REGION}",
          "-nomad_addr", "${attr.unique.network.ip-address}:4646",
          "-consul_addr", "${attr.unique.network.ip-address}:8500",
          "-statsd_addr", "${NOMAD_UPSTREAM_ADDR_statsd_server}", 
          "-node_addr", "${attr.unique.network.ip-address}",
          "-basic_auth_secret_path", "/secrets",
          "-enable_basic_auth=false"
        ]
      }

      resources {
        cpu    = 500
        memory = 128
      }
    }
  }
}
