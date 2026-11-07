# Azen Search

一个 KDE Plasma 6 小组件（Plasmoid）：Windows 11 风格的搜索框，可以固定在面板（任务栏）上。

- 点击胶囊搜索框弹出搜索面板
- 搜索：应用、系统设置、最近文档、文件（Baloo）、位置、窗口、计算器和单位换算
- 回车启动第一个结果；下方"在网页中搜索"用浏览器搜索
- 宽度和搜索引擎可在组件设置里调整

## 安装（开发模式）

```bash
kpackagetool6 -t Plasma/Applet -i .
```

然后右键面板 → 进入编辑模式 → 添加组件 → 搜索 "Azen Search"。

或者直接安装到用户目录：

```bash
mkdir -p ~/.local/share/plasma/plasmoids
cp -r . ~/.local/share/plasma/plasmoids/com.azen.winsearch
plasmashell --replace &   # 重启 plasmashell 加载
```

## 依赖

- KDE Plasma 6（KWin/plasmashell 6）
- krunner、baloo（可选，提供文件搜索）

## 许可

GPL-3.0-or-later
