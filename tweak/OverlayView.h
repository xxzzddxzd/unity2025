//
//  OverlayView.h
//  unity2025
//
//  Created by xuzhengda on 2/17/25.
//
#import <UIKit/UIKit.h>
#import "FloatingButton.h"
#import "HookManager.h"
//@class FloatingButton;
@interface OverlayView : UIView{
    bool autoSetSpeedOn;
    float speed;
}
//@property (nonatomic, assign) CGRect gameArea;
@property (nonatomic, strong) FloatingButton *toggleButton;
@property (nonatomic, strong) UIWindow *customWindow;
+ (instancetype)sharedInstance;
- (void)handleHookStateChanged:(HookState)state;
@end
