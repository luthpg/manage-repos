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

# 2. メインブランチの保護（自分への制限は緩く、外部からの攻撃は鉄壁に）
resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"

  # 管理者の誤操作防止は最低限（自分は直接Pushやテスト未完了マージが可能）
  enforce_admins = false

  # 外部からの「なりすましコミット」をマージ不可にする（署名必須）
  require_signed_commits = true

  # 外部ユーザー（コントリビューター）からのPRには、CIの通過を義務付ける
  # リスト要素数が0より大きい場合のみ、CIチェック必須ルールを適用する
  dynamic "required_status_checks" {
    for_each = length(var.required_status_checks_contexts) > 0 ? [1] : []
    content {
      strict   = true
      contexts = var.required_status_checks_contexts
    }
  }

  # 自分自身の開発スピードを落とさないため、マージに必要な「承認数」は0にする
  required_pull_request_reviews {
    required_approving_review_count = 0
    # ただし外部がPR作成後にコードをこっそり書き換えた（追記した）場合、レビュー状態を強制リセット
    dismiss_stale_reviews = true
  }
}

# 3. GitHub Actionsの実行権限を厳格化（不正ランナー利用・トークン奪取対策）
resource "github_actions_repository_permissions" "actions_limit" {
  repository = github_repository.repo.name
  enabled    = true

  # 許可された安全なアクション（公式や検証済み組織）だけを実行可能にする
  allowed_actions = var.allowed_actions

  # allowed_actions が "selected" の場合のみ設定を適用
  dynamic "allowed_actions_config" {
    for_each = var.allowed_actions == "selected" ? [1] : []
    content {
      github_owned_allowed = true # GitHub公式のアクションのみ許可
      verified_allowed     = true # Marketplaceの認証済み組織のみ許可
    }
  }
}

# 4. 脆弱性アラートを有効化
resource "github_repository_vulnerability_alerts" "repo" {
  repository = github_repository.repo.name
  enabled    = true
}
