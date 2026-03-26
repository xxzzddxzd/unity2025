//
//  HookManager.h
//  unity2025
//
//  Created by xuzhengda on 2/17/25.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HookArchType) {
    HookArchFramework,
    HookArchFrameworkV2,
    HookArchBinary
};

typedef NS_ENUM(NSUInteger, HookState) {
    HookStateUninitialized,
    HookStateSearching,
    HookStateHooked,
    HookStatePaused
};

typedef void (^HookStateChangedBlock)(HookState newState);

@interface HookManager : NSObject
@property (nonatomic, copy) HookStateChangedBlock stateChangedHandler;


// 注册特征码模板
- (void)registerSignature:(NSArray<NSNumber *> *)sig
                archType:(HookArchType)type
             description:(NSString *)desc;

// 执行内存搜索
- (long)performSignatureSearch;

// 系统架构检测
- (HookArchType)detectSystemArchitecture;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSArray<NSArray<NSNumber *>*>*> *signatures;
@property (nonatomic, assign) HookState currentState;
@property (nonatomic, strong) NSMutableDictionary *hookAddresses;
@property (nonatomic, assign) float currentSpeedScale;

+ (instancetype)shared;
- (void)initializeHooks;
- (void)enableHooks;
- (void)disableHooks;
- (void)setGameSpeed:(float)speedScale;
- (void)resetGameSpeed;
- (long)resolveFromSymbol;
@end
