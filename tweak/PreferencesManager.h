#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PreferencesManager : NSObject

+ (instancetype)sharedManager;

/// 获取当前应用配置（自动处理全局配置继承）
- (NSDictionary *)getPrefs;

/// 重新从 CFPreferences 加载配置
- (void)reloadPreferences;

/// 注册当前 app 为已检测的 Unity app
- (void)registerAsDetectedUnityApp;

/// 全局配置访问（直接从 CFPreferences 读取）
- (BOOL)globalEnable;
- (NSInteger)globalSpeed;

@end

NS_ASSUME_NONNULL_END
