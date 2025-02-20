#import "p_inc.h"
#import "ToolsManager.h"
#import "HookManager.h"
#import "OverlayView.h"
#import "PreferencesManager.h"


//long doLoadFramework();
void constructor() __attribute__((constructor));
void constructor(void)
{
    XLog(@"Loading unity2025, by deepseek R1")
    [[ToolsManager shared] cachedASLR];
}


%hook UnityAppController
-(BOOL)application:(id)application didFinishLaunchingWithOptions:(id)options
{
    
    XLog(@"-(BOOL)application:(id)application didFinishLaunchingWithOptions:(id)options")
    NSDictionary * prefs = [[PreferencesManager sharedManager] getPrefs];
    if ([prefs objectForKey:@"enable"]){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            OverlayView *overlay = [OverlayView sharedInstance];
            overlay.frame = [UIScreen mainScreen].bounds;
            [[UIApplication sharedApplication].keyWindow addSubview:overlay];
        });
        
        
        dispatch_queue_t queue = dispatch_queue_create("1212", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(queue, ^{
            XLog(@"Loading unity for unity engine")
            if(1){
                XLog(@"#########2");
                [[HookManager shared] initializeHooks];
                
            }
        });
    }
    return %orig;
}
%end

#import <substrate.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>

// 检查是否为 Unity 应用
static BOOL isUnityApp() {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *frameworkPath = [[mainBundle.bundlePath stringByAppendingPathComponent:@"Frameworks"]
                              stringByAppendingPathComponent:@"UnityFramework.framework"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:frameworkPath]) {
        XLog(@"UnityFramework found");
        return YES;
    }
    return NO;

    
}

// 注入逻辑
%ctor {
    @autoreleasepool {
        XLog(@"✅ running checking %d",isUnityApp());
    }
}
