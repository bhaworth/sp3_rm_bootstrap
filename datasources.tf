# Random string
resource "random_string" "deploy_id" {
  length  = 5
  special = false
  upper   = false
  number  = false
}

data "template_cloudinit_config" "headnode" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.headnode_cloud_init.rendered
  }
}
data "template_file" "headnode_cloud_init" {
  template = file("${path.module}/scripts/headnode-cloud-config.template.yaml")

  vars = {
    bootstrap_root_sh_content   = base64gzip(data.template_file.bootstrap_root.rendered)
    bootstrap_ubuntu_sh_content = base64gzip(data.template_file.bootstrap_ubuntu.rendered)
    stack_info_content          = base64gzip(data.template_file.stack_info.rendered)
    install_sp3_sh_content      = base64gzip(data.template_file.install_sp3.rendered)
    inject_pub_keys_sh_content  = base64gzip(data.template_file.inject_pub_keys.rendered)
    install_nginx_sh_content    = base64gzip(data.template_file.install_nginx.rendered)
  }
}

data "template_cloudinit_config" "bastion" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.bastion_cloud_init.rendered
  }
}
data "template_file" "bastion_cloud_init" {
  template = file("${path.module}/scripts/bastion-cloud-config.template.yaml")

  vars = {
    inject_pub_keys_sh_content = base64gzip(data.template_file.inject_pub_keys.rendered)
  }
}

data "template_file" "bootstrap_root" {
  template = file("${path.module}/scripts/bootstrap_root.sh")
}
data "template_file" "bootstrap_ubuntu" {
  template = file("${path.module}/scripts/bootstrap_ubuntu.sh")

  # Variables parsed into bootstrap_ubuntu.sh as it is encoded in to Cloud-Init
  vars = {
    deployment_id = local.Sp3_deploy_id
    tenancy_id    = var.tenancy_ocid
  }
}

data "template_file" "stack_info" {
  template = file("${path.module}/scripts/stack_info.json")

  # Variables parsed into stack_info.json as it is encoded in to Cloud-Init
  vars = {
    deployment_id      = local.Sp3_deploy_id
    compartment_id     = local.Sp3_cid
    tenancy_id         = var.tenancy_ocid
    load_balancer_id   = local.Sp3_lb_id
    sp3_url            = local.Sp3_lb_url
    priv_subnet_id     = local.Privsn001_id
    ad                 = var.ad
    worker_shape       = var.worker_shape
    worker_image       = var.worker_image
    worker_ocpus       = local.is_flexible_worker_shape ? var.worker_ocpus : 0
    worker_ram         = local.is_flexible_worker_shape ? var.worker_ram : 0
    worker_min         = var.worker_min
    worker_max         = var.worker_max
    worker_use_scratch = var.worker_use_scratch
  }
}

data "template_file" "install_sp3" {
  template = file("${path.module}/scripts/install_sp3.sh")

  vars = {
    Sp3_gitrepo_secret_id = local.Sp3_gitrepo_secret_id
  }
}

data "template_file" "inject_pub_keys" {
  template = file("${path.module}/scripts/inject_pub_keys.sh")
}

data "template_file" "install_nginx" {
  template = file("${path.module}/scripts/install_nginx.sh")

  vars = {
    install_certs            = var.install_certs
    Sp3dev_ml_ssl_secret_id  = local.Sp3dev_ml_ssl_secret_id
    Sp3dev_ml_priv_secret_id = local.Sp3dev_ml_priv_secret_id
    Sp3_env_name             = local.Sp3_env_name
  }
}

locals {
  is_flexible_worker_shape = contains(local.compute_flexible_shapes, var.worker_shape)
}
