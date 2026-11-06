# 成员 B：MongoDB 副本集与分片集群

## 一、成员分工

成员 B 负责智慧图书馆数字资源平台的以下工作：

- 任务 5：MongoDB 三节点副本集部署与高可用验证
- 任务 6 前半部分：MongoDB 分片集群基础设施搭建
- 任务 7：副本集与分片集群验收、截图整理及报告撰写

## 二、实验环境

| 项目 | 配置 |
|---|---|
| 操作系统 | CentOS Stream 10 |
| MongoDB 版本 | 8.3.11 |
| mongosh 版本 | 2.12.0 |
| Linux 主机名 | nosql01 |
| 运行用户 | mongolab |
| 实验根目录 | /opt/smart-library-b |

本项目使用单台 CentOS 虚拟机部署多个 MongoDB 实例，模拟副本集与分片集群，主要用于课程教学实验，不作为生产级高可用部署方案。

## 三、任务 5：MongoDB 副本集

副本集名称：libraryRS

| 节点 | 端口 | Priority |
|---|---|---|
| Node 1 | 27117 | 2 |
| Node 2 | 27118 | 1 |
| Node 3 | 27119 | 1 |

已完成实验：

1. 三节点副本集初始化与 PRIMARY、SECONDARY 状态验证
2. PRIMARY 向 SECONDARY 的数据同步
3. primary、secondaryPreferred 读取偏好验证
4. PRIMARY 故障模拟及新 PRIMARY 自动选举
5. 故障切换后的数据读取与多数写入
6. 原 PRIMARY 恢复及数据同步
7. 节点移除、重新加入及状态检查
8. 管理员认证与未认证访问拒绝验证

本阶段使用 library_b_test 测试数据库完成基础实验，正式业务数据的联合验证需要与成员 A 的应用程序对接。

## 四、任务 6：MongoDB 分片集群

已完成以下基础设施部署：

| 组件 | 副本集名称 | 端口 |
|---|---|---|
| Config Server | configRS | 27219 |
| Shard 1 | shard1RS | 27211 |
| Shard 2 | shard2RS | 27212 |
| mongos | 路由服务 | 27200 |

已完成实验：

1. Config Server 配置和初始化
2. Shard 1 和 Shard 2 配置和初始化
3. mongos 路由服务启动
4. 分片集群管理员 shardingAdmin 创建及认证
5. 通过 sh.addShard() 注册两个 Shard
6. 使用 listShards 和 sh.status() 检查集群拓扑
7. 四个组件运行状态及端口验证

最终检查结果表明，mongos 能识别 shard1RS 和 shard2RS 两个已注册分片。

## 五、配置与连接说明

实验中的主要路径：

- MongoDB 安装目录：/export/servers/mongodb-8.3.11
- mongosh 安装目录：/export/servers/mongosh-2.12.0
- 配置文件目录：/opt/smart-library-b/config
- 副本集数据目录：/opt/smart-library-b/replica
- 分片数据目录：/opt/smart-library-b/sharding
- 日志目录：/opt/smart-library-b/logs

所有数据库服务均绑定虚拟机内部的 127.0.0.1 地址。

连接分片集群：

```bash
/export/servers/mongosh-2.12.0/bin/mongosh \
  --host 127.0.0.1 \
  --port 27200 \
  -u shardingAdmin \
  --authenticationDatabase admin \
  --password
```

连接成功后，可执行：

```javascript
db.adminCommand({listShards: 1})
sh.status()
```

管理员密码、keyfile、私钥和其他敏感配置不提交到 GitHub。

## 六、交接成员 C

成员 B 已完成任务 6 的分片基础设施部署，成员 C 可继续完成：

1. 确认正式数据库 smart_library 和 borrow_logs 集合结构
2. 分析 reader_card、book_isbn、borrow_date 等候选分片键
3. 确定主要分片方案和备选方案
4. 完成 borrow_logs 的分片配置
5. 导入或迁移 3000 条借阅流水
6. 验证数据在两个 Shard 上的分布
7. 对比定向路由查询与跨分片查询
8. 整理分片实验报告与截图

注意：两个 Shard 已加入集群，不代表业务借阅数据已经完成分片。

## 七、后续待完成事项

- 整理并提交可复现的副本集和分片集群部署脚本
- 提交不包含真实密钥的配置模板
- 整理任务 5 和任务 6 的实验截图
- 配合成员 A 完成正式业务数据与 Python 应用故障测试
- 完成成员 B 对应的实验报告章节
- 通过 Pull Request 将成员 B 的成果合并到 main 分支

## 八、协作说明

成员 B 在 member-b-infrastructure 分支完成开发及提交。

所有代码、配置模板和说明文档均应经过检查后，通过 Pull Request 交由成员 A 审核、合并。

禁止将 MongoDB 管理员密码、sharding.key、replica.key、.env、GitHub Token 或 SSH 私钥上传到公共仓库。
