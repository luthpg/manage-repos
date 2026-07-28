variable "repo_name" {
  type        = string
  description = "GitHubリポジトリ名"
}

variable "description" {
  type        = string
  description = "リポジトリの説明文"
  default     = ""
}

variable "required_status_checks_contexts" {
  type        = list(string)
  description = "PRマージ前に必須とするCIのステータスチェック名"
  default     = ["build-and-test"]
}

# Actionsの制限レベル ("all", "local_only", "selected")
variable "allowed_actions" {
  type        = string
  description = "GitHub Actionsの実行制限レベル"
  default     = "all" # pnpmセットアップアクションのため、デフォルトallに設定

  validation {
    condition     = contains(["all", "local_only", "selected"], var.allowed_actions)
    error_message = "allowed_actions must be one of: 'all', 'local_only', 'selected'."
  }
}
