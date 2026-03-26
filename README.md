# Unity 2025 (Dopamine Rootless)

使用 DeepSeek R1 对 unityspeedtool 进行了重构，并适配 Dopamine 无根越狱。

## 功能

### 修改 Unity app 的运行速度
- 使用查找 `il2cpp_resolve_icall` 和 `il2cpp_resolve_icall_0` 的方式，进而查找 `UnityEngine.Time::set_timeScale(System.Single)`，进行劫持
- 支持 `MSFindSymbol` 和 `dlsym` 双重符号查找（兼容 ElleKit）
- 有些游戏按不到加速按钮，可以通过音量键来启停加速
- 加速暂停时，解除了 hook，可以通过一些完整性校验

### 全新的设置页面
- 设置页面可以扫描手机上所有应用，并找出 Unity 类型游戏 app
- 每个游戏可以单独设置速度，无需再来回调整

## 兼容性
- **越狱类型**: Dopamine 无根越狱 (rootless)
- **iOS 版本**: 15.0+
- **架构**: arm64 / arm64e
- **Hook 框架**: ElleKit (CydiaSubstrate 兼容层)

## 构建

需要安装 [Theos](https://theos.dev) 开发环境。

```bash
make clean
make package
```

## 文件层级（安装后）
- `/var/jb/Library/MobileSubstrate/DynamicLibraries/` — 存放 `unity2025.dylib` 和 `unity2025.plist`，钩子
- `/var/jb/Library/PreferenceBundles/` — 存放 `u2025s.bundle`，设置程序
- `/var/jb/Library/PreferenceLoader/Preferences/` — 存放 `u2025s.plist`，设置的入口
- `/var/mobile/Library/Preferences/x5.u2025s.plist` — 偏好配置文件

## 项目结构

```
unity2025/
├── Makefile                # 根 Makefile（Theos rootless）
├── control                 # Debian 包控制文件
├── tweak/                  # 主插件源代码
│   ├── Tweak.xm            # Logos hook 入口
│   ├── HookManager.h/.mm   # Hook 管理器
│   ├── ToolsManager.h/.mm  # 内存/ASLR 工具
│   ├── PreferencesManager.h/.mm  # 偏好读取
│   ├── OverlayView.h/.mm   # 浮窗 UI
│   ├── FloatingButton.h/.mm # 悬浮按钮
│   └── p_inc.h             # 公共头文件
├── layout/                 # 安装布局
│   └── Library/MobileSubstrate/DynamicLibraries/
│       └── unity2025.plist
├── u2025s/                 # 设置子项目
│   ├── Makefile
│   ├── *.m / *.h
│   ├── Resources/
│   └── layout/
└── unity2025/              # 旧 Xcode 项目（保留参考）
```
