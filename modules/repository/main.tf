terraform {
  required_providers {
    github = {
      source = "integrations/github"
      version = "~> 6.2"
    }
  }
}

# 1. リポジトリ本体の設定（外部防御を最大化）
resource "github_repository" "repo" {
  name        = var.repo_name
  description = var.description
  visibility  = "public" # 公開リポジトリ

  # --- プロジェクト機能の有効化 ---
  has_issues = true # Issue機能を有効化
  has_wiki   = true # Wiki機能を有効化

  # 外部PRのコード隠蔽を防ぐ（履歴をSquashに1つに潰して、後からの検知・Revertを容易にする）
  allow_merge_commit = false
  allow_squash_merge = true
  allow_rebase_merge = false

  # マージ後に自動でブランチを削除し、不要な残骸を狙われるリスクを減らす
  delete_branch_on_merge = true
}

# 2. メインブランチの保護
resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"

  enforce_admins         = false
  require_signed_commits = true

  # 外部ユーザー（コントリビューター）からのPRには、CIの通過を義務付ける
  dynamic "required_status_checks" {
    for_each = length(var.required_status_checks_contexts) > 0 ? [1] : []
    content {
      strict   = true
      contexts = var.required_status_checks_contexts
    }
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
    dismiss_stale_reviews           = true
  }
}

# 3. GitHub Actionsの実行権限
resource "github_actions_repository_permissions" "actions_limit" {
  repository = github_repository.repo.name
  enabled    = true

  allowed_actions = var.allowed_actions

  dynamic "allowed_actions_config" {
    for_each = var.allowed_actions == "selected" ? [1] : []
    content {
      github_owned_allowed = true
      verified_allowed     = true
    }
  }
}

# 4. Dependabot 脆弱性アラートの有効化
resource "github_repository_vulnerability_alerts" "repo" {
  repository = github_repository.repo.name
  enabled    = true
}

# 5. Dependabot セキュリティアップデートの有効化（脆弱性発見時に自動で修正PRを作成）
resource "github_repository_dependabot_security_updates" "repo" {
  repository = github_repository.repo.name
  enabled    = true
}

# 6. CodeQL (Code Scanning Default Setup) の一律有効化
resource "github_repository_code_scanning_default_setup" "repo" {
  repository  = github_repository.repo.name
  state       = "configured"
  query_suite = "default"
}
