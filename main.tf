terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.13.1"
    }
  }
}

locals {
  port = 5432
  app  = "postgres"
  match_labels = {
    "app.kubernetes.io/name"     = "postgres"
    "app.kubernetes.io/instance" = "postgres"
  }
  labels = merge(local.match_labels, var.labels)
  env    = "postgres-env"
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = var.stateful_set_name
    namespace = var.namespace
    labels    = local.labels
  }
  spec {
    selector {
      match_labels = local.labels
    }
    service_name = local.app
    replicas     = local.replicas
    template {
      metadata {
        labels = local.labels
      }
      spec {
        affinity {
          pod_affinity {}
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              pod_affinity_term {
                label_selector {
                  match_labels = local.match_labels
                }
                namespaces   = [var.namespace]
                topology_key = "kubernetes.io/hostname"
              }
              weight = 1
            }
          }
          node_affinity {}
        }
        security_context {
          fs_group = 1001
        }
        container {
          image = var.image_registry == "" ? "${var.image_repository}:${var.image_tag}" : "${var.image_registry}/${var.image_repository}:${var.image_tag}"
          name  = var.container_name
          env_from {
            config_map_ref {
              name = kubernetes_config_map.postgres.metadata.0.name
            }
          }
          env {
            name = "POSTGRES_POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata.0.name
                key  = "postgres-postgres-password"
              }
            }
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata.0.name
                key  = "postgres-password"
              }
            }
          }
          port {
            name           = "tcp-postgres"
            container_port = local.port
          }
          liveness_probe {
            exec {
              command = ["/bin/sh", "-c", "exec pg_isready -U ${var.postgres_user} -d \"dbname=${var.postgres_db}\" -h 127.0.0.1 -p ${local.port}"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 1
          }
          readiness_probe {
            exec {
              command = [
                "/bin/sh",
                "-c",
                "-e",
                <<EOT
                |
                exec pg_isready -U ${var.postgres_user} -d \"dbname=${var.postgres_db}\" -h 127.0.0.1 -p ${local.port}
                [ -f /opt/bitnami/postgresql/tmp/.initialized ] || [ -f /bitnami/postgresql/.initialized ]
                EOT
              ]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 1
          }
          volume_mount {
            name       = "dshm"
            mount_path = "/dev/shm"
          }
          volume_mount {
            name       = "data"
            mount_path = "/bitnami/postgresql"
          }
        }
        volume {
          name = "dshm"
          empty_dir {
            medium     = "Memory"
            size_limit = "1Gi"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.storage_size
          }
        }
        storage_class_name = var.storage_class_name
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = var.service_name
    namespace = var.namespace
    labels = merge({
      "service.alpha.kubernetes.io/tolerate-unready-endpoints" = "true"
    }, local.labels)
  }
  spec {
    type                        = var.service_type
    publish_not_ready_addresses = true
    selector                    = local.match_labels
    port {
      port = local.port
    }
  }
  count = var.enable_service ? 1 : 0
}

resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres"
    namespace = local.namespace
    labels    = local.match_labels
  }
  type = "Opaque"
  data = {
    "postgres-postgres-password" = var.postgres_postgres_password
    "postgres-password"          = var.postgres_password
  }
}

resource "kubernetes_config_map" "postgres" {
  metadata {
    name      = local.env
    namespace = var.namespace
  }

  data = {
    BITNAMI_DEBUG                       = "false"
    POSTGRESQL_PORT_NUMBER              = local.port
    POSTGRESQL_VOLUME_DIR               = "/bitnami/postgresql"
    PGDATA                              = "/bitnami/postgresql/data"
    POSTGRES_USER                       = var.postgres_user
    POSTGRES_DB                         = var.postgres_db
    POSTGRESQL_ENABLE_LDAP              = "no"
    POSTGRESQL_LOG_HOSTNAME             = "false"
    POSTGRESQL_LOG_DISCONNECTIONS       = "false"
    POSTGRESQL_PGAUDIT_LOG_CATALOG      = "off"
    POSTGRESQL_CLIENT_MIN_MESSAGES      = "error"
    POSTGRESQL_SHARED_PRELOAD_LIBRARIES = "pgaudit"
  }
}
