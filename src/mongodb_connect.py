"""MongoDB 连接配置与只读连通性检查。

本模块只负责创建客户端、执行 ``ping`` 和释放连接，不会创建数据库、
集合或写入任何业务数据。
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Final

from dotenv import load_dotenv
from pymongo import MongoClient
from pymongo.errors import OperationFailure, PyMongoError

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = PROJECT_ROOT / "config" / ".env"

load_dotenv(ENV_FILE)
DEFAULT_MONGODB_URI: Final = "mongodb://localhost:27017/"
DEFAULT_DATABASE_NAME: Final = "smart_library"
DEFAULT_SERVER_SELECTION_TIMEOUT_MS: Final = 3_000
DEFAULT_CONNECT_TIMEOUT_MS: Final = 3_000
DEFAULT_SOCKET_TIMEOUT_MS: Final = 5_000


def _read_positive_int(name: str, default: int) -> int:
    """读取正整数环境变量，并在配置错误时尽早失败。"""

    raw_value = os.getenv(name)
    if raw_value is None or not raw_value.strip():
        return default

    try:
        value = int(raw_value)
    except ValueError as exc:
        raise ValueError(f"环境变量 {name} 必须是整数，当前值为 {raw_value!r}") from exc

    if value <= 0:
        raise ValueError(f"环境变量 {name} 必须大于 0，当前值为 {value}")
    return value


@dataclass(frozen=True)
class MongoSettings:
    """MongoDB 连接参数。"""

    uri: str = DEFAULT_MONGODB_URI
    database_name: str = DEFAULT_DATABASE_NAME
    server_selection_timeout_ms: int = DEFAULT_SERVER_SELECTION_TIMEOUT_MS
    connect_timeout_ms: int = DEFAULT_CONNECT_TIMEOUT_MS
    socket_timeout_ms: int = DEFAULT_SOCKET_TIMEOUT_MS

    @classmethod
    def from_environment(cls) -> "MongoSettings":
        """从环境变量加载设置，未提供时使用安全的本地默认值。"""

        uri = os.getenv("MONGODB_URI", DEFAULT_MONGODB_URI).strip()
        database_name = os.getenv("MONGODB_DB_NAME", DEFAULT_DATABASE_NAME).strip()
        if not uri:
            raise ValueError("环境变量 MONGODB_URI 不能为空")
        if not database_name:
            raise ValueError("环境变量 MONGODB_DB_NAME 不能为空")

        return cls(
            uri=uri,
            database_name=database_name,
            server_selection_timeout_ms=_read_positive_int(
                "MONGODB_SERVER_SELECTION_TIMEOUT_MS",
                DEFAULT_SERVER_SELECTION_TIMEOUT_MS,
            ),
            connect_timeout_ms=_read_positive_int(
                "MONGODB_CONNECT_TIMEOUT_MS",
                DEFAULT_CONNECT_TIMEOUT_MS,
            ),
            socket_timeout_ms=_read_positive_int(
                "MONGODB_SOCKET_TIMEOUT_MS",
                DEFAULT_SOCKET_TIMEOUT_MS,
            ),
        )


@dataclass(frozen=True)
class ConnectionStatus:
    """只读连接检查结果。``None`` 表示数据库存在性无法判定。"""

    server_reachable: bool
    database_exists: bool | None
    message: str


class MongoDBConnection:
    """统一管理 ``MongoClient`` 的生命周期。"""

    def __init__(self, settings: MongoSettings | None = None) -> None:
        self.settings = settings or MongoSettings.from_environment()
        self._client: MongoClient | None = None

    def connect(self) -> MongoClient:
        """创建或复用客户端；PyMongo 会在首次操作时真正建立连接。"""

        if self._client is None:
            self._client = MongoClient(
                self.settings.uri,
                serverSelectionTimeoutMS=self.settings.server_selection_timeout_ms,
                connectTimeoutMS=self.settings.connect_timeout_ms,
                socketTimeoutMS=self.settings.socket_timeout_ms,
                appname="smart-library-project",
            )
        return self._client

    def ping(self) -> bool:
        """执行 MongoDB 官方 ``ping`` 命令，不创建或修改任何数据。"""

        response = self.connect().admin.command("ping")
        return response.get("ok") == 1.0

    def get_database(self):
        """返回数据库句柄；获取句柄本身不会创建数据库。"""

        return self.connect()[self.settings.database_name]

    def check_connection(self) -> ConnectionStatus:
        """检查服务器可达性，并单独判断目标数据库是否已经存在。"""

        try:
            if not self.ping():
                return ConnectionStatus(False, None, "MongoDB 服务器响应了 ping，但返回值异常。")
        except PyMongoError as exc:
            return ConnectionStatus(False, None, f"MongoDB 服务器不可访问：{exc}")

        try:
            database_exists = self.settings.database_name in self.connect().list_database_names()
        except OperationFailure as exc:
            return ConnectionStatus(
                True,
                None,
                "MongoDB 服务器可访问，但当前账号无权列出数据库，"
                f"因此无法确认 {self.settings.database_name!r} 是否存在：{exc}",
            )
        except PyMongoError as exc:
            return ConnectionStatus(
                True,
                None,
                "MongoDB 服务器可访问，但查询数据库列表失败，"
                f"因此无法确认 {self.settings.database_name!r} 是否存在：{exc}",
            )

        if database_exists:
            message = (
                f"MongoDB 服务器可访问；业务数据库 {self.settings.database_name!r} 已存在。"
            )
        else:
            message = (
                f"MongoDB 服务器可访问；业务数据库 {self.settings.database_name!r} 尚不存在。"
                "本次检查不会创建该数据库。"
            )
        return ConnectionStatus(True, database_exists, message)

    def close(self) -> None:
        """释放客户端资源，可重复调用。"""

        if self._client is not None:
            self._client.close()
            self._client = None

    def __enter__(self) -> "MongoDBConnection":
        self.connect()
        return self

    def __exit__(self, exc_type, exc_value, traceback) -> None:
        self.close()


def main() -> int:
    """命令行只读连接检查入口。"""

    try:
        with MongoDBConnection() as connection:
            status = connection.check_connection()
    except ValueError as exc:
        print(f"配置错误：{exc}")
        return 2

    print(status.message)
    return 0 if status.server_reachable else 1


if __name__ == "__main__":
    raise SystemExit(main())
