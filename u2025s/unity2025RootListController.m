#import "unity2025RootListController.h"
#import "PreferencesManager.h"
#import "p_inc.h"


@implementation unity2025RootListController{
	NSMutableDictionary *_config;
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        // 加载基础配置
        NSMutableArray *specs = [[self loadSpecifiersFromPlistName:@"root" target:self] mutableCopy];
        
        // 读取已保存配置
        NSDictionary *savedApps = _config[@"appsetting"];
        
        // 生成已配置条目
        [savedApps enumerateKeysAndObjectsUsingBlock:^(NSString *bundleID, NSDictionary *appConfig, BOOL *stop) {
            PSSpecifier *spec = [self _createAppSpecifier:bundleID];
            [specs addObject:spec];
        }];
        
        _specifiers = specs;
        
    }
    return _specifiers;
}

#pragma mark - 创建规范器
- (PSSpecifier *)_createAppSpecifier:(NSString *)bundleID{
	ALApplicationList *appList = [ALApplicationList sharedApplicationList];
    PSSpecifier *spec = [PSSpecifier 
        preferenceSpecifierNamed:appList.applications[bundleID]
        target:self
        set:nil //@selector(setPreferenceValue:specifier:)
        get:nil //@selector(readPreferenceValue:)
        detail:[AppSettingController class]
        cell:PSLinkCell
        edit:nil];
    
    // 关联配置键
    [spec setProperty:bundleID forKey:@"bundleIdentifier"];
    XLog(@"_createAppSpecifier setProperty %@, name:%@",bundleID,appList.applications[bundleID])
    [spec setProperty:@YES forKey:@"enabled"];    
    [spec setProperty:[appList iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:bundleID] forKey:@"iconImage"];
    return spec;
}

#pragma mark - Unity应用扫描
- (void)rescan:(id)sender {
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
	    NSMutableArray *bundleIDs = [NSMutableArray new];
	    NSString *bundleRoot = @"/var/containers/Bundle/Application";
	    NSMutableDictionary *appSettings = _config[@"appsetting"];
	    
	    // 遍历一级容器目录
	    for (NSString *uuid in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundleRoot error:nil]) {
	        NSString *containerPath = [bundleRoot stringByAppendingPathComponent:uuid];
	        
	        // 遍历二级应用包目录
	        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:containerPath];
	        NSString *appPackage;
	        while ((appPackage = [enumerator nextObject])) {
	            // 过滤.app目录
	            if (![[appPackage pathExtension] isEqualToString:@"app"]) continue;
	            
	            NSString *fullAppPath = [containerPath stringByAppendingPathComponent:appPackage];
	            NSString *frameworkPath = [fullAppPath stringByAppendingPathComponent:@"Frameworks/UnityFramework.framework"];
	            XLog(@"frameworkPath %@",frameworkPath)
	            // 验证Unity特征
	            if ([[NSFileManager defaultManager] fileExistsAtPath:frameworkPath]) {
	                NSString *infoPlistPath = [fullAppPath stringByAppendingPathComponent:@"Info.plist"];
	                NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
	                
	                if (info[@"CFBundleIdentifier"] ) {
	                    [bundleIDs addObject:info[@"CFBundleIdentifier"]];
	                    XLog(@"发现Unity应用：%@ at %@", info[@"CFBundleIdentifier"], appPackage);
	                    if (!appSettings[info[@"CFBundleIdentifier"]]) {
			                [[PreferenceConfig sharedInstance] addNewApp:info[@"CFBundleIdentifier"]];
			                [[PreferenceConfig sharedInstance] saveSettings];
			                // 实时插入新条目
			                // dispatch_async(dispatch_get_main_queue(), ^{
			                //     PSSpecifier *spec = [self _createAppSpecifier:info[@"CFBundleIdentifier"]];
			                //     [_specifiers addObject:spec];
			                //     [self reloadSpecifier:spec];
			                // });
			            }
	                }
	                break; // 单个容器只处理第一个.app
	            }
	        }
	    }
    });
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
	return [_config objectForKey:[specifier identifier]];
}

- (void)setPreferenceValue:(id)value forSpecifier:(PSSpecifier *)specifier {
	[_config setObject:value forKey:[specifier identifier]];
	[[PreferenceConfig sharedInstance] saveSettings];
}

- (instancetype)init {
	if((self = [super init])) {
		_config = [[PreferenceConfig sharedInstance] AllSettings] ;
	}

	return self;
}
@end