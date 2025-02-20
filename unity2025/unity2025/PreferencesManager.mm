#import "PreferencesManager.h"
#import "p_inc.h"

@interface PreferencesManager () {
//    NSString *_localConfigPath;
    NSString *_currentBundleID;
}

@property (nonatomic, strong) NSMutableDictionary *globalPreferences;
@property (nonatomic, strong) NSMutableDictionary *localPreferences;

@end

@implementation PreferencesManager

+ (instancetype)sharedManager {
    static PreferencesManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化路径
        _currentBundleID = [[NSBundle mainBundle] bundleIdentifier];
        NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//        _localConfigPath = [docDir stringByAppendingPathComponent:@"local.x5.u2025s.plist"];
        
        // 加载配置
        [self loadGlobalPreferences];
//        [self loadLocalPreferences];
    }
    return self;
}

#pragma mark - 配置加载
- (void)loadGlobalPreferences {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:D_PREFPATH];
    _globalPreferences = prefs ? [prefs mutableCopy] : [NSMutableDictionary dictionary];
}

//- (void)loadLocalPreferences {
//    NSDictionary *localPrefs = [NSDictionary dictionaryWithContentsOfFile:_localConfigPath];
//    _localPreferences = localPrefs ? [localPrefs mutableCopy] : [NSMutableDictionary dictionary];
//}

#pragma mark - 核心逻辑
- (NSDictionary *)getPrefs {
    if (!_currentBundleID) {
        XLog(@"BundleID 获取失败");
        return @{@"enable": @YES, @"speed": @5};
    }
    
    // 优先检查本地配置
    if (_localPreferences.count > 0) {
        return @{
            @"enable": _localPreferences[@"enable"] ?: @(self.globalEnable),
            @"speed": _localPreferences[@"speed"] ?: @(self.globalSpeed)
        };
    }
    
    // 检查全局配置
    NSDictionary *appSettings = _globalPreferences[@"appsetting"];
    NSDictionary *bundleConfig = appSettings[_currentBundleID];
    
    if (!bundleConfig) {
        // 创建继承全局配置的新条目
        NSDictionary *newConfig = @{
            @"enable": @(self.globalEnable),
            @"speed": @(self.globalSpeed)
        };
        
        // 写入本地配置文件
        [self saveLocalConfig:newConfig];
        
        return newConfig;
    }
    
    return bundleConfig;
}

#pragma mark - 配置保存
- (void)saveLocalConfig:(NSDictionary *)config {
    // 使用原子写入保证数据完整性
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:config
                                                             format:NSPropertyListBinaryFormat_v1_0
                                                            options:0
                                                              error:nil];
//    [data writeToFile:_localConfigPath options:NSDataWritingAtomic error:nil];
    
    // 更新内存缓存
    _localPreferences = [config mutableCopy];
}

#pragma mark - 全局配置存取
- (BOOL)globalEnable {
    return [_globalPreferences[@"global_enable"] boolValue];
}

- (void)setGlobalEnable:(BOOL)globalEnable {
    _globalPreferences[@"global_enable"] = @(globalEnable);
}

- (NSInteger)globalSpeed {
    return [_globalPreferences[@"speed"] integerValue];
}

- (void)setGlobalSpeed:(NSInteger)globalSpeed {
    _globalPreferences[@"speed"] = @(globalSpeed);
}

@end
