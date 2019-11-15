job "nats" {
  datacenters = ["dc1"]

  type = "service"

  group "nats" {
    count = 1

    network {
      mode= "bridge"
    }

    service {
      name = "nats"
      port = "4222"

      connect {
        sidecar_service {}
      }
    }

    task "nats" {
      driver = "docker"
      
      config {
        image = "nats-streaming:0.16.2-linux"

        args = [
          "-store", "file", 
          "-dir", "/dev/shm",
          "-m", "8222",
          "-cid","faas-cluster",
        ]

        #port_map {
        #  client = 4222
        #  monitoring = 8222
        #  routing = 6222
        #}
      }

      resources {
        cpu    = 400
        memory = 128
      }
    }
  }
}
