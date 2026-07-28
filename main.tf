terraform {
  # import ブロックでの for_each サポートのため v1.7.0 以上を指定
  required_version = ">= 1.7.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # GitHub Actionsでステートを永続化するためのリモートバックエンド設定
  cloud {
    organization = "ciderlabs" # HCP Terraformで作成した組織名
    workspaces {
      name = "manage-repos" # ワークスペース名
    }
  }
}

provider "github" {
  # GITHUB_TOKEN は環境変数から自動読み込み
}

# 1. GitHub Variables から JSON 文字列で受け取る変数定義
variable "repositories" {
  type        = string
  description = "JSON string containing repository configurations"
}

# 2. 受け取った JSON 文字列をパースして locals 化
locals {
  repositories_list = jsondecode(var.repositories)
  repositories_map  = { for repo in local.repositories_list : repo.name => repo }
}

# 3. 既存のリポジトリを自動でStateに取り込むインポート設定 (Terraform 1.7+)
import {
  for_each = local.repositories_map
  to       = module.github_repositories[each.key].github_repository.repo
  id       = each.key
}

# 4. ループ処理でモジュール呼び出し
module "github_repositories" {
  source   = "./modules/repository"
  for_each = local.repositories_map

  repo_name   = each.value.name
  description = lookup(each.value, "description", "")
  # JSON側で指定があればそれを使い、無ければデフォルトを使う
  allowed_actions                 = lookup(each.value, "allowed_actions", null)
  required_status_checks_contexts = lookup(each.value, "required_status_checks_contexts", null)
}
