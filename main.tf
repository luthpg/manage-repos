terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "github" {
  # DockerのSecret機能でマウントされたパスからトークンを安全に読み込む
  token = trimspace(file("/run/secrets/github_token"))
}

# 1. YAMLファイルを読み込んでパースする
locals {
  yaml_data = yamldecode(file("${path.module}/repositories.yaml"))
}

# 2. ループ処理で防御モジュールを呼び出す
module "github_repositories" {
  source   = "./modules/repository"
  for_each = { for repo in local.yaml_data : repo.name => repo }

  repo_name   = each.value.name
  description = each.value.description
}
