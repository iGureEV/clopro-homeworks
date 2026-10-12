variable "service_account_key_file" {
  default = "/home/geolook/.ssh/key.json"
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
}

variable "zone" {
  default = "ru-central1-a"
}

variable "sa_access_key" {
  description = "Static access key ID (key_id) для Object Storage"
}

variable "sa_secret_key" {
  description = "Static access key secret для Object Storage"
}

variable "bucket_name" {
  description = "Глобально уникальное имя бакета"
}

