# 成员 B：任务五与任务六基础设施完成说明

## 1. 核对范围与结论

本说明依据原始项目任务书、团队分工、成员 A/C 的任务三与任务四交付、成员 B 的实验截图，以及当前仓库中的配置和脚本进行核对。

结论如下：

- 任务五的数据库实验主体已经完成，现有证据覆盖三节点副本集、数据同步、读取偏好、故障转移、节点恢复、节点移除与重新加入、认证和未认证访问拒绝。
- 任务五原先最明显的缺口是缺少可重复执行的副本集生命周期脚本、自动记录选举耗时的故障演练脚本，以及驱动层持续读写记录。仓库现已补充这些交付物。
- 任务六中成员 B 负责的基础设施主体已经完成，现有证据覆盖 Config Server、Shard 1、Shard 2、mongos、管理员认证、双分片注册、停止与恢复。
- 任务六原先缺少从“仅启动已有数据目录”到“首次初始化并注册双分片”的幂等化脚本，以及带认证的严格验收脚本。仓库现已补充。
- 分片键论证、`borrow_logs` 启用分片、3000 条流水分布验证及定向/跨分片查询对比属于成员 C 的任务六后半部分，不应作为成员 B 已完成内容重复申报。

## 2. 与成员 A/C 交付的衔接

成员 A/C 的阶段文档确认：

- 正式数据库为 `smart_library`，基础数据规模为 books 50 条、readers 30 条、borrow_logs 3000 条。
- 单机实例端口为 27018，Python 应用使用统一连接模块，不在业务代码中硬编码连接串。
- 应用已经包含图书、读者、借阅、统计、审计和 GridFS 模块。
- GridFS 6 个文件的上传、查询、下载和字节数校验已经完成。

成员 B 在副本集阶段不应重新设计 A/C 的业务集合或 GridFS 结构。应用切换到副本集时，只需由统一连接层改用包含三个节点、`replicaSet=libraryRS`、认证库、读取偏好、重试写入和多数写关注的 URI。

建议的连接形式：

```text
mongodb://USER:PASSWORD@HOST:27117,HOST:27118,HOST:27119/
  ?replicaSet=libraryRS
  &authSource=admin
  &readPreference=secondaryPreferred
  &retryWrites=true
  &w=majority
```

实际使用时应写成一行并通过 `.env` 注入，不能把真实凭据提交到 Git。

## 3. 任务五完成项

### 3.1 拓扑与配置

副本集名称为 `libraryRS`：

| 节点 | 端口 | Priority | 数据目录 |
|---|---:|---:|---|
| Node 1 | 27117 | 2 | `/opt/smart-library-b/replica/node1` |
| Node 2 | 27118 | 1 | `/opt/smart-library-b/replica/node2` |
| Node 3 | 27119 | 1 | `/opt/smart-library-b/replica/node3` |

三个节点均绑定 `127.0.0.1`，启用 `libraryRS`、keyfile 内部认证和访问控制。现有截图显示 Node 1 为 PRIMARY、Node 2/3 为 SECONDARY，并已验证三节点端口和 ping。

### 3.2 数据同步与读取偏好

现有证据包括：

- PRIMARY 中测试集合的数据修复和唯一索引创建；
- Node 2、Node 3 上读取到相同测试数据；
- `primary` 读取偏好连接到主节点；
- `secondaryPreferred` 读取偏好能够从从节点读取；
- 节点恢复和重新加入后数据、索引及测试写入记录保持一致。

### 3.3 故障转移与恢复

现有证据覆盖故障前拓扑、原 PRIMARY 停止、新 PRIMARY 产生、原始数据读取、多数写入恢复、原节点重启和同步恢复。为了让过程可复现，新增 `failover_drill.sh`：

1. 自动识别当前 PRIMARY；
2. 输出故障开始 UTC 时间；
3. 只停止与目标配置文件匹配的 `mongod` 进程；
4. 轮询新 PRIMARY，并输出 `ELECTION_SECONDS`；
5. 在 `library_b_test.failover_evidence` 执行多数写入和读取；
6. 恢复原节点并等待其成为 SECONDARY。

### 3.4 应用层业务影响

原证据主要证明 mongosh 在切换后能够继续读写，但不足以单独证明 Python 驱动在选举窗口内的表现。新增 `replica_failover_probe.py`，用于在故障演练期间持续执行：

- `hello` 主节点发现；
- 多数写关注的 upsert；
- 立即读取验证；
- 成功、失败、异常类型和单次延迟的 JSONL 记录。

