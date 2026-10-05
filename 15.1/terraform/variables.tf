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

