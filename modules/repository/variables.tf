variable "repo_name" {
  type        = string
  description = "GitHubリポジトリ名"
}

variable "description" {
  type        = string
  description = "リポジトリの説明文"
  default     = ""
}
