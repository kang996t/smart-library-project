# 成员 B 任务交付清单

说明：`[x]` 表示当前配置、脚本或已有截图可以证明；`[ ]` 表示提交前仍需在真实 CentOS/MongoDB 环境执行或与队员确认。不要仅凭脚本存在就勾选运行验证项。

## A. 任务五：三节点副本集

### 配置与拓扑

- [x] 提交 Node 1/2/3 配置模板，端口分别为 27117/27118/27119。
- [x] 配置 `libraryRS`、独立数据目录、日志目录和 PID 文件。
- [x] 配置 keyfile 内部认证及 `authorization: enabled`。
- [x] 已有截图证明一个 PRIMARY、两个 SECONDARY。
- [x] 提交副本集启动、停止、首次初始化和健康检查脚本。
- [ ] 在最终虚拟机运行 `check_replica.sh`，保留 `REPLICA_ACCEPTANCE_PASS` 输出。

### 数据同步与读取偏好

- [x] 已有截图证明 PRIMARY 数据同步至 Node 2 和 Node 3。
- [x] 已有截图证明 `primary` 读取偏好。
- [x] 已有截图证明 `secondaryPreferred` 读取偏好。
- [x] 已有截图证明节点恢复和重新加入后的数据一致性。

### 故障转移

- [x] 已有截图包含故障前拓扑、原 PRIMARY 停止、新 PRIMARY 产生和原节点恢复。
- [x] 已有截图包含选举时间分析以及切换后的读取和写入。
- [x] 提交自动识别 PRIMARY、计算选举耗时和恢复原节点的 `failover_drill.sh`。
- [x] 提交持续读写并记录驱动异常的 `replica_failover_probe.py`。
- [ ] 在同一次实验中并行运行探针与故障脚本。
- [ ] 保存 `ELECTION_SECONDS`、`FAILOVER_DRILL_PASS` 和探针 `probe_end` 输出。
- [ ] 在报告中说明选举窗口内读取、写入是否失败，以及驱动何时恢复；不得只写“业务不中断”。

### 节点管理与认证

- [x] 已有截图证明 Node 3 移除、重新启动、重新加入和三节点恢复。
- [x] 提交带显式确认保护的 `member_change_drill.sh`。
- [ ] 最终环境运行一次并保存 `MEMBER_CHANGE_DRILL_PASS`。
- [x] 已有截图证明管理员认证成功。
- [x] 已有截图证明未认证操作被拒绝。

## B. 任务六：成员 B 基础设施部分

### Config Server、Shard 与 mongos

- [x] 提交 `configRS`、`shard1RS`、`shard2RS` 和 mongos 配置模板。
- [x] 端口规划为 27219、27211、27212、27200。
- [x] 已有截图证明三个副本集组件完成初始化。
- [x] 已有截图证明 mongos 启动并识别为路由服务。
- [x] 已有截图证明管理员创建、认证和访问控制。
- [x] 已有截图证明 `shard1RS`、`shard2RS` 注册成功。
- [x] 提交幂等的 `bootstrap_sharded_cluster.sh`。
- [x] 提交身份校验后的启动、停止和健康检查脚本。
- [x] 提交严格认证验收脚本 `verify_cluster_acceptance.sh`。
- [ ] 最终环境运行严格验收并保存 `SHARDED_CLUSTER_ACCEPTANCE_PASS`。
- [ ] 再执行一次停止、恢复和严格验收，证明数据目录及分片注册保持不变。

### 向成员 C 交接

- [x] 文档明确给出集群拓扑、端口、配置路径和启动顺序。
- [x] 文档明确 mongos 统一入口为 27200。
- [x] 文档明确两个 Shard 已注册不等于业务数据已完成分片。
- [ ] 与成员 C 确认主分片键和备选方案的论证已完成。
- [ ] 与成员 C 确认 `borrow_logs` 已启用分片并含 3000 条数据。
- [ ] 与成员 C 确认两个 Shard 上均有真实数据或 Chunk 分布证据。
- [ ] 与成员 C 确认定向查询和跨分片查询对比已完成。

## C. 仓库与安全检查

- [x] 配置模板不含真实密码或 keyfile 内容。
- [x] 提供 `member-b.env.example`，只含占位符。
- [x] `.gitignore` 排除 `.env`、日志、PID、虚拟环境及缓存。
- [x] 启停脚本校验服务用户、进程名、配置路径和端口。
- [x] 配置安装脚本默认 `--dry-run`，应用时会备份旧配置。
- [ ] 在 CentOS 对所有 `*.sh` 执行 `bash -n` 并截图。
- [ ] 检查 Git 暂存内容中不存在密码、keyfile、Token、私钥、数据库文件和本机绝对路径。

## D. 报告与截图

- [x] 现有任务五截图覆盖环境、拓扑、同步、读取偏好、故障转移、恢复、节点管理和认证。
- [x] 现有任务六截图覆盖配置、组件启动、管理员、双分片注册、健康检查和停止恢复。
- [ ] 补充应用层持续读写探针截图或日志摘要。
- [ ] 补充新严格验收脚本的 PASS 输出截图。
- [ ] 统一图号；现有任务六题注从“图 6-17”跳到“图 6-19”，需核对是否遗漏图 6-18 或重新编号。
- [ ] 删除完全重复的截图或重复题注；现有证据中“安全停止验证”出现重复。
- [ ] 报告写明单成员 Config Server/Shard 是课程实验方案，不宣称生产级高可用。
- [ ] 报告至少保留成员 B 的真实问题排查过程：进程身份识别、认证初始化顺序、故障转移窗口或安全停止恢复。
- [ ] 与 A/C 合并后检查全报告术语、端口、集合名、图号和截图引用一致。

## E. 建议最终交付文件

- [x] `config/member-b/replica/*.conf`
- [x] `config/member-b/sharding/*.conf`
- [x] `config/member-b/member-b.env.example`
- [x] `scripts/member-b/*.sh`
- [x] `scripts/member-b/replica_failover_probe.py`
- [x] `scripts/member-b/requirements.txt`
- [x] `scripts/member-b/README.md`
- [x] `docs/member-b/TASK5_TASK6_COMPLETION.md`
- [x] `docs/member-b/REPORT_DRAFT_TASK5_TASK6.md`
- [x] `docs/member-b/DELIVERY_CHECKLIST.md`
- [x] `docs/member-b/GITHUB_UPDATE_GUIDE.md`
- [x] 现有任务五/六证据 Word 文档。
- [ ] 新运行日志及补充截图。
- [x] 已形成成员 B 报告初稿。
- [ ] 将成员 B 报告初稿并入团队 10-14 页正文，截图放附录。
