#import "p_inc.h"

@interface PreferenceConfig : NSObject
@property (strong, nonatomic) NSMutableDictionary<NSString *, id>* AllSettings;
+ (instancetype)sharedInstance;
- (void)saveSettings;
- (void)addNewApp:(NSString *)bundleID;
@end