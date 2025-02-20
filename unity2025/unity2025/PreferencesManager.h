#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PreferencesManager : NSObject

+ (instancetype)sharedManager;

// 获取当前应用配置（自动处理全局配置继承）
- (NSDictionary *)getPrefs;

// 全局配置访问
@property (nonatomic, assign) BOOL globalEnable;
@property (nonatomic, assign) NSInteger globalSpeed;

@end

NS_ASSUME_NONNULL_END
