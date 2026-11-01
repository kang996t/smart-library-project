# 智慧图书馆数字资源平台

本仓库用于完成基于 MongoDB 与 Python 的数据库管理系统期末项目。当前 `dev-A` 分支已完成成员 A 的前期开发基础：独立 Python 环境、MongoDB 只读连接封装、原始数据质量审计和命令行菜单框架。

本阶段不会创建 `smart_library` 数据库、集合或索引，不会导入数据、配置账号权限或执行 GridFS 上传，也不会修改原有 `library` 数据库。

## 当前实现

- `src/mongodb_connect.py`：统一读取环境变量、创建 `MongoClient`、执行只读 `ping`、区分服务器可达性与目标数据库是否存在，并可靠关闭连接。
- `scripts/check_data.py`：审计三份业务数据的解析、规模、字段、类型、缺失值、唯一性、引用关系、日期和 GridFS 文件清单。
- `src/main.py`：提供 8 项功能菜单、循环分发、非法输入处理、异常边界和正常退出；业务功能目前明确标记为待开发。
- `docs/data_quality_report.md`：由审计脚本基于当前原始文件生成的真实结果。

## 环境要求

- Python 3.13（当前验证版本为 3.13.5）
- PyMongo 4.x（当前验证版本为 4.19.0）
- MongoDB 本地服务；默认地址为 `mongodb://localhost:27017/`

Windows PowerShell 初始化方式：

```powershell
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

本仓库已创建 `.venv` 并通过 `.gitignore` 排除，不应提交虚拟环境文件。

## MongoDB 配置与只读检查

程序直接读取环境变量，不会自动加载本地 `.env` 文件。可参考 `config/.env.example` 在 PowerShell 或 PyCharm 运行配置中设置：

```powershell
$env:MONGODB_URI = "mongodb://localhost:27017/"
$env:MONGODB_DB_NAME = "smart_library"
python src\mongodb_connect.py
```

若不设置环境变量，将使用上述默认值。连接检查只执行 `ping` 和数据库列表读取；即使 `smart_library` 尚不存在也不会创建它。

## 数据审计

执行审计并刷新 Markdown 报告：

```powershell
python scripts\check_data.py --report docs\data_quality_report.md
```

脚本只读取 `data` 目录，不修改原始业务数据或 `gridfs_files` 中的资源。存在解析错误、关键字段错误、主标识冲突、引用缺失或文件不一致时返回非零退出码；普通质量警告默认不阻断执行，可增加 `--strict` 将警告视为失败。

## 命令行应用

```powershell
python src\main.py
```

菜单包含：

1. 图书检索与管理
2. 读者管理
3. 借阅记录查询
4. 分类统计
5. 学院借阅排行
6. 年月借阅趋势
7. 热门图书排行
8. GridFS 数字资源管理

当前仅实现应用框架，选择任一业务项都会显示“待开发”，不会返回模拟结果，也不依赖业务数据库已经初始化。后续模块可通过 `SmartLibraryCLI` 的 `handlers` 参数注入对应处理函数。

## 项目结构

```text
smart-library-project/
├─ config/       连接配置示例
├─ data/         原始业务数据与 GridFS 测试资源
├─ docs/         审计报告及后续项目文档
├─ evidence/     后续实验截图
├─ scripts/      数据审计及后续可复现脚本
├─ src/          Python 应用源码
├─ requirements.txt
└─ README.md
```

## 后续开发依赖

成员 C 完成并冻结集合名称、字段类型、可选字段规则、`borrow_logs` 集合类型及索引清单后，成员 A 才能继续开展正式建库、数据导入、查询统计、索引优化、账号权限和业务管理模块。GridFS 上传、下载、元数据与主菜单联调依赖成员 C 提供的 `gridfs_manager.py` 接口。
