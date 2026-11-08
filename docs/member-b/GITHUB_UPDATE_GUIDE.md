# 成员 B：使用 Xshell、Xftp 更新 GitHub（新手版）

## 1. 本次采用的流程

```text
Windows 已修改文件
        ↓ Xftp
虚拟机中的 Git 仓库 member-b-infrastructure 分支
        ↓ git add / commit / push
GitHub 现有 Pull Request #1
        ↓ 成员 A/C 审核合并
main 分支
```

不要直接向 `main` 推送。本次继续向 `member-b-infrastructure` 分支提交，已有 Pull Request 会自动加入新提交。

## 2. 上传前：在 Xshell 检查仓库

```bash
cd /opt/smart-library-b/handoff/github
pwd
git rev-parse --show-toplevel
git status --short
git branch --show-current
git remote -v
```

必须确认：

- `git rev-parse` 能输出仓库根目录；
- 当前分支为 `member-b-infrastructure`；
- `git status --short` 没有不认识的旧修改。

若当前分支不正确：

```bash
git switch member-b-infrastructure
```

确认工作区干净后，先同步远程同名分支：

```bash
git fetch origin
git pull --rebase origin member-b-infrastructure
```

如果提示冲突，不要继续上传、不要使用 `--force`，先执行 `git status` 并处理冲突。

## 3. 在 Xftp 上传指定文件

Xftp 左侧进入：

```text
C:\Users\GoeQ\Desktop\期末报告\GitHub交接\PR新版\smart-library-project-member-b-infrastructure
```

右侧进入：

```text
/opt/smart-library-b/handoff/github
```

### 3.1 从项目工作目录上传

上传或覆盖以下文件：

```text
README.md
config/member-b/member-b.env.example

docs/member-b/README.md
docs/member-b/TASK5_TASK6_COMPLETION.md
docs/member-b/REPORT_DRAFT_TASK5_TASK6.md
docs/member-b/DELIVERY_CHECKLIST.md
docs/member-b/GITHUB_UPDATE_GUIDE.md

scripts/member-b/README.md
scripts/member-b/requirements.txt
scripts/member-b/member_b_common.sh
scripts/member-b/init_environment.sh
scripts/member-b/install_templates.sh
scripts/member-b/start_replica.sh
scripts/member-b/stop_replica.sh
scripts/member-b/bootstrap_replica.sh
scripts/member-b/check_replica.sh
scripts/member-b/failover_drill.sh
scripts/member-b/member_change_drill.sh
scripts/member-b/replica_failover_probe.py
scripts/member-b/start_cluster.sh
scripts/member-b/stop_cluster.sh
scripts/member-b/bootstrap_sharded_cluster.sh
scripts/member-b/check_cluster.sh
scripts/member-b/verify_cluster_acceptance.sh
```

保持相同目录层级，不要把所有文件堆到仓库根目录。

### 3.2 单独上传最新版证据 Word

项目工作目录中的证据 Word 可能不是最新版。请从以下位置选择最新版：

```text
C:\Users\GoeQ\Desktop\期末报告\Member_B_Task5_Task6_Evidence.docx
```

上传并覆盖到：

```text
/opt/smart-library-b/handoff/github/docs/member-b/Member_B_Task5_Task6_Evidence.docx
```

不要直接拖动整个 `docs/member-b` 文件夹，否则可能用旧 Word 覆盖新证据。

### 3.3 禁止上传

不要上传：

- `replica.key`、`sharding.key`；
- 真实 `.env`；
- MongoDB 管理员密码；
- GitHub Token、SSH 私钥；
- `logs/`、PID 文件、WiredTiger 数据目录；
- `__pycache__/`、临时文件和下载结果。

## 4. 上传后：检查文件与脚本

回到 Xshell：

```bash
cd /opt/smart-library-b/handoff/github
git status --short
git diff --stat
git diff --check
```

给脚本添加可执行权限：

```bash
chmod +x scripts/member-b/*.sh
chmod +x scripts/member-b/replica_failover_probe.py
```

