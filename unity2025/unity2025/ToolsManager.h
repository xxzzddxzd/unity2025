// ToolsManager.h
#import <Foundation/Foundation.h>
#import <mach/vm_map.h>

NS_ASSUME_NONNULL_BEGIN

@interface ToolsManager : NSObject

#pragma mark - 内存操作
+ (instancetype)shared;

/// 内存区域查询（64位架构）
/// @param dst 查询起始地址
/// @param ad1 输出区域起始地址
/// @param ad2 输出区域结束地址
+ (int)getMemoryMap:(void *)dst startAddress:(long *)ad1 endAddress:(long *)ad2;

/// 内存数据打印（支持64位格式）
/// @param start 起始地址
/// @param len 读取长度
/// @param type 输出格式 (1=十六进制 2=浮点数)
- (void)printMemory64:(long)start length:(long)len formatType:(int)type;

@property (nonatomic, assign) long cachedASLROffset;
@property (nonatomic, assign) BOOL aslrCalculated;
@property (nonatomic, readonly) long cachedASLR;
- (void)clearASLRCache; // 必要时可重置缓存
@end

NS_ASSUME_NONNULL_END

