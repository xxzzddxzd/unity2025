#import "PreferencesManager.h"

static NSString * const kPrefsFilePath = @"/var/jb/var/mobile/Library/Preferences/x5.u2025s.plist";

@interface PreferenceConfig ()
@property (strong, nonatomic, readwrite) NSMutableDictionary<NSString *, id> *AllSettings;
@end

@implementation PreferenceConfig

+ (instancetype)sharedInstance {
    static PreferenceConfig *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        [self reloadSettings];
        // 首次运行写入默认值
        [self saveSettings];
    }
    return self;
}

#pragma mark - 文件读写

- (void)reloadSettings {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefsFilePath];
    XLog(@"Read settings from file: %@", prefs);
    
    if (prefs) {
        _AllSettings = [prefs mutableCopy];
        // 确保 appsetting 是可变的
        if (_AllSettings[@"appsetting"]) {
            _AllSettings[@"appsetting"] = [_AllSettings[@"appsetting"] mutableCopy];
        }
    } else {
        _AllSettings = [NSMutableDictionary dictionaryWithDictionary:@{
            @"global_enable": @YES,
            @"speed": @5,
            @"appsetting": [NSMutableDictionary dictionary]
        }];
    }
    
    XLog(@"Settings loaded: %@", _AllSettings);
}

- (void)saveSettings {
    XLog(@"Saving settings to file");
    
    // 合并 detected_apps：避免覆盖 tweak 写入的数据
    NSDictionary *existingFile = [NSDictionary dictionaryWithContentsOfFile:kPrefsFilePath];
    if (existingFile[@"detected_apps"] && !_AllSettings[@"detected_apps"]) {
        _AllSettings[@"detected_apps"] = [existingFile[@"detected_apps"] mutableCopy];
    }
    
    BOOL success = [_AllSettings writeToFile:kPrefsFilePath atomically:YES];
    XLog(@"Save result: %d, data: %@", success, _AllSettings);
    
    // 发送 Darwin Notification 通知 tweak 配置已变更
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        kPrefsChangedNotification,
        NULL, NULL, true
    );
    
    XLog(@"Settings saved and notification posted");
}

#pragma mark - App 管理

- (void)addNewApp:(NSString *)bundleID {
    XLog(@"Adding new app: %@", bundleID);
    NSMutableDictionary *appSettings = [_AllSettings[@"appsetting"] mutableCopy];
    if (!appSettings) appSettings = [NSMutableDictionary dictionary];
    
    if (!appSettings[bundleID]) {
        appSettings[bundleID] = [@{
            @"enable": @YES,
            @"speed": @5,
        } mutableCopy];
        _AllSettings[@"appsetting"] = appSettings;
    }
    XLog(@"App settings after add: %@", _AllSettings);
}

- (NSDictionary *)detectedApps {
    // 重新读取文件获取 tweak 写入的最新数据
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefsFilePath];
    NSDictionary *detected = prefs[@"detected_apps"];
    XLog(@"detectedApps from file: %@", detected);
    return detected ?: @{};
}

@end
