# Keycloak-chart

A Helm chart that integrates the **official Keycloak Operator** with the
**Zalando Postgres Operator**, providing a production-ready, operator-managed
Keycloak identity platform backed by a highly-available PostgreSQL cluster.

## Overview

| Component | Project | Version |
|-----------|---------|---------|
| Keycloak Operator | [keycloak/keycloak-k8s-resources](https://www.keycloak.org/operator/installation) | 26.0.0 |
| Postgres Operator | [zalando/postgres-operator](https://github.com/zalando/postgres-operator) | 1.12.2 |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Kubernetes Cluster                                          │
│                                                             │
│  ┌───────────────────┐    ┌──────────────────────────────┐  │
│  │  Keycloak Operator │    │   Zalando Postgres Operator  │  │
│  │  (reconciles      │    │   (reconciles postgresql CRs)│  │
│  │   Keycloak CRs)   │    └──────────────┬───────────────┘  │
│  └────────┬──────────┘                   │                  │
│           │ manages                      │ manages          │
│  ┌────────▼──────────┐    ┌──────────────▼───────────────┐  │
│  │  Keycloak         │───▶│   PostgreSQL Cluster         │  │
│  │  (k8s.keycloak.   │ db │   (acid.zalan.do/v1)         │  │
│  │   org/v2alpha1)   │    │   keycloak-keycloak-db       │  │
│  └───────────────────┘    └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

* Kubernetes 1.26+
* Helm 3.12+
* The Keycloak Operator and Postgres Operator CRDs installed on the cluster
  (handled automatically when the operator sub-charts are enabled)

## Installing the Chart

### 1 – Fetch dependencies

```bash
helm dependency update keycloak-custom/
```

> **Note:** The `charts/` directory contains lightweight stub charts that allow
> `helm lint` and `helm template` to work offline. Running
> `helm dependency update` replaces them with the real operator charts from
> their upstream registries.

### 2 – Create the admin secret

The Keycloak Operator requires a secret with initial admin credentials:

```bash
kubectl create secret generic keycloak-admin-secret \
  --from-literal=username=admin \
  --from-literal=password='<your-password>' \
  -n <namespace>
```

### 3 – Install the chart

```bash
helm install my-keycloak ./keycloak-custom \
  --namespace keycloak \
  --create-namespace \
  --set keycloak.hostname.hostname=keycloak.example.com
```

## Configuration

Below are the most important values. See [`values.yaml`](keycloak-custom/values.yaml)
for a full reference.

### Global

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Override the deployment namespace | `""` (release namespace) |

### Keycloak Operator

| Parameter | Description | Default |
|-----------|-------------|---------|
| `keycloak-operator.enabled` | Install the Keycloak Operator sub-chart | `true` |

### Postgres Operator

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgres-operator.enabled` | Install the Zalando Postgres Operator sub-chart | `true` |

### PostgreSQL Cluster

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Create the `postgresql` CR | `true` |
| `postgresql.teamId` | Zalando team identifier | `keycloak` |
| `postgresql.clusterName` | Cluster name suffix | `keycloak-db` |
| `postgresql.numberOfInstances` | Number of Postgres replicas | `2` |
| `postgresql.version` | PostgreSQL major version | `"16"` |
| `postgresql.volume.size` | PVC size per instance | `5Gi` |
| `postgresql.database` | Database name for Keycloak | `keycloak` |
| `postgresql.user` | Database user for Keycloak | `keycloak` |

### Keycloak

| Parameter | Description | Default |
|-----------|-------------|---------|
| `keycloak.enabled` | Create the `Keycloak` CR | `true` |
| `keycloak.instances` | Number of Keycloak pods | `2` |
| `keycloak.image.repository` | Keycloak image | `quay.io/keycloak/keycloak` |
| `keycloak.image.tag` | Image tag | chart `appVersion` |
| `keycloak.hostname.hostname` | Public hostname | `""` |
| `keycloak.http.httpEnabled` | Enable plain HTTP | `true` |
| `keycloak.http.tlsSecret` | TLS secret name (disables HTTP) | `""` |
| `keycloak.proxy.headers` | Proxy header mode | `xforwarded` |
| `keycloak.adminSecret` | Secret containing admin credentials | `keycloak-admin-secret` |

## Credentials Flow

The Zalando Postgres Operator automatically generates a PostgreSQL credential
secret named:

```
<user>.<teamId>-<clusterName>   (e.g. keycloak.keycloak-keycloak-db)
```

This chart creates a bridge secret (`keycloak-db-secret` by default) that
Keycloak uses to connect to the database. When deploying against a live
cluster, the bridge secret is populated from the operator-generated secret
via a Helm lookup. For `helm template` output a placeholder value is used.

## Uninstalling

```bash
helm uninstall my-keycloak -n keycloak
```

> Persistent volume claims created by the Postgres Operator are **not**
> deleted automatically. Remove them manually if needed:
> `kubectl delete pvc -l application=spilo -n keycloak`

## License

[MIT License](LICENSE)
