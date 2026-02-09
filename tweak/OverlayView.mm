//
//  OverlayView.mm
//  unity2025
//
//  Created by xuzhengda on 2/17/25.
//

#import "OverlayView.h"
#import "HookManager.h"
#import "PreferencesManager.h"
#import "p_inc.h"

#import <MediaPlayer/MediaPlayer.h>

// 自定义穿透窗口：只拦截按钮区域的触摸，其他区域传递给下层
@interface PassthroughWindow : UIWindow
@end

@implementation PassthroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    // 如果触摸点不在任何子控件上（只命中了 window 或 VC 的 view），则穿透
    if (hitView == self || hitView == self.rootViewController.view) {
        return nil;
    }
    return hitView;
}
@end

@implementation OverlayView

+ (instancetype)sharedInstance {
    static OverlayView *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance setupToggleButton];
        instance.hidden = YES;  // 初始时隐藏图层
    });

    return instance;
}

- (UIWindowScene *)_activeWindowScene {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]] &&
            scene.activationState == UISceneActivationStateForegroundActive) {
            return (UIWindowScene *)scene;
        }
    }
    // 如果没有前台 scene，取第一个
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

- (void)setupToggleButton {
    // 创建悬浮按钮
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    self.toggleButton = [[FloatingButton alloc] initWithFrame:CGRectMake(screenWidth-64, 100, 44, 44)];
    self.toggleButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    self.toggleButton.layer.cornerRadius = 22;
    self.toggleButton.layer.masksToBounds = YES;
    
    // 设置按钮图标或文字
    [self.toggleButton setTitle:@"loading" forState:UIControlStateNormal];
    self.toggleButton.titleLabel.font = [UIFont systemFontOfSize:15];
    
    // 添加点击事件
    [self.toggleButton addTarget:self
                          action:@selector(handleButtonTap:)
                forControlEvents:UIControlEventTouchUpInside];
    
    // 创建独立的穿透窗口，确保按钮在最上层且可点击
    dispatch_async(dispatch_get_main_queue(), ^{
        PassthroughWindow *overlayWindow = nil;
        UIWindowScene *windowScene = [self _activeWindowScene];
        if (windowScene) {
            overlayWindow = [[PassthroughWindow alloc] initWithWindowScene:windowScene];
        } else {
            overlayWindow = [[PassthroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
        
        overlayWindow.windowLevel = UIWindowLevelAlert + 100;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.userInteractionEnabled = YES;
        
        // 必须设置 rootViewController（iOS 13+ 要求）
        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = [UIColor clearColor];
        vc.view.userInteractionEnabled = YES;
        overlayWindow.rootViewController = vc;
        
        // 将按钮添加到穿透窗口
        [vc.view addSubview:self.toggleButton];
        
        overlayWindow.hidden = NO;
        self.customWindow = overlayWindow; // 持有强引用防止释放
        
        XLog(@"Overlay window created, level: %.0f", overlayWindow.windowLevel);
    });
    
    __unsafe_unretained typeof(self) weakSelf = self;
    [HookManager shared].stateChangedHandler = ^(HookState state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleHookStateChanged:state];
        });
    };
}

- (void)handleHookStateChanged:(HookState)state {
    XLog(@"handleHookStateChanged %lu",(unsigned long)state)
    switch (state) {
        case HookStateSearching:
            [self.toggleButton startSearchingAnimation];
            [self.toggleButton setTitle:@" " forState:UIControlStateNormal];
            break;
            
        case HookStateHooked:
            [self.toggleButton stopSearchingAnimation];
            [self.toggleButton setTitle:[NSString stringWithFormat:@"%.1f",speed] forState:UIControlStateNormal];
            break;
            
        case HookStateUninitialized:
            [self.toggleButton stopSearchingAnimation];
            [self.toggleButton setTitle:@"❌" forState:UIControlStateNormal];
            break;
            
        case HookStatePaused:
            [self.toggleButton stopSearchingAnimation];
            [self.toggleButton setTitle:@"▶️" forState:UIControlStateNormal];
            break;
    }
}


- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO; // 不接收触摸事件
        NSDictionary * prefs = [[PreferencesManager sharedManager] getPrefs];
        speed = [[prefs objectForKey:@"speed"] floatValue] ;
        
        // 添加音量键监听
        [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(volumeChanged:)
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                               object:nil];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
    return self;
}

- (void)volumeChanged:(NSNotification *)notification {
    XLog(@"volumeChanged")
//    [self handleButtonTap:self.toggleButton];
    NSDictionary *userInfo = notification.userInfo;
//    float volume = [[userInfo objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    NSString *reason = [userInfo objectForKey:@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"];
    
    // 检测是否是用户通过物理按键改变音量
    if ([reason isEqualToString:@"ExplicitVolumeChange"]) {
        [self handleButtonTap:self.toggleButton];
    }
}

- (void)handleButtonTap:(FloatingButton *)sender {
    XLog(@"Button tapped, current hidden state: %d", self.hidden);
    
    // 每次点击重新读取设置
    NSDictionary *prefs = [[PreferencesManager sharedManager] getPrefs];
    speed = [[prefs objectForKey:@"speed"] floatValue];
    if (speed <= 0) speed = 5;
    XLog(@"Read speed from prefs: %.1f", speed);
    
    // 切换显示状态
    self.hidden = !self.hidden;
    if (autoSetSpeedOn == false) {
        [[HookManager shared] enableHooks];
        [[HookManager shared] setGameSpeed:speed];
        autoSetSpeedOn = true;
    }
    else{
        [[HookManager shared] resetGameSpeed];
        [[HookManager shared] disableHooks];
        autoSetSpeedOn = false;
    }
    
    XLog(@"New hidden state: %d, speed: %.1f", self.hidden, speed);
}

- (void)toggleOverlay:(UIButton *)sender {
    // 添加调试日志
    XLog(@"Toggle button tapped, current hidden state: %d", self.hidden);
    
    self.hidden = !self.hidden;
    sender.alpha = self.hidden ? 0.6 : 1.0;
    XLog(@"New hidden state: %d", self.hidden);
}

- (void)setupWithFrame:(CGRect)frame {
    self.frame = frame;
}



@end
