//
//  p_inc.h
//  unity2025
//
//  Created by 徐正达 on 2018/9/7.
//

#ifndef p_inc_h
#define p_inc_h

// CFPreferences App ID
#define kPrefsAppID CFSTR("x5.u2025s")
#define kPrefsChangedNotification CFSTR("x5.u2025s/prefsChanged")

#define XLog(FORMAT, ...) NSLog(@"#pc %@" , [NSString stringWithFormat:FORMAT, ##__VA_ARGS__]);
#define psta XLog(@"%lx,%@",_dyld_get_image_vmaddr_slide(0),[NSThread callStackSymbols]);

#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import <substrate.h>
#import <dlfcn.h>
#import <mach/mach_init.h>
#import <mach/vm_map.h>
#import <mach/mach_port.h>
#import <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <UIKit/UIKit.h>
#include <CoreFoundation/CoreFoundation.h>

#endif /* p_inc_h */
