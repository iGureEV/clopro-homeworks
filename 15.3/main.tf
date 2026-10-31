resource "yandex_vpc_network" "net" {
  name = "net"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}


resource "yandex_storage_bucket" "images" {
  bucket     = var.bucket_name
  access_key = var.sa_access_key
  secret_key = var.sa_secret_key
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_bucket_grant" "images_public" {
  bucket     = yandex_storage_bucket.images.bucket
  access_key = var.sa_access_key
  secret_key = var.sa_secret_key

  grant {
    uri         = "http://acs.amazonaws.com/groups/global/AllUsers"
    permissions = ["READ"]
    type        = "Group"
  }
}

resource "yandex_storage_object" "picture" {
  bucket       = yandex_storage_bucket.images.bucket
  key          = "picture.png"
  source       = "assets/picture.png"
  content_type = "image/png"
  acl          = "public-read"
  access_key   = var.sa_access_key
  secret_key   = var.sa_secret_key
  depends_on   = [yandex_storage_bucket_grant.images_public]
}



resource "yandex_compute_instance_group" "lamp" {
  name               = "lamp-group"
  folder_id          = var.folder_id
  service_account_id = "ajek12cfv1r2h6nhqov2"

  instance_template {
    platform_id = "standard-v2"

    resources {
      cores         = 2
      memory        = 2
      core_fraction = 20
    }

    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
      }
    }

    network_interface {
      network_id = yandex_vpc_network.net.id
      subnet_ids = [yandex_vpc_subnet.public.id]
      nat        = true
    }

    metadata = {
      ssh-keys  = "ubuntu:${file("/home/geolook/.ssh/id_rsa.pub")}"
      user-data = file("cloud-init.yaml")
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 3
    max_expansion   = 1
    max_deleting    = 1
  }

  load_balancer {
    target_group_name = "lamp-tg"
  }

  health_check {
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    http_options {
      port = 80
      path = "/"
    }
  }
}

resource "yandex_lb_network_load_balancer" "lb" {
  name = "net-lb"

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.lamp.load_balancer[0].target_group_id

    healthcheck {
      name = "health"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}



resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "bucket-encryption-key"
  description       = "Ключ KMS для бакета Object Storage"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_kms" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${var.sa_id}"
}
