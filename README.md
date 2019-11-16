# OpenFAAS on Hashistack

This is a reference for running OpenFAAS on Consul+Nomad.

## Instructions 

This is for running local.

### Installation

With the Makefile you can install consul, nomad and cni plugins (needed for nomad network namespace and consul connect). They will be installed system-wide.

```sh
make install-consul intall-cni install-nomad
```

### Starting

You can them start consul:

```sh
make start-consul
```

And after that start nomad:

```sh
make start-nomad
```
### Deploying OpenFaas

OpenFaas is composed of several parts, they are all described in services folder in order of priority. 

To reploy all services:

```sh
make start-services
```

To re-deploy a single service on Nomad:

```sh
nomad job run services/00-prometheus.hcl
```

And so on for each service, in order.

### Accessing

You can access the gateway at [http://localhost/gateway/ui] and grafana at [http://localhost/grafana].

## License

MIT
