//
//  hxshxx.h
//  hxshx
//
//  Created by 徐正达 on 2018/9/7.
//

#ifndef hxshxx_h
#define hxshxx_h

#define D_PREFPATH @"/var/mobile/Library/Preferences/x5.u2025s.plist"
#define XLog(FORMAT, ...) NSLog(@"#pc %@" , [NSString stringWithFormat:FORMAT, ##__VA_ARGS__]);
#define psta XLog(@"%lx,%@",_dyld_get_image_vmaddr_slide(0),[NSThread callStackSymbols]);

#import <objc/objc-class.h>
#import "rocketbootstrap.h"
#import <CommonCrypto/CommonDigest.h>
#import <substrate.h>
#import <mach/mach_init.h>
#import <mach/vm_map.h>
#import <mach/mach_port.h>
#import <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <UIKit/UIKit.h>




#endif /* hxshxx_h */



