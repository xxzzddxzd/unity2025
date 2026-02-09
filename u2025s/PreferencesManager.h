#import "p_inc.h"

@interface PreferenceConfig : NSObject

@property (strong, nonatomic, readonly) NSMutableDictionary<NSString *, id> *AllSettings;

+ (instancetype)sharedInstance;

/// 保存所有设置到 CFPreferences，并发送变更通知
- (void)saveSettings;

/// 重新从 CFPreferences 加载设置
- (void)reloadSettings;

/// 添加新 app 配置
- (void)addNewApp:(NSString *)bundleID;

/// 获取已检测的 Unity app 列表 { bundleID: displayName }
- (NSDictionary *)detectedApps;

@end
