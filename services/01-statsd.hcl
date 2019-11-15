job "statsd" {
  datacenters = ["dc1"]

  type = "service"

  group "statsd" {
    count = 1

    network {
      mode= "bridge"

      port "http" {
        to=9102
      }
    }

    service {
      name = "statsd-server"
      port = "9125"

      connect {
        sidecar_service {}
      }
    }

    service {
      name = "statsd"
      port = "http"
      tags = ["prometheus"]
    }

    task "statsd" {
      driver = "docker"

      config {
        image = "prom/statsd-exporter:v0.12.2"

        args = [
          "--log.level=debug",
        ]
      }

      resources {
        cpu    = 100
        memory = 36
      }
    }
  }
}
