
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>

#define kPrefsAppID     CFSTR("x5.u2025s")
#define kPrefsAppIDStr  @"x5.u2025s"
#define kPrefsChangedNotification CFSTR("x5.u2025s/prefsChanged")

#define XLog(FORMAT, ...) NSLog(@"#pc %@" , [NSString stringWithFormat:FORMAT, ##__VA_ARGS__]);
