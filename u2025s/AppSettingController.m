#import "AppSettingController.h"
#import "PreferencesManager.h"

// app列表上显示加速数值
@implementation AppSettingController {
    NSMutableDictionary *_config;
    NSMutableDictionary *_appconfig;
}

// - (NSString *)previewStringForApplicationWithIdentifier:(NSString *)applicationID {
//     // read enabled status for applicationID
//     NSDictionary* app_settings = [prefs objectForKey:applicationID];

//     if(app_settings) {
//         // show "Enabled" label if shadow is enabled in app
//         if(app_settings[@"App_Enable"] && [app_settings[@"App_Enable"] boolValue]) {
//             return app_settings[@"Speed"];
//         }
//     }

//     return @"";
// }

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    XLog(@"AppSettingController readPreferenceValue")
    return [_appconfig[self.bundleIdentifier] objectForKey:[specifier identifier]];
}

- (void)setPreferenceValue:(id)value forSpecifier:(PSSpecifier *)specifier {
    XLog(@"AppSettingController setPreferenceValue")
    [_config[@"appsetting"][self.bundleIdentifier] setObject:value forKey:[specifier identifier]];
    [[PreferenceConfig sharedInstance] saveSettings];
}

- (id)specifiers {
    XLog(@"AppSettingController specifiers.1 %@",_specifiers)
    // NSMutableArray *specs = [[self loadSpecifiersFromPlistName:@"appsetting" target:self] mutableCopy];
    // NSMutableArray *specifiers = [self loadSpecifiersFromPlistName:@"appseting" target:self];
    // _specifiers = specs;
    // if (!_specifiers) {
    //     // 从app.plist加载模板
    //     NSArray *specifiers = [self loadSpecifiersFromPlistName:@"appseting" target:self];
        
    //     // 动态替换bundleID变量
    //     // [self _injectBundleIDIntoSpecifiers:specifiers];
    //     _specifiers = [specifiers mutableCopy];
    // }
    // XLog(@"AppSettingController specifiers.2 %@",_specifiers)
    return _specifiers;
}

- (void)setSpecifier:(PSSpecifier *)specifier {
    XLog(@"AppSettingController setSpecifier %@,%@",specifier,[specifier propertyForKey:@"bundleIdentifier"])
    
    self.bundleIdentifier = [specifier propertyForKey:@"bundleIdentifier"];
    NSMutableArray *specifiers = [self loadSpecifiersFromPlistName:@"appsetting" target:self];
    _specifiers = specifiers;
    // 动态设置导航栏标题
    NSString *appName = [[ALApplicationList sharedApplicationList] applications][self.bundleIdentifier];
    self.title = appName ?: @"App Settings";
    // if (!_specifiers) {
    //     // 从app.plist加载模板
    //     NSArray *specifiers = [self loadSpecifiersFromPlistName:@"appseting" target:self];
        
    //     // 动态替换bundleID变量
    //     // [self _injectBundleIDIntoSpecifiers:specifiers];
    //     [super setSpecifier:specifier];
    //     _specifiers = [specifiers mutableCopy];
    // }

}

- (instancetype)init {
    if((self = [super init])) {
        _config = [[PreferenceConfig sharedInstance] AllSettings] ;
        _appconfig = _config[@"appsetting"];
    }

    return self;
}
@end