该探针只写入 `library_b_test.infrastructure_probe`，不会修改正式业务集合。实际交付时需在 CentOS 环境运行一次，并把 `probe_start`、选举窗口内的记录和 `probe_end` 作为应用影响证据。

### 3.5 节点增删与认证

现有截图已经覆盖 Node 3 移除、进程重启、重新加入和三节点恢复。新增 `member_change_drill.sh` 以固定复现顺序，并要求显式设置 `ALLOW_RS_RECONFIG=YES`，避免误操作。

副本集配置启用了 keyfile 和 `authorization: enabled`。现有截图还证明管理账号能够认证、未认证的 `listDatabases` 被拒绝。

## 4. 任务六基础设施完成项

### 4.1 拓扑

| 组件 | 副本集/角色 | 端口 | 数据目录或入口 |
|---|---|---:|---|
| Config Server | `configRS` | 27219 | `/opt/smart-library-b/sharding/configsvr` |
| Shard 1 | `shard1RS` | 27211 | `/opt/smart-library-b/sharding/shard1` |
| Shard 2 | `shard2RS` | 27212 | `/opt/smart-library-b/sharding/shard2` |
| mongos | Router | 27200 | 统一访问入口 |

任务书允许每个分片采用单节点或副本集形式；当前实现使用单成员副本集作为两个 Shard，并使用单成员 `configRS`，适合课程实验，不应描述为生产级高可用分片架构。

### 4.2 初始化、注册与访问控制

现有证据已经证明：

- Config Server、Shard 1、Shard 2 均完成初始化并成为 PRIMARY；
- mongos 识别为 `isdbgrid`；
- 创建并认证了分片集群管理员；
- `shard1RS` 和 `shard2RS` 均成功注册；
- `listShards` 与 `sh.status()` 显示双分片拓扑。

新增 `bootstrap_sharded_cluster.sh`，将上述首次初始化与注册整理为幂等流程：已有副本集或已有 Shard 不会重复创建。

### 4.3 生命周期与严格验收

启动、停止脚本现在会同时检查：

- 端口是否监听；
- 监听进程是否属于 `mongolab`；
- 进程名和配置文件路径是否与目标组件一致；
- MongoDB ping 是否成功。

这可以防止仅凭端口存在就误判为目标服务。`verify_cluster_acceptance.sh` 进一步核对认证用户、mongos 身份、Config Server 身份和两个 Shard 的注册状态，并以非零退出码表示失败。

## 5. 新增或完善的交付物

### 任务五

- `start_replica.sh`、`stop_replica.sh`
- `bootstrap_replica.sh`
- `check_replica.sh`
- `failover_drill.sh`
- `member_change_drill.sh`
- `replica_failover_probe.py`

### 任务六基础设施

- 改进后的 `start_cluster.sh`、`stop_cluster.sh`、`check_cluster.sh`
- `bootstrap_sharded_cluster.sh`
- `verify_cluster_acceptance.sh`

### 通用交付

- `member_b_common.sh`：统一安全检查、进程识别、端口与认证逻辑；
- `install_templates.sh`：预览或安装运行时配置，覆盖前自动备份；
- `member-b.env.example`：无真实凭据的环境变量示例；
- `scripts/member-b/README.md`：完整复现顺序与证据标记；
- `REPORT_DRAFT_TASK5_TASK6.md`：可直接合并到总报告的成员 B 章节初稿；
- `DELIVERY_CHECKLIST.md`：提交前逐项勾选清单。

## 6. 仍需在虚拟机执行的收尾

仓库代码只能证明“具备可复现能力”，不能替代真实 MongoDB 运行结果。提交前还需在 CentOS 环境完成：

1. 对全部 Shell 脚本执行 `bash -n`；
2. 运行 `check_replica.sh` 并保存 `REPLICA_ACCEPTANCE_PASS`；
3. 同时运行 Python 探针与 `failover_drill.sh`，保存选举耗时和驱动异常/恢复记录；
4. 运行一次 `member_change_drill.sh`，保存移除和恢复结果；
5. 运行 `verify_cluster_acceptance.sh`，保存 `SHARDED_CLUSTER_ACCEPTANCE_PASS`；
6. 将新增证据截图编号接在现有任务五、任务六截图之后；
7. 与成员 C 确认其任务六后半部分已经完成真实分片、双分片数据分布和查询对比。

不得把尚未在虚拟机运行的新脚本描述为“已通过实测”。
