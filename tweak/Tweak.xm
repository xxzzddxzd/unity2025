#import "p_inc.h"
#import "ToolsManager.h"
#import "HookManager.h"
#import "OverlayView.h"
#import "PreferencesManager.h"

// 检查是否为 Unity 应用
static BOOL isUnityApp() {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *bundlePath = mainBundle.bundlePath;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 方法1：标准 Frameworks 目录下的 UnityFramework.framework
    NSString *frameworkPath = [[bundlePath stringByAppendingPathComponent:@"Frameworks"]
                              stringByAppendingPathComponent:@"UnityFramework.framework"];
    if ([fm fileExistsAtPath:frameworkPath]) {
        XLog(@"UnityFramework found via Frameworks/ check");
        return YES;
    }
    
    // 方法2：UnityFramework 直接在 app bundle 根目录（部分游戏的打包方式）
    NSString *directFramework = [bundlePath stringByAppendingPathComponent:@"UnityFramework"];
    if ([fm fileExistsAtPath:directFramework]) {
        XLog(@"UnityFramework found in bundle root");
        return YES;
    }
    
    // 方法3：检查 il2cpp 元数据文件（il2cpp 编译的 Unity 游戏特征）
    NSString *globalMetadata = [bundlePath stringByAppendingPathComponent:@"global-metadata.dat"];
    if ([fm fileExistsAtPath:globalMetadata]) {
        XLog(@"global-metadata.dat found (il2cpp Unity app)");
        return YES;
    }
    
    // 方法4：检查 Data 目录下的 Unity 资源（Mono 编译的 Unity 游戏特征）
    NSString *dataManaged = [[bundlePath stringByAppendingPathComponent:@"Data"]
                             stringByAppendingPathComponent:@"Managed"];
    if ([fm fileExistsAtPath:dataManaged]) {
        XLog(@"Data/Managed found (Mono Unity app)");
        return YES;
    }
    
    // 方法5：检查 Unity 默认资源文件
    NSString *unityDefault = [bundlePath stringByAppendingPathComponent:@"unity default resources"];
    if ([fm fileExistsAtPath:unityDefault]) {
        XLog(@"unity default resources found");
        return YES;
    }
    
    // 方法6：运行时检查 UnityAppController 类
    if (objc_getClass("UnityAppController")) {
        XLog(@"UnityAppController found via runtime check");
        return YES;
    }
    
    return NO;
}

%hook UnityAppController
-(BOOL)application:(id)application didFinishLaunchingWithOptions:(id)options
{
    XLog(@"UnityAppController didFinishLaunchingWithOptions")
    NSDictionary *prefs = [[PreferencesManager sharedManager] getPrefs];
    
    if ([[prefs objectForKey:@"enable"] boolValue]) {
        // 延迟初始化浮窗 UI（OverlayView 内部会创建独立的穿透窗口）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [OverlayView sharedInstance]; // 触发初始化，按钮会自动添加到穿透窗口
        });
        
        // 异步初始化 hook
        dispatch_queue_t queue = dispatch_queue_create("x5.unity2025.hook", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(queue, ^{
            XLog(@"Initializing hooks for Unity engine");
            [[HookManager shared] initializeHooks];
        });
    }
    return %orig;
}
%end

// 构造函数：注入时执行
%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        XLog(@"unity2025 loaded in: %@", bundleID);
        
        // 非 Unity app 立即返回
        if (!isUnityApp()) {
            XLog(@"Not a Unity app, skipping: %@", bundleID);
            return;
        }
        
        XLog(@"unity2025 rootless: Unity app detected: %@", bundleID);
        
        // 缓存 ASLR 偏移
        [[ToolsManager shared] cachedASLR];
        
        // 自动注册此 app 为已检测的 Unity app
        [[PreferencesManager sharedManager] registerAsDetectedUnityApp];
    }
}
