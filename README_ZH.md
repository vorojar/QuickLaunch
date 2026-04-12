# QuickLaunch - macOS 快捷启动器

[English](README.md) | **中文**

> 一款轻量级 macOS 原生应用启动器，替代系统自带 Launchpad。纯 Swift 构建，零依赖，内存仅占 36MB。

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![GitHub release](https://img.shields.io/github/v/release/vorojar/QuickLaunch)](https://github.com/vorojar/QuickLaunch/releases)

![QuickLaunch 截图](screenshots/main.png)

## 为什么选择 QuickLaunch？

macOS 自带的 Launchpad 功能有限：不支持拼音搜索、无法按分类整理、没有右键菜单、无法自定义快捷键。QuickLaunch 解决了这些痛点，同时保持了原生 Launchpad 的流畅体验。

### 对比原生 Launchpad

| 功能 | 原生 Launchpad | QuickLaunch |
|------|:-:|:-:|
| 全屏模糊壁纸 | ✅ | ✅ |
| 拖拽排序 / 文件夹 | ✅ | ✅ |
| 搜索过滤 | ✅ | ✅ |
| 抖动删除模式 | ✅ | ✅ |
| 自动检测安装/卸载 | ✅ | ✅ |
| 拼音首字母搜索 | ❌ | ✅ |
| 按分类自动整理 | ❌ | ✅ |
| 使用频率排序 | ❌ | ✅ |
| 右键菜单 | ❌ | ✅ |
| 状态栏入口 | ❌ | ✅ |
| 自定义全局快捷键 | ❌ | ✅ |

## 功能特性

- **全屏启动台** - 高斯模糊壁纸背景，还原原生 macOS 体验
- **应用网格** - 流畅动画展示所有已安装应用
- **拖拽排序** - 拖拽排列应用，拖放到一起自动创建文件夹
- **文件夹管理** - 创建、重命名、解散文件夹
- **智能搜索** - 实时过滤，支持中文拼音首字母搜索
- **自动整理** - 一键按应用分类自动归类到文件夹
- **全局快捷键** - `Cmd+Shift+Space` 随时呼出
- **状态栏常驻** - 菜单栏快捷入口
- **自动同步** - 实时检测新安装和卸载的应用
- **中英双语** - 自动跟随系统语言
- **右键菜单** - 在 Finder 中显示、显示简介、移到废纸篓

## 安装

### 方式一：Homebrew（推荐）

```bash
brew install --cask quicklaunch
```

### 方式二：直接下载

1. 下载最新的 [QuickLaunch.dmg](https://github.com/vorojar/QuickLaunch/releases/latest)
2. 打开 DMG，将 `QuickLaunch.app` 拖入「应用程序」文件夹
3. 双击启动

## 使用方法

| 操作 | 方式 |
|------|------|
| 打开启动台 | `Cmd+Shift+Space` 或点击状态栏图标 |
| 关闭启动台 | `Esc` 或点击空白区域 |
| 启动应用 | 点击应用图标 |
| 搜索 | 直接打字（支持拼音） |
| 快速启动 | 输入后按 `Enter` |
| 创建文件夹 | 将一个应用拖到另一个上 |
| 重命名文件夹 | 点击打开文件夹后点击名称 |
| 调整排序 | 拖拽移动 |
| 删除模式 | 长按任意应用 |
| 右键菜单 | 右键点击应用 |

## 性能

| 指标 | 数值 |
|------|------|
| 应用体积 | 1.3 MB |
| 安装包 | 454 KB |
| 内存占用 | ~36 MB |
| 空闲 CPU | 0.0% |
| 外部依赖 | 无 |

纯 Swift 原生构建，无任何第三方依赖。启动时预渲染全部应用图标，打开面板时图标秒显、零卡顿。

## 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- Apple Silicon 或 Intel Mac

## 从源码构建

```bash
git clone https://github.com/vorojar/QuickLaunch.git
cd QuickLaunch
./scripts/build.sh
open QuickLaunch.app
```

## 数据存储

用户数据保存在 `~/Library/Application Support/QuickLaunch/`：

- `grid_layout.json` - 应用排列和文件夹布局
- `usage_stats.json` - 应用使用统计
- `hidden_apps.json` - 从启动台隐藏的应用

## 相关链接

- [官方网站](https://vorojar.github.io/QuickLaunch)
- [版本下载](https://github.com/vorojar/QuickLaunch/releases)
- [Homebrew Cask](https://github.com/Homebrew/homebrew-cask/pull/247853)

## 开源协议

MIT License

---

**关键词：** macOS 启动器、Launchpad 替代、Mac 应用启动器、macOS app launcher、快捷启动、拼音搜索启动器、Swift macOS 应用
