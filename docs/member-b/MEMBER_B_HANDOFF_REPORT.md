# 成员 B 最终交付报告

## 1. 交付结论

成员 B 负责的 MongoDB 副本集与分片集群基础设施已经达到团队交接条件：配置模板、自动化脚本、使用说明、报告初稿和已有实验依据均已提交至 GitHub 分支，并已创建 Pull Request。

本报告中的“完成”特指仓库交付与已有实验主体完成。新增加的自动验收脚本仍需在最终 CentOS 虚拟机保存一次真实 PASS 输出；成员 C 负责的业务集合分片、数据分布和查询对比不属于成员 B 的完成范围。

## 2. GitHub 交付信息

| 项目 | 内容 |
|---|---|
| 仓库 | `kang996t/smart-library-project` |
| 分支 | `member-b-infrastructure` |
| 最新交付提交 | `cdbf88b705c760ae0cd8405c91b759d28410e993` |
| 提交说明 | `Complete Member B replica and sharded cluster deliverables` |
| Pull Request | `#1 Member B: MongoDB Replica Set and Sharded Cluster Infrastructure` |
| 同步验证 | 本地与远端哈希一致，已取得 `PUSH_VERIFIED` |

分支已通过 SSH 方式安全推送。私钥只保存在虚拟机 `/root/.ssh/`，不属于项目交付物，不得复制到仓库或发送给队员。

## 3. 成员 B 已完成内容

### 3.1 任务五：三节点副本集

- 提交 `libraryRS` 三节点配置，端口为 27117、27118、27119。
- 配置独立数据目录、日志、PID、keyfile 内部认证和访问控制。
- 已有证据覆盖 PRIMARY/SECONDARY 拓扑、数据同步、读取偏好、故障转移、节点恢复、节点移除与重新加入、认证成功及未认证拒绝。
- 提交副本集初始化、启动、停止和严格检查脚本。
- 提交自动故障转移演练脚本，可识别 PRIMARY、计算选举耗时并恢复原节点。
- 提交 PyMongo 持续读写探针，用于记录选举窗口中的成功、失败、异常和恢复时间。
- 提交受显式确认变量保护的成员变更演练脚本。

### 3.2 任务六：分片集群基础设施

- 提交 `configRS`、`shard1RS`、`shard2RS` 与 mongos 配置。
- 端口分别为 27219、27211、27212、27200。
- 已有证据覆盖三个副本集组件初始化、mongos 路由身份、管理员认证、两个 Shard 注册、停止与恢复。
- 提交幂等初始化和分片注册脚本。
- 提交带进程身份、用户、配置文件、端口和 ping 校验的启停脚本。
- 提交严格认证验收脚本，用于检查 mongos、Config Server 和两个已注册 Shard。
- 明确 mongos `27200` 是成员 C 后续业务分片实验的统一入口。

### 3.3 安全与可维护性

- Git 中不保存真实管理员密码、keyfile、Token、SSH 私钥、日志、PID 或数据库文件。
- `member-b.env.example` 仅包含占位符。
- 配置安装默认使用 `--dry-run`，正式覆盖前自动备份旧配置。
- 故障转移和副本集重配置均要求显式确认变量，防止误操作。
- 测试写入使用 `library_b_test`，不修改正式业务集合。

## 4. 交付目录

| 路径 | 用途 |
|---|---|
| `config/member-b/replica/` | 三节点副本集配置模板 |
| `config/member-b/sharding/` | Config Server、两个 Shard 与 mongos 配置模板 |
| `config/member-b/member-b.env.example` | 无真实凭据的环境变量示例 |
| `scripts/member-b/` | 初始化、启停、检查、演练及探针脚本 |
| `scripts/member-b/README.md` | 完整运行顺序与安全说明 |
| `docs/member-b/Member_B_Task5_Task6_Evidence.docx` | 已有实验截图与说明 |
| `docs/member-b/REPORT_DRAFT_TASK5_TASK6.md` | 可并入总报告的成员 B 章节 |
| `docs/member-b/TASK5_TASK6_COMPLETION.md` | 完成范围、技术实现与遗留事项 |
| `docs/member-b/MEMBER_B_HANDOFF_CHECKLIST.md` | 团队接手与最终验收清单 |

## 5. 其他成员接手方式

### 5.1 获取成员 B 分支

已有仓库的队员可执行：

```bash
git fetch origin member-b-infrastructure
git switch member-b-infrastructure
git pull --ff-only origin member-b-infrastructure
```

在 PR 合并后，团队统一执行：

```bash
git switch main
git pull --ff-only origin main
```

### 5.2 成员 A 的衔接点

- 应用连接副本集时通过统一连接模块注入包含三个节点、`replicaSet=libraryRS`、`authSource=admin` 和多数写关注的 URI。
- 不在业务代码中硬编码密码或 keyfile。
- 使用 Python 探针日志说明故障转移期间的应用层表现，不笼统声称“完全不中断”。

### 5.3 成员 C 的衔接点

- 通过 mongos `127.0.0.1:27200` 访问分片集群。
- 完成 `smart_library.borrow_logs` 的分片键论证、启用分片和 3000 条记录导入或迁移。
- 提供总分片数、Chunk 数、两个 Shard 文档数、定向查询和跨分片查询的访问分片数与执行耗时。
- 提供 `sh.status()` 及两类 `explain("executionStats")` 截图，填写报告表 6-3。
- 两个 Shard 已注册不等于业务集合已经完成分片，必须提交真实分布证据。

## 6. 最终虚拟机待补证据

以下项目不影响代码和文档交接，但在最终报告宣称“验收通过”前必须完成：

1. 保存 `check_replica.sh` 的 `REPLICA_ACCEPTANCE_PASS` 输出。
2. 并行运行 Python 探针与 `failover_drill.sh`，保存 `ELECTION_SECONDS`、`FAILOVER_DRILL_PASS` 和 `probe_end`。
3. 保存 `member_change_drill.sh` 的 `MEMBER_CHANGE_DRILL_PASS`。
4. 保存 `verify_cluster_acceptance.sh` 的 `SHARDED_CLUSTER_ACCEPTANCE_PASS`。
5. 在无人使用集群时执行一次停止、恢复和再次验收，证明数据目录及分片注册保持不变。
6. 将新增日志和截图编号后补入证据文档与团队报告。

不得用脚本存在代替真实运行结果，也不得虚构表 6-3 的实测数值。

## 7. 当前交付状态

- **仓库交付：完成。**
- **GitHub 分支推送：完成。**
- **Pull Request：已创建，等待 reviewer 审查和合并。**
- **成员 B 配置、脚本和文档：完成。**
- **最终虚拟机新增 PASS 证据：待补。**
- **成员 C 业务分片实验与表 6-3：待成员 C 完成。**

