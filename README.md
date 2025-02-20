# Unity 2025
使用deepseek r1对unityspeedtool进行了重构

## 修改Unity app的运行速度
- 依然使用查找il2cpp_resolve_icall和il2cpp_resolve_icall_0的方式，进而查找UnityEngine.Time::set_timeScale(System.Single)，进行劫持。
- 有些游戏按不到加速按钮，可以通过音量键来启停加速
- 加速暂停时，解除了hook，可以通过一些完整性校验。

## 全新的设置页面
- 设置页面可以扫描手机上所有应用，并找出Unity类型游戏app
- 每个游戏可以单独设置速度，无需再来回调整

## 文件层级
- /Library/MobileSubstrate/DynamicLibraries，存放unity2025.dylib和unity2025.plist，钩子。
- /Library/PreferenceBundles，存放u2025s.bundle，设置程序。
- /Library/PreferenceLoader/Preferences，存放u2025s.plist，设置的入口。

## 不同点
- 放弃了内存特征搜索。deepseek搞不定这个代码。
