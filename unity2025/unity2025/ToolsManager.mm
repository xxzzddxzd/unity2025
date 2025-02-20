// ToolsManager.mm
#import "ToolsManager.h"
#import "p_inc.h"

// 内核调用验证宏（类内部使用）
#define KERN_SAFE_CALL(call) ({ \
kern_return_t _kr = (call); \
if(_kr != KERN_SUCCESS) { \
    XLog(@"%s failed: 0x%x @ %s:%d", #call, _kr, __FILE__, __LINE__); \
} \
_kr; \
})

// Mach API声明
extern "C" {
kern_return_t mach_vm_region(
    vm_map_t target_task,
    vm_address_t *address,
    vm_size_t *size,
    vm_region_flavor_t flavor,
    vm_region_info_t info,
    mach_msg_type_number_t *infoCnt,
    mach_port_t *object_name
);
}

@implementation ToolsManager

+ (instancetype)shared {
    static ToolsManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - 内存操作实现
+ (int)getMemoryMap:(void *)dst
      startAddress:(long *)ad1
        endAddress:(long *)ad2 {
    XLog(@"getMemoryMap in")
//    vm_address_t region = reinterpret_cast<vm_address_t>(dst);
//    vm_size_t region_size = 0;
//    
//    vm_region_basic_info_data_64_t info;
//    mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
//    
//    kern_return_t kr = KERN_SAFE_CALL(
//        mach_vm_region(mach_task_self(),
//                      &region,
//                      &region_size,
//                      VM_REGION_BASIC_INFO_64,
//                      reinterpret_cast<vm_region_info_t>(&info),
//                      &info_count,
//                      nullptr)
//    );
//    
//    if (kr != KERN_SUCCESS) return 0;
//    
//    *ad1 = static_cast<long>(region);
//    *ad2 = static_cast<long>(region + region_size);
//    
//    XLog(@"Memory Map: [0x%lx - 0x%lx]", *ad1, *ad2);
//    return (info.protection >= VM_PROT_READ) ? 64 : 0;
    mach_port_t task;
    vm_address_t region = (vm_address_t)dst;
    vm_size_t region_size = 0;
    
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
    vm_region_flavor_t flavor = VM_REGION_BASIC_INFO_64;
    kern_return_t kr = mach_vm_region(mach_task_self(), &region, &region_size, flavor, (vm_region_info_t)&info, (mach_msg_type_number_t*)&info_count, (mach_port_t*)&task);
    if (kr != KERN_SUCCESS)
    {
        return 0;
    }
    
    *ad1 = region;
    *ad2 = region + region_size;
    
    if (info.protection < 1) {
        return 0;
    }
    XLog(@"getMap from %lx to %lx", region, region + region_size)
    return 64;
}

- (long)cachedASLR {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _cachedASLROffset = [self calculateFreshASLROffset];
        _aslrCalculated = YES;
        XLog(@"ASLR Calculated: 0x%lx", _cachedASLROffset);
    });
    return _cachedASLROffset;
}

- (long)calculateFreshASLROffset {
    @synchronized (self) {
        // 保留原有完整计算逻辑
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *frameworkPath = [[mainBundle.bundlePath stringByAppendingPathComponent:@"Frameworks"]
                                  stringByAppendingPathComponent:@"UnityFramework.framework"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:frameworkPath]) {
            XLog(@"UnityFramework not found");
            return _dyld_get_image_vmaddr_slide(0);
        }
        
        NSBundle *frameworkBundle = [NSBundle bundleWithPath:frameworkPath];
        if (![frameworkBundle load]) {
            XLog(@"Framework load failed");
            return _dyld_get_image_vmaddr_slide(0);
        }
        
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            if (strstr(_dyld_get_image_name(i), "UnityFramework.framework/UnityFramework")) {
                long slide = _dyld_get_image_vmaddr_slide(i);
                XLog(@"Found Framework ASLR: 0x%lx", slide);
                return slide;
            }
        }
        return _dyld_get_image_vmaddr_slide(0);
    }
}

- (void)clearASLRCache {
    @synchronized (self) {
        _cachedASLROffset = 0;
        _aslrCalculated = NO;
    }
}

- (void)printMemory64:(long)start
              length:(long)len
          formatType:(int)type {
    const long endAddress = start + len;
    XLog(@"Memory Dump Start: 0x%lx", start);
    
    for (long addr = start; addr <= endAddress; addr += 16) {
        @autoreleasepool {
            if (type == 1) {
                const uint64_t value1 = *reinterpret_cast<uint64_t*>(addr);
                const uint64_t value2 = *reinterpret_cast<uint64_t*>(addr + 8);
                XLog(@"0x%016lx | %016lx %016lx", addr, value1, value2);
            } else if (type == 2) {
                const float f1 = *reinterpret_cast<float*>(addr);
                const float f2 = *reinterpret_cast<float*>(addr + 4);
                const float f3 = *reinterpret_cast<float*>(addr + 8);
                const float f4 = *reinterpret_cast<float*>(addr + 12);
                XLog(@"0x%016lx | %.4f | %.4f | %.4f | %.4f",
                    addr, f1, f2, f3, f4);
            }
        }
    }
}

@end
