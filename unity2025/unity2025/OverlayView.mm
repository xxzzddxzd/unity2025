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

- (UIWindow*) getmainw{
    __block UIWindow *activeWindow = nil;
        [[[UIApplication sharedApplication] connectedScenes] enumerateObjectsUsingBlock:^(UIScene *scene, BOOL *stop) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                activeWindow = windowScene.windows.firstObject;
                *stop = YES;
            }
        }];
        return activeWindow;
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
    
    // 确保按钮始终显示在最上层
    self.toggleButton.layer.zPosition = 999;
    
    // 将按钮添加到主窗口
    // 添加到主窗口
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) {
            window = [[UIApplication sharedApplication].windows firstObject];
        }
        [window addSubview:self.toggleButton];
    });
    
    __unsafe_unretained typeof(self) weakSelf = self;
    [HookManager shared].stateChangedHandler = ^(HookState state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleHookStateChanged:state];
        });
    };
}

- (void)handleHookStateChanged:(HookState)state {
    XLog(@"handleHookStateChanged %d",state)
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
    
    XLog(@"New hidden state: %d", self.hidden);
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
