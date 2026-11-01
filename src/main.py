"""智慧图书馆数字资源平台命令行入口。

当前阶段只提供可独立运行的菜单框架。业务处理函数通过 ``handlers`` 注入，
便于数据模型确定后接入各管理模块及成员 C 的 GridFS 模块。
"""

from __future__ import annotations

from collections.abc import Callable, Mapping
from dataclasses import dataclass


Handler = Callable[[], None]
InputFunction = Callable[[str], str]
OutputFunction = Callable[[str], None]


@dataclass(frozen=True)
class MenuItem:
    """一个可分发的菜单项。"""

    key: str
    title: str


MENU_ITEMS = (
    MenuItem("1", "图书检索与管理"),
    MenuItem("2", "读者管理"),
    MenuItem("3", "借阅记录查询"),
    MenuItem("4", "分类统计"),
    MenuItem("5", "学院借阅排行"),
    MenuItem("6", "年月借阅趋势"),
    MenuItem("7", "热门图书排行"),
    MenuItem("8", "GridFS 数字资源管理"),
)


class SmartLibraryCLI:
    """可测试、可扩展的菜单循环。"""

    def __init__(
        self,
        handlers: Mapping[str, Handler] | None = None,
        input_function: InputFunction = input,
        output_function: OutputFunction = print,
    ) -> None:
        self._input = input_function
        self._output = output_function
        supplied_handlers = dict(handlers or {})
        self._handlers: dict[str, Handler] = {
            item.key: supplied_handlers.get(item.key, self._pending_handler(item.title))
            for item in MENU_ITEMS
        }

    def _pending_handler(self, feature_name: str) -> Handler:
        def show_pending() -> None:
            self._output(
                f"[待开发] {feature_name}：正式数据模型或对应业务模块尚未集成。"
            )

        return show_pending

    def show_menu(self) -> None:
        self._output("\n=== 智慧图书馆数字资源平台 ===")
        for item in MENU_ITEMS:
            self._output(f"{item.key}. {item.title}")
        self._output("0. 退出系统")

    def run(self) -> int:
        """运行菜单循环；数据库尚未初始化时也可正常使用。"""

        while True:
            self.show_menu()
            try:
                choice = self._input("请选择功能：").strip()
            except (EOFError, KeyboardInterrupt):
                self._output("\n输入已结束，系统正常退出。")
                return 0

            if choice == "0":
                self._output("感谢使用，系统已退出。")
                return 0

            handler = self._handlers.get(choice)
            if handler is None:
                self._output("输入无效，请输入 0 到 8 之间的菜单编号。")
                continue

            try:
                handler()
            except Exception as exc:  # 业务模块接入后的统一故障边界
                self._output(f"功能执行失败：{exc}")


def main() -> int:
    return SmartLibraryCLI().run()


if __name__ == "__main__":
    raise SystemExit(main())
