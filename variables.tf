variable "postgres_postgres_password" {
  description = "Password for the `postgres` user"
  type        = string
  sensitive   = true
}

variable "postgres_user" {
  description = "Username for the user"
  default     = "user"
  type        = string
}

variable "postgres_password" {
  description = "Password for the user"
  type        = string
  sensitive   = true
}

variable "postgres_db" {
  description = "Name of the default database"
  type        = string
  sensitive   = true
}

variable "stateful_set_name" {
  description = "Name of StatefulSet"
  type        = string
  default     = "postgres"
}

variable "labels" {
  description = "Labels to add to the Postgres deployment"
  type        = map(any)
  default     = {}
}

variable "volum_claim_template_name" {
  description = "Name to use for the volume claim template"
  type        = string
  default     = "postgres-pvc"
}

variable "replicas" {
  description = "Replicas to deploy in the Postgres StatefulSet"
  type        = number
  default     = 1
}

variable "storage_size" {
  description = "Storage size for the StatefulSet PVC"
  type        = string
  default     = "10Gi"
}

variable "storage_class_name" {
  description = "Storage class to use for Postgres PVCs"
  type        = string
  default     = ""
}

variable "image_registry" {
  description = "Image registry, e.g. gcr.io, docker.io"
  type        = string
  default     = ""
}

variable "image_repository" {
  description = "Image to start for this pod"
  type        = string
  default     = "bitnami/postgresql"
}

variable "image_tag" {
  description = "Image tag to use"
  type        = string
  default     = "13.9.0"
}

variable "container_name" {
  description = "Name of the Postgres container"
  type        = string
  default     = "postgres"
}

variable "enable_service" {
  description = "Enable service for Postgres"
  type        = bool
  default     = true
}

variable "service_name" {
  description = "Name of service to deploy"
  type        = string
  default     = "postgres"
}

variable "service_type" {
  description = "Type of service to deploy"
  type        = string
  default     = "ClusterIP"
}
