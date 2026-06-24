1. 運用の流れ事前に ~/.secrets/github_token.txt にトークンを書き込んでおきます。

2. 以下のコマンドで検証と適用を行います。

```bash
# 初期化
docker compose run --rm terraform init

# 差分確認
docker compose run --rm terraform plan

# 適用
docker compose run --rm terraform
```
