terraform {
  required_version = ">= 1.5.0"

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
}

# 3. ループ処理でモジュール呼び出し
module "github_repositories" {
  source   = "./modules/repository"
  for_each = { for repo in local.repositories_list : repo.name => repo }

  repo_name   = each.value.name
  description = lookup(each.value, "description", "")
}
