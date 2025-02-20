#line 1 "/Users/xuzhengda/Documents/codespace/unity2025/unity2025/unity2025.xm"
#import "p_inc.h"
#import "ToolsManager.h"
#import "HookManager.h"
#import "OverlayView.h"
#import "PreferencesManager.h"



void constructor() __attribute__((constructor));
void constructor(void)
{
    XLog(@"Loading unity2025, by deepseek R1")
    [[ToolsManager shared] cachedASLR];
}



#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

__asm__(".linker_option \"-framework\", \"CydiaSubstrate\"");

@class UnityAppController; 
static BOOL (*_logos_orig$_ungrouped$UnityAppController$application$didFinishLaunchingWithOptions$)(_LOGOS_SELF_TYPE_NORMAL UnityAppController* _LOGOS_SELF_CONST, SEL, id, id); static BOOL _logos_method$_ungrouped$UnityAppController$application$didFinishLaunchingWithOptions$(_LOGOS_SELF_TYPE_NORMAL UnityAppController* _LOGOS_SELF_CONST, SEL, id, id); 

#line 17 "/Users/xuzhengda/Documents/codespace/unity2025/unity2025/unity2025.xm"


static BOOL _logos_method$_ungrouped$UnityAppController$application$didFinishLaunchingWithOptions$(_LOGOS_SELF_TYPE_NORMAL UnityAppController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id application, id options) {
    
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
    return _logos_orig$_ungrouped$UnityAppController$application$didFinishLaunchingWithOptions$(self, _cmd, application, options);
}


#import <substrate.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>


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


static __attribute__((constructor)) void _logosLocalCtor_ca6a4934(int __unused argc, char __unused **argv, char __unused **envp) {
    @autoreleasepool {
        XLog(@"✅ running checking %d",isUnityApp());
    }
}
static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$UnityAppController = objc_getClass("UnityAppController"); { MSHookMessageEx(_logos_class$_ungrouped$UnityAppController, @selector(application:didFinishLaunchingWithOptions:), (IMP)&_logos_method$_ungrouped$UnityAppController$application$didFinishLaunchingWithOptions$, (IMP*)&_logos_orig$_ungrouped$UnityAppController$application$didFinishLaunchingWithOptions$);}} }
#line 70 "/Users/xuzhengda/Documents/codespace/unity2025/unity2025/unity2025.xm"
