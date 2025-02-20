

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AppList/AppList.h>

#define BUNDLE_ID           "x5.u2025s"
#define U2025S_PREFS_PLIST  "/var/mobile/Library/Preferences/" BUNDLE_ID ".plist"


#define XLog(FORMAT, ...) NSLog(@"#pc %@" , [NSString stringWithFormat:FORMAT, ##__VA_ARGS__]);