variable "repo_name" {
  type        = string
  description = "GitHubリポジトリ名"
}

variable "description" {
  type        = string
  description = "リポジトリの説明文"
  default     = ""
  nullable    = false
}

variable "required_status_checks_contexts" {
  type        = list(string)
  description = "PRマージ前に必須とするCIのステータスチェック名"
  default     = ["build-and-test"]
  nullable    = false
}

# Actionsの制限レベル ("all", "local_only", "selected")
variable "allowed_actions" {
  type        = string
  description = "GitHub Actionsの実行制限レベル"
  default     = "all" # pnpmセットアップアクションのため、デフォルトallに設定
  nullable    = false

  validation {
    condition     = contains(["all", "local_only", "selected"], var.allowed_actions)
    error_message = "allowed_actions must be one of: 'all', 'local_only', 'selected'."
  }
}

variable "homepage_url" {
  type        = string
  description = "リポジトリのWebサイトURL（手動指定）"
  default     = null
}

variable "use_github_pages" {
  type        = bool
  description = "GitHub PagesのデフォルトURLを自動割り当てするかどうか"
  default     = false
  nullable    = false
}

variable "owner" {
  type        = string
  description = "GitHubの組織名またはユーザー名"
  default     = "ciderlabs"
}