检查所有 Shell 语法：

```bash
for file in scripts/member-b/*.sh; do
    echo "Checking $file"
    bash -n "$file" || exit 1
done
echo "ALL_SHELL_SYNTAX_PASS"
```

检查 Python 语法且不生成缓存：

```bash
python3 -c "p='scripts/member-b/replica_failover_probe.py'; compile(open(p, encoding='utf-8').read(), p, 'exec'); print('PYTHON_SYNTAX_PASS')"
```

检查是否误放敏感文件：

```bash
find . -type f \( -name '*.key' -o -name '.env' -o -name '*.pem' \) -print
```

正常情况下不应输出真实密钥或 `.env`。`member-b.env.example` 是占位示例，可以提交。

## 5. 暂存并复查

只暂存本次成员 B 文件：

```bash
git add README.md
git add config/member-b/member-b.env.example
git add scripts/member-b
git add docs/member-b/README.md
git add docs/member-b/TASK5_TASK6_COMPLETION.md
git add docs/member-b/REPORT_DRAFT_TASK5_TASK6.md
git add docs/member-b/DELIVERY_CHECKLIST.md
git add docs/member-b/GITHUB_UPDATE_GUIDE.md
git add docs/member-b/Member_B_Task5_Task6_Evidence.docx
```

检查暂存结果：

```bash
git status --short
git diff --cached --stat
git diff --cached --check
git diff --cached --name-only
```

如果发现不应提交的文件：

```bash
git restore --staged 文件路径
```

该命令只取消暂存，不删除本地文件。

## 6. 提交并推送

首次提交前可设置身份：

```bash
git config user.name "你的 GitHub 用户名"
git config user.email "你的 GitHub 邮箱"
```

提交：

```bash
git commit -m "Complete Member B replica and sharded cluster deliverables"
```

推送到成员 B 分支：

```bash
git push origin member-b-infrastructure
```

严禁执行：

```text
git push --force
git push origin main
```

如果使用 HTTPS，GitHub 要求用个人访问令牌代替账号密码；令牌只在终端认证时使用，不能写入脚本或配置文件。

## 7. 在 GitHub 页面确认

1. 打开 `kang996t/smart-library-project`。
2. 分支选择 `member-b-infrastructure`。
3. 确认最新提交信息和时间。
4. 打开 Pull requests → PR #1。
5. 检查 Commits 和 Files changed。
6. 确认 base 为 `main`，compare 为 `member-b-infrastructure`。
7. 请求成员 A/C 审核，不要再创建重复 PR。

## 8. 合并后成员 A/C 如何同步

PR 合并进 `main` 后，每位成员在自己的仓库执行：

```bash
git fetch origin
git switch main
git pull origin main
git switch 自己的分支名
git merge main
git push origin 自己的分支名
```

成员 C 随后可以在成员 B 的分片基础设施上完成分片键、3000 条流水分布和查询对比。成员 A 可以更新统一 README、连接模块和最终集成内容。

## 9. Git 更新不等于运行环境更新

`git pull` 只更新仓库文件，不会自动改变 `/opt/smart-library-b/config` 中正在使用的配置，也不会删除 MongoDB 数据。

需要安装仓库配置模板时，先预览：

```bash
cd /opt/smart-library-b/handoff/github
sudo bash scripts/member-b/install_templates.sh --dry-run
```

确认无误再应用：

```bash
sudo bash scripts/member-b/install_templates.sh --apply
```

脚本会备份旧配置。已有集群运行正常时，不要在未与 A/C 协调的情况下停止或重新初始化集群。

成员 C 在虚拟机内应通过 mongos 访问：

```bash
/export/servers/mongosh-2.12.0/bin/mongosh \
  --host 127.0.0.1 \
  --port 27200 \
  -u shardingAdmin \
  --authenticationDatabase admin \
  --password
```

密码在提示时输入，不要把密码写进命令历史、截图或 GitHub。
