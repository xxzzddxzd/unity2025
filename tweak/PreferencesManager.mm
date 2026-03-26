#import "PreferencesManager.h"
#import "HookManager.h"
#import "p_inc.h"

static NSString * const kPrefsFilePath = @"/var/jb/var/mobile/Library/Preferences/x5.u2025s.plist";

@interface PreferencesManager () {
    NSString *_currentBundleID;
}
@property (nonatomic, strong) NSDictionary *cachedPrefs;
@end

// Darwin Notification 回调
static void prefsChangedCallback(CFNotificationCenterRef center,
                                  void *observer,
                                  CFStringRef name,
                                  const void *object,
                                  CFDictionaryRef userInfo) {
    XLog(@"Preferences changed notification received");
    [[PreferencesManager sharedManager] reloadPreferences];
}

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
        _currentBundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        // 监听配置变更通知
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            prefsChangedCallback,
            kPrefsChangedNotification,
            NULL,
            CFNotificationSuspensionBehaviorCoalesce
        );
    }
    return self;
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge const void *)(self)
    );
}

#pragma mark - 文件读写

- (NSDictionary *)readAllPrefs {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefsFilePath];
    XLog(@"Read prefs from file: %@", prefs);
    return prefs;
}

- (void)writeAllPrefs:(NSDictionary *)prefs {
    BOOL success = [prefs writeToFile:kPrefsFilePath atomically:YES];
    XLog(@"Write prefs to file: %d", success);
}

- (void)reloadPreferences {
    @synchronized(self) {
        _cachedPrefs = nil;
    }
    
    // 重新读取并立即应用新设置
    NSDictionary *prefs = [self getPrefs];
    BOOL enable = [[prefs objectForKey:@"enable"] boolValue];
    float speed = [[prefs objectForKey:@"speed"] floatValue];
    if (speed <= 0) speed = 5;
    
    XLog(@"Preferences reloaded live: enable=%d, speed=%.1f", enable, speed);
    
    HookManager *hook = [HookManager shared];
    if (hook.currentState == HookStateHooked || hook.currentState == HookStatePaused) {
        if (enable) {
            [hook enableHooks];
            [hook setGameSpeed:speed];
        } else {
            [hook resetGameSpeed];
            [hook disableHooks];
        }
    }
}

#pragma mark - 核心逻辑

- (NSDictionary *)getPrefs {
    @synchronized(self) {
        if (_cachedPrefs) return _cachedPrefs;
    }
    
    if (!_currentBundleID) {
        XLog(@"BundleID 获取失败");
        return @{@"enable": @YES, @"speed": @5};
    }
    
    NSDictionary *allPrefs = [self readAllPrefs];
    
    // 读取全局配置，处理 nil 情况
    BOOL globalEnable = allPrefs[@"global_enable"] ? [allPrefs[@"global_enable"] boolValue] : YES;
    NSInteger globalSpeed = allPrefs[@"speed"] ? [allPrefs[@"speed"] integerValue] : 5;
    if (globalSpeed <= 0) globalSpeed = 5;
    
    XLog(@"Global config: enable=%d, speed=%ld", globalEnable, (long)globalSpeed);
    
    // 读取 appsetting
    NSDictionary *allAppSettings = allPrefs[@"appsetting"];
    NSDictionary *bundleConfig = allAppSettings[_currentBundleID];
    
    NSDictionary *result;
    if (bundleConfig && [bundleConfig count] > 0) {
        result = bundleConfig;
    } else {
        result = @{
            @"enable": @(globalEnable),
            @"speed": @(globalSpeed)
        };
    }
    
    @synchronized(self) {
        _cachedPrefs = result;
    }
    
    XLog(@"getPrefs for %@: %@", _currentBundleID, result);
    return result;
}

#pragma mark - 自动注册

- (void)registerAsDetectedUnityApp {
    if (!_currentBundleID) return;
    
    // 获取 app 显示名称
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *displayName = info[@"CFBundleDisplayName"]
                         ?: info[@"CFBundleName"]
                         ?: _currentBundleID;
    
    // 读取当前配置
    NSMutableDictionary *allPrefs = [[self readAllPrefs] mutableCopy]
                                    ?: [NSMutableDictionary dictionary];
    
    // 读取或创建 detected_apps
    NSMutableDictionary *detectedApps = [allPrefs[@"detected_apps"] mutableCopy]
                                        ?: [NSMutableDictionary dictionary];
    
    // 检查是否已注册
    if ([detectedApps[_currentBundleID] isEqualToString:displayName]) {
        XLog(@"App already registered: %@", _currentBundleID);
        return;
    }
    
    // 注册
    detectedApps[_currentBundleID] = displayName;
    allPrefs[@"detected_apps"] = detectedApps;
    
    [self writeAllPrefs:allPrefs];
    XLog(@"Registered Unity app: %@ (%@)", _currentBundleID, displayName);
}

#pragma mark - 全局配置存取

- (BOOL)globalEnable {
    NSDictionary *prefs = [self readAllPrefs];
    return prefs[@"global_enable"] ? [prefs[@"global_enable"] boolValue] : YES;
}

- (NSInteger)globalSpeed {
    NSDictionary *prefs = [self readAllPrefs];
    NSInteger speed = [prefs[@"speed"] integerValue];
    return speed > 0 ? speed : 5;
}

@end
