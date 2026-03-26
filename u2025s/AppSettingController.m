#import "AppSettingController.h"
#import "PreferencesManager.h"

@implementation AppSettingController

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    XLog(@"AppSettingController readPreferenceValue for %@.%@",
         self.bundleIdentifier, [specifier identifier]);
    
    // 始终从最新的 AllSettings 读取
    NSMutableDictionary *config = [[PreferenceConfig sharedInstance] AllSettings];
    NSDictionary *appSettings = config[@"appsetting"][self.bundleIdentifier];
    id value = [appSettings objectForKey:[specifier identifier]];
    XLog(@"Read value: %@", value);
    return value;
}

- (void)setPreferenceValue:(id)value forSpecifier:(PSSpecifier *)specifier {
    XLog(@"AppSettingController setPreferenceValue %@ for %@.%@",
         value, self.bundleIdentifier, [specifier identifier]);
    
    // 始终操作最新的 AllSettings
    NSMutableDictionary *config = [[PreferenceConfig sharedInstance] AllSettings];
    NSMutableDictionary *appSettings = [config[@"appsetting"] mutableCopy];
    NSMutableDictionary *thisApp = [appSettings[self.bundleIdentifier] mutableCopy];
    
    if (!thisApp) {
        thisApp = [NSMutableDictionary dictionary];
    }
    
    [thisApp setObject:value forKey:[specifier identifier]];
    appSettings[self.bundleIdentifier] = thisApp;
    config[@"appsetting"] = appSettings;
    
    [[PreferenceConfig sharedInstance] saveSettings];
}

- (id)specifiers {
    return _specifiers;
}

- (void)setSpecifier:(PSSpecifier *)specifier {
    XLog(@"AppSettingController setSpecifier %@", [specifier propertyForKey:@"bundleIdentifier"]);
    
    self.bundleIdentifier = [specifier propertyForKey:@"bundleIdentifier"];
    _specifiers = [self loadSpecifiersFromPlistName:@"appsetting" target:self];
    
    // 设置导航栏标题
    NSDictionary *detected = [[PreferenceConfig sharedInstance] detectedApps];
    NSString *appName = detected[self.bundleIdentifier] ?: self.bundleIdentifier;
    self.title = appName;
}

@end
