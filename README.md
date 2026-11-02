# 智慧图书馆数字资源平台

本仓库用于完成基于 MongoDB 与 Python 的数据库管理系统期末项目。当前 `dev-A` 分支已完成成员 A 的任务三单机环境实现，包括专用 MongoDB 实例、基础数据初始化、检索与统计、索引执行计划实验以及三类账号权限控制；任务四及 GridFS、副本集、分片集群不在本阶段范围内。

## 任务三实现概览

- MongoDB 8.0.32 独立单机实例，数据目录为 `/var/lib/smart_library_mongo`，服务端口为 `27018`。
- `smart_library` 包含 `books`、`readers`、`borrow_logs`、`audit_logs` 和 `stat_result` 五个普通集合。
- 已导入 `books` 50 条、`readers` 30 条、`borrow_logs` 3000 条；日期字符串在导入时转换为 Python `datetime`，写入 MongoDB 后对应 BSON Date。
- 六类检索、五项统计、两组索引前后执行计划对比以及三类账号权限边界均已完成并留存真实执行记录。
- 阶段文档位于 `docs/任务3_单机环境实现_阶段交付.md` 和 `docs/任务3_单机环境实现_初稿.docx`，证据定位见 `docs/任务3_证据清单.md`。

## 环境要求

- Python 3.13
- PyMongo 4.x
- python-dotenv
- MongoDB 8.0.x 单机实例

Windows PowerShell 初始化方式：

```powershell
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item config\.env.example config\.env
```

`config/.env` 会由各任务三脚本自动加载，并已被 Git 忽略。请在本地填写专用实例地址和三类账号密码，不要将真实凭据写入源码、README 或 `.env.example`。

## 推荐执行顺序

以下顺序用于从空白单机实例复现任务三。当前已确认通过的实验环境无需重复执行。

```powershell
python scripts\init_database.py
python scripts\import_data.py
python scripts\task3_queries.py
python scripts\task3_statistics.py
python scripts\task3_indexes.py
python scripts\task3_create_users.py
```

创建账号后，在 MongoDB 配置文件中启用 `security.authorization: enabled` 并按运维流程重启专用实例，再执行权限验证：

```powershell
python scripts\task3_verify_permissions.py
```

`task3_indexes.py` 为执行计划实验脚本，会删除脚本清单中的业务索引、采集无索引执行计划，然后重建全部业务索引并采集优化后结果。它不删除集合或业务数据，但会短暂改变索引状态，因此不要在已验收环境中仅为重复验证而再次运行。

## 连接与认证

`src/mongodb_connect.py` 和任务三脚本优先读取 `config/.env`。认证未启用时可使用基础 URI：

```text
mongodb://<mongo-host>:27018/
```

认证启用后，普通查询或管理脚本必须使用具有相应权限的账号，并指定 `authSource=smart_library`。`task3_verify_permissions.py` 会分别使用 `libReader`、`libWriter` 和 `libAdmin` 验证查询、写入及索引管理边界，不会输出密码。

## 任务三脚本

- `src/mongodb_connect.py`：统一加载连接配置、执行只读 `ping` 并管理客户端生命周期。
- `scripts/init_database.py`：按需创建五个集合，不删除或覆盖已有数据。
- `scripts/import_data.py`：导入三份基础数据，转换日期类型，并校验集合数量。
- `scripts/task3_queries.py`：执行六类检索并生成真实查询记录。
- `scripts/task3_statistics.py`：执行五项统计，分类结果以 upsert 方式写入 `stat_result`。
- `scripts/task3_indexes.py`：创建任务二规划的索引并生成两组前后执行计划对比。
- `scripts/task3_create_users.py`：创建只读、读写和数据库管理三类账号。
- `scripts/task3_verify_permissions.py`：验证三类账号的权限边界，并清理验证时创建的临时记录或索引。

## 数据审计与命令行框架

原始数据可通过以下命令做只读质量审计：

```powershell
python scripts\check_data.py --report docs\data_quality_report.md
```

`src/main.py` 仍是后续任务的命令行菜单框架。本阶段没有实现或修改 `book_manager.py`、`reader_manager.py`、`borrow_manager.py`、`stat_manager.py`、GridFS 或集群部署功能。

## 项目结构

```text
smart-library-project/
├─ config/       本地连接配置示例
├─ data/         原始业务数据与后续 GridFS 测试资源
├─ docs/         任务三执行记录、阶段文档和证据清单
├─ evidence/     任务三实验截图
├─ scripts/      数据审计与任务三可复现脚本
├─ src/          连接封装和后续应用框架
├─ requirements.txt
└─ README.md
```
