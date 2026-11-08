# 成员 B 交付与团队接手清单

使用说明：`[x]` 表示已有提交或记录可以证明；`[ ]` 表示接收人仍需执行、确认或补充。运行验证项只有在看到对应 PASS 标记后才能勾选。

## 一、成员 B 已交付

- [x] 三节点 `libraryRS` 配置模板已提交。
- [x] 副本集初始化、启动、停止和检查脚本已提交。
- [x] 故障转移、成员变更和 Python 持续读写探针已提交。
- [x] Config Server、Shard 1、Shard 2 和 mongos 配置已提交。
- [x] 分片集群初始化、注册、启停、健康检查和严格验收脚本已提交。
- [x] 配置示例不包含真实密码、Token、keyfile 或 SSH 私钥。
- [x] 使用说明、完成说明、报告初稿和证据 Word 文档已提交。
- [x] 最新提交为 `cdbf88b705c760ae0cd8405c91b759d28410e993`。
- [x] 本地与 GitHub 远端提交一致，已取得 `PUSH_VERIFIED`。
- [x] Pull Request `#1` 已创建且当前可合并。

## 二、PR 审查与合并

- [ ] Reviewer `kang996t` 检查 PR 的 32 个变更文件。
- [ ] 确认仓库中没有真实密码、Token、私钥或数据库数据文件。
- [ ] 确认成员 B 的任务边界未包含成员 C 的业务分片实验。
- [ ] Reviewer 批准 PR。
- [ ] 将 PR `#1` 合并到 `main`。
- [ ] 合并后各成员执行 `git switch main` 和 `git pull --ff-only origin main`。

## 三、最终虚拟机验收

- [ ] `check_replica.sh` 输出 `REPLICA_ACCEPTANCE_PASS`。
- [ ] Python 探针与故障转移脚本并行运行。
- [ ] 日志包含 `ELECTION_SECONDS`。
- [ ] 故障转移脚本输出 `FAILOVER_DRILL_PASS`。
- [ ] Python 探针输出最终 `probe_end` 汇总。
- [ ] `member_change_drill.sh` 输出 `MEMBER_CHANGE_DRILL_PASS`。
- [ ] `verify_cluster_acceptance.sh` 输出 `SHARDED_CLUSTER_ACCEPTANCE_PASS`。
- [ ] 停止并恢复分片集群后再次输出 `SHARDED_CLUSTER_ACCEPTANCE_PASS`。
- [ ] 新运行日志保存在仓库外的证据目录，避免误提交密码或临时文件。

## 四、成员 A 接手确认

- [ ] 从统一连接模块切换到 `libraryRS` URI。
- [ ] URI 包含三个节点、`replicaSet=libraryRS`、认证库、读取偏好、重试写入和多数写关注。
- [ ] 真实凭据通过环境变量注入，不写入源代码。
- [ ] 结合探针日志说明选举窗口中的失败次数、异常类型和恢复时间。

## 五、成员 C 接手确认

- [ ] 通过 mongos 端口 `27200` 访问分片集群。
- [ ] 完成 `smart_library.borrow_logs` 分片键主方案和备选方案论证。
- [ ] 启用集合分片并确认共有 3000 条借阅流水。
- [ ] 提供总分片数量和 Chunk 总数量。
- [ ] 提供 Shard1 和 Shard2 的真实文档数量或 Chunk 分布证据。
- [ ] 提供定向查询的访问分片数和 `executionTimeMillis`。
- [ ] 提供跨分片查询的访问分片数和 `executionTimeMillis`。
- [ ] 提供 `sh.status()` 输出截图。
- [ ] 提供两类查询的 `explain("executionStats")` 截图。
- [ ] 使用真实数值填写表 6-3，不使用预计值。

## 六、最终报告整合

- [ ] 将 `REPORT_DRAFT_TASK5_TASK6.md` 合并到团队正文。
- [ ] 将新增 PASS 输出和日志摘要补入证据文档。
- [ ] 统一数据库名、集合名、端口、副本集名和图号。
- [ ] 删除重复截图和重复题注。
- [ ] 写明单成员 Config Server/Shard 是课程实验方案，不是生产级高可用架构。
- [ ] 成员 A、B、C 共同检查最终报告页数、任务分工和证据引用。

## 七、安全收尾

- [ ] 确认此前截图中暴露的 Personal Access Token 已在 GitHub 删除。
- [x] SSH 私钥权限为 `600`，公钥权限为 `644`。
- [ ] 确认 `/root/.ssh/id_ed25519_github` 未复制到仓库或共享目录。
- [ ] 项目完成后按团队需要保留或删除 GitHub SSH Key。

## 交接签收

| 角色 | 姓名 | 确认内容 | 日期 |
|---|---|---|---|
| 成员 A |  | 应用连接与报告整合 |  |
| 成员 B |  | 基础设施交付与验收证据 |  |
| 成员 C |  | 业务分片实验与表 6-3 |  |
| Reviewer |  | PR 审查与合并 |  |

