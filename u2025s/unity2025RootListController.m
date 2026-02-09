#import "unity2025RootListController.h"
#import "PreferencesManager.h"
#import "p_inc.h"

@implementation unity2025RootListController {
    NSMutableDictionary *_config;
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        // 加载基础配置（全局开关 + 变速值）
        NSMutableArray *specs = [[self loadSpecifiersFromPlistName:@"root" target:self] mutableCopy];
        
        // 重新加载以获取最新数据
        _config = [[PreferenceConfig sharedInstance] AllSettings];
        
        // 从文件获取已检测的 Unity app 列表
        NSDictionary *detectedApps = [[PreferenceConfig sharedInstance] detectedApps];
        NSDictionary *appSettings = _config[@"appsetting"];
        
        // 合并：detected_apps 和 appsetting 中的 app 都要显示
        NSMutableSet *allBundleIDs = [NSMutableSet setWithArray:detectedApps.allKeys];
        [allBundleIDs addObjectsFromArray:appSettings.allKeys];
        
        XLog(@"Building specifiers: detectedApps=%@, appSettings=%@, allBundleIDs=%@",
             detectedApps, appSettings, allBundleIDs);
        
        for (NSString *bundleID in allBundleIDs) {
            // 如果该 app 还没有 appsetting 配置，自动创建默认配置
            if (!appSettings[bundleID]) {
                [[PreferenceConfig sharedInstance] addNewApp:bundleID];
                [[PreferenceConfig sharedInstance] saveSettings];
                _config = [[PreferenceConfig sharedInstance] AllSettings];
            }
            
            NSString *displayName = detectedApps[bundleID] ?: bundleID;
            PSSpecifier *spec = [self _createAppSpecifier:bundleID
                                             displayName:displayName];
            [specs addObject:spec];
        }
        
        _specifiers = specs;
    }
    return _specifiers;
}

#pragma mark - 创建规范器

- (PSSpecifier *)_createAppSpecifier:(NSString *)bundleID
                         displayName:(NSString *)displayName {
    PSSpecifier *spec = [PSSpecifier
        preferenceSpecifierNamed:displayName
        target:self
        set:nil
        get:nil
        detail:[AppSettingController class]
        cell:PSLinkCell
        edit:nil];
    
    [spec setProperty:bundleID forKey:@"bundleIdentifier"];
    [spec setProperty:@YES forKey:@"enabled"];
    
    XLog(@"Created specifier for %@ (%@)", bundleID, displayName);
    return spec;
}

#pragma mark - 配置读写

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    // 始终从最新的 AllSettings 读取
    _config = [[PreferenceConfig sharedInstance] AllSettings];
    return [_config objectForKey:[specifier identifier]];
}

- (void)setPreferenceValue:(id)value forSpecifier:(PSSpecifier *)specifier {
    _config = [[PreferenceConfig sharedInstance] AllSettings];
    [_config setObject:value forKey:[specifier identifier]];
    [[PreferenceConfig sharedInstance] saveSettings];
}

#pragma mark - 生命周期

- (instancetype)init {
    if ((self = [super init])) {
        _config = [[PreferenceConfig sharedInstance] AllSettings];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 重新加载配置和刷新列表
    [[PreferenceConfig sharedInstance] reloadSettings];
    _config = [[PreferenceConfig sharedInstance] AllSettings];
    _specifiers = nil;  // 强制重建 specifiers
    [self reloadSpecifiers];
}

@end
