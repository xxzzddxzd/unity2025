# Unity 2025

iOS 越狱插件，用于控制 Unity 游戏的运行速度（`timeScale`）。支持 **Dopamine 无根越狱（rootless）** 和传统有根越狱（rootful）。基于 [Theos](https://theos.dev) 构建，使用 Logos 语法和 Objective-C++。

## 功能特性

### 三阶段 Hook 引擎

通过逐级降级的方式定位 IL2CPP 二进制中的 `UnityEngine.Time::set_timeScale` 函数：

1. **符号查找（Symbol）** — 通过 `MSFindSymbol` / `dlsym` 查找 `il2cpp_resolve_icall`，再用它解析 `set_timeScale`
2. **特征码扫描（Signature）** — 在内存中进行 ARM64 指令模式匹配（Framework v1、Framework v2、Binary 三套模式）
3. **交叉引用（XREF）** — 在内存中搜索 `"UnityEngine.Time::set_timeScale"` 字符串，解码 ADRP+ADD+BL 指令序列定位目标函数

Hook 通过 `MSHookFunction` 安装，拦截 `set_timeScale` 调用并替换为用户配置的速度值。

### 智能暂停/恢复

暂停加速时会完全解除 Hook，使游戏恢复原始状态，可通过部分完整性校验。恢复时重新安装 Hook。

### 浮窗控制

- 透明穿透窗口，不影响游戏操作
- 可拖拽悬浮按钮，显示当前速度和状态
- 支持屏幕旋转自动跟随

### 音量键控制

部分游戏 UI 会遮挡悬浮按钮，可通过音量键快捷启停加速。

### 设置页面

- 在 iOS 系统设置中提供独立的配置界面
- 自动扫描并识别设备上安装的 Unity 游戏
- 支持全局速度设置
- 支持每个游戏单独配置速度和开关
- 配置变更通过 Darwin 通知实时生效

## 兼容性

| 项目 | 要求 |
|------|------|
| 越狱类型 | Dopamine 无根越狱 (rootless) / 传统有根越狱 (rootful) |
| iOS 版本 | 15.0+ |
| 架构 | arm64 / arm64e |
| Hook 框架 | ElleKit / CydiaSubstrate |
| 依赖 | `ellekit`, `preferenceloader` |

## 构建

需要安装 [Theos](https://theos.dev) 开发环境，并设置 `$THEOS` 环境变量。

```bash
# 构建 rootless 版本（Dopamine）— 主要目标
make clean && make package SCHEME=rootless

# 构建 rootful 版本（传统越狱）
make clean && make package
```

构建产物（`.deb` 文件）输出到 `packages/` 目录。

## 项目结构

```
unity2025/
├── Makefile                          # 根 Makefile，定义 tweak 和子项目
├── control                           # Debian 包控制文件（版本、依赖等）
├── unity2025.plist                   # 注入过滤器配置
├── tweak/                            # 主插件源代码
│   ├── Tweak.xm                      # Logos hook 入口（%ctor 构造器）
│   ├── HookManager.h / .mm           # 三阶段 Hook 管理器
│   ├── ToolsManager.h / .mm          # 内存操作 / ASLR 工具
│   ├── PreferencesManager.h / .mm    # 偏好设置读取与合并
│   ├── OverlayView.h / .mm           # 浮窗 UI（穿透窗口 + 旋转跟随）
│   ├── FloatingButton.h / .mm        # 可拖拽悬浮按钮
│   └── p_inc.h                       # 公共头文件（XLog 宏、偏好 ID）
├── u2025s/                           # 设置界面子项目（PreferenceBundle）
│   ├── Makefile
│   ├── unity2025RootListController.h / .m   # 主设置页
│   ├── AppSettingController.h / .m          # 单应用设置页
│   ├── PreferencesManager.h / .m            # 设置端偏好管理
│   ├── p_inc.h                              # 共享偏好 ID
│   ├── Resources/                           # plist 资源
│   └── layout/                              # 安装布局
├── layout/                           # tweak 安装布局
│   └── Library/MobileSubstrate/DynamicLibraries/
│       └── unity2025.plist
└── unity2025/                        # 旧 Xcode 项目（保留参考）
```

## 安装路径

### Rootless（Dopamine 无根越狱）

| 路径 | 说明 |
|------|------|
| `/var/jb/Library/MobileSubstrate/DynamicLibraries/unity2025.dylib` | 插件动态库 |
| `/var/jb/Library/MobileSubstrate/DynamicLibraries/unity2025.plist` | 注入过滤器 |
| `/var/jb/Library/PreferenceBundles/u2025s.bundle` | 设置界面 Bundle |
| `/var/jb/Library/PreferenceLoader/Preferences/u2025s.plist` | 设置入口 |
| `/var/mobile/Library/Preferences/x5.u2025s.plist` | 用户偏好配置 |

### Rootful（传统有根越狱）

| 路径 | 说明 |
|------|------|
| `/Library/MobileSubstrate/DynamicLibraries/unity2025.dylib` | 插件动态库 |
| `/Library/MobileSubstrate/DynamicLibraries/unity2025.plist` | 注入过滤器 |
| `/Library/PreferenceBundles/u2025s.bundle` | 设置界面 Bundle |
| `/Library/PreferenceLoader/Preferences/u2025s.plist` | 设置入口 |
| `/var/mobile/Library/Preferences/x5.u2025s.plist` | 用户偏好配置 |
