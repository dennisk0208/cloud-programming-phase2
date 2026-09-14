variable "project_name" {
  type        = string
  default     = "dkphase2"
  description = "Projektname für Ressourcenbenennung"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Deployment-Umgebung"
}

variable "location" {
  type        = string
  default     = "germanywestcentral"
  description = "Azure Region prod"
}