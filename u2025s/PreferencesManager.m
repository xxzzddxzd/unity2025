#import "PreferencesManager.h"



#pragma mark - 配置管理
@implementation PreferenceConfig
@synthesize  AllSettings;
+ (instancetype)sharedInstance {
    static PreferenceConfig* sharedInstance = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}




- (instancetype)init {
    if((self = [super init])) {
        AllSettings = [NSMutableDictionary dictionaryWithContentsOfFile:@U2025S_PREFS_PLIST];
        XLog(@"AllSettings 1 %@",AllSettings)
        if (!AllSettings) {
            AllSettings = [[NSMutableDictionary alloc] initWithDictionary:@{
                            @"global_enable": @YES,
                            @"speed": @5,
                            @"appsetting": @{}
                        } ];
        }
        XLog(@"AllSettings 2 %@",AllSettings)
        [self saveSettings];
    }
    return self;
}

- (void)saveSettings {
    XLog(@"saveSettings 1")
    [AllSettings writeToFile:@U2025S_PREFS_PLIST atomically:YES];
    XLog(@"saveSettings 2")
}

- (void)addNewApp:(NSString *)bundleID {
    XLog(@"addNewApp 1")
    NSMutableDictionary *appSettings = [AllSettings[@"appsetting"] mutableCopy];
    
    if (!appSettings[bundleID]) {
        appSettings[bundleID] = @{
            @"enable": @YES,
            @"speed": @5,
        };
        AllSettings[@"appsetting"] = appSettings;
    }
    XLog(@"addNewApp final :%@",AllSettings)
}

@end