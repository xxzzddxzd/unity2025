//
//  HookManager.mm
//  unity2025
//
//  Created by xuzhengda on 2/17/25.
//

#import "HookManager.h"
#import "ToolsManager.h"
#import "OverlayView.h"
#import "p_inc.h"



@implementation HookManager{
    long _u3dSystemFuncAddr[5];
    long _timeScaleAddr[5];
}
long ne_u3dsystemfunc(char * a1);
HookState GetCurrentHookState(void);
float GetCurrentSpeedScale(void);
long ne_sys_speed_control(float a1);
long searchintarget_new(long ad1, long ad2);

long (*u3dsystemfunc)(char*);
long ne_u3dsystemfunc(char * a1){
    XLog(@"u3dsystemfunc call %s",a1);
    return u3dsystemfunc(a1);
}
HookState GetCurrentHookState(void) {
    HookManager *manager = [HookManager shared];
    @synchronized(manager) {
        return manager.currentState;
    }
}
float GetCurrentSpeedScale(void) {
    HookManager *manager = [HookManager shared];
    @synchronized(manager) {
        return manager.currentSpeedScale;
    }
}
long (*sys_speed_control)(float);
long ne_sys_speed_control(float a1){
    XLog(@"C#原有调用，若启用了加速设置，则在此拦截 state:%lu, speed to set:%f",static_cast<unsigned long>(GetCurrentHookState()),a1);
    if (GetCurrentHookState()==HookStateHooked) {
        a1=GetCurrentSpeedScale();
    }
    return sys_speed_control(a1);
}
+ (instancetype)shared {
    static HookManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance setupDefaultSignatures];
    });
    return instance;
}
- (void)setGameSpeed:(float)speedScale {
    if (self.currentState != HookStateHooked && self.currentState != HookStatePaused ) {
        XLog(@"Hook not ready, delaying speed change, ");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self setGameSpeed:speedScale];
        });
        return;
    }
    
    _currentSpeedScale = speedScale;
    XLog(@"Setting game speed to: %.1fx", speedScale);
    
    // 调用被Hook的函数
    if (sys_speed_control) {
        ne_sys_speed_control(speedScale);
    } else {
        XLog(@"Speed control function not available");
    }
}
//- (void)setCurrentState:(HookState)currentState {
//    _currentState = currentState;
//    
//    // 主线程通知状态变化
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (self.stateChangedHandler) {
//            self.stateChangedHandler(currentState);
//        }
//    });
//}

- (void)setCurrentState:(HookState)newState {
    // 状态变更检查
    if (_currentState == newState) return;
    
    // 原子性写入
    @synchronized(self) {
        _currentState = newState;
    }
    
    // 主线程通知
    dispatch_async(dispatch_get_main_queue(), ^{
        [[OverlayView sharedInstance] handleHookStateChanged:newState];
    });
}


- (void)resetGameSpeed {
    [self setGameSpeed:1.0f];
}

#pragma mark - 参数校验
- (void)initializeHooks {
    if (self.currentState != HookStateUninitialized) return;
    
    self.currentState = HookStateSearching;
    XLog(@"Starting hook initialization");
    
    long u3dFuncAddr = 0;
    long u3dsettimescaleAddr64 = 0;
    XLog(@"Stage 1.0")
    [self getStoredAddressByName:&u3dFuncAddr func:@"u3dFuncAddr"];
    [self getStoredAddressByName:&u3dsettimescaleAddr64 func:@"u3dsettimescaleAddr64"];
    
    // 第一阶段：快速符号解析
    if(!u3dFuncAddr){
        XLog(@"Stage 1.1")
        u3dFuncAddr = [self resolveFromSymbol];
    }
    
    // 第二阶段：内存特征码搜索（快速路径失败时执行）
    if(!u3dFuncAddr){
        XLog(@"Stage 1.2")
        u3dFuncAddr = [self performSignatureSearch];
    }
    
    if (u3dFuncAddr) {
        XLog(@"Stage 2.0")
        if (!u3dsettimescaleAddr64) {
            XLog(@"Stage 2.1")
            [self setupSystemFuncHook:u3dFuncAddr];
            u3dsettimescaleAddr64 = [self getTimeScaleAddr];
        }
        
        if (u3dsettimescaleAddr64) {
            XLog(@"Stage 2.2")
            [self setupTimeScaleHook:u3dsettimescaleAddr64];
            XLog(@"Stage 2.3")
            self.currentState = HookStateHooked;
            [self unhooku3dsystemfuncAddr64];
            XLog(@"Stage 2.4")
            [self disableHooks];
            XLog(@"Stage 2.5")
            [self updateAddrToFileByFunctionName:u3dsettimescaleAddr64 func:@"u3dsettimescaleAddr64"];
            [self updateAddrToFileByFunctionName:u3dFuncAddr func:@"u3dFuncAddr"];
        }
        
    } else {
        self.currentState = HookStateUninitialized;
    }
}
- (void)enableHooks {
    if (self.currentState != HookStatePaused) {
        XLog(@"不是暂停状态")
        return;
    }
    
    [self applyMemoryPatch:_timeScaleAddr index:3];
    XLog(@"Hooks activated");
    self.currentState = HookStateHooked;
}

- (void)disableHooks {
    [self applyMemoryPatch:_timeScaleAddr index:1];
    XLog(@"Hooks deactivated");
    self.currentState = HookStatePaused;
}

- (void)applyMemoryPatch:(long[5])addrArray index:(int)idx {
    long addr = addrArray[0];
    kern_return_t kr = vm_protect(mach_task_self(), addr, 0x10, 0,
                                  VM_PROT_READ | VM_PROT_WRITE);
    if (kr == KERN_SUCCESS) {
        *(long *)addr = addrArray[idx];
        *(long *)(addr + 8) = addrArray[idx + 1];
        vm_protect(mach_task_self(), addr, 0x10, 0,
                   VM_PROT_READ | VM_PROT_EXECUTE);
    }
}
- (void)setupSystemFuncHook:(long)address {
    XLog(@"setupSystemFuncHook in 0x%lx",address)
    _u3dSystemFuncAddr[0] = address;
    _u3dSystemFuncAddr[1] = *(long *)address;
    _u3dSystemFuncAddr[2] = *(long *)(address + 8);
    
    MSHookFunction((void *)address, (void *)ne_u3dsystemfunc, (void **)&u3dsystemfunc);
    
    _u3dSystemFuncAddr[3] = *(long *)address;
    _u3dSystemFuncAddr[4] = *(long *)(address + 8);
    XLog(@"setupSystemFuncHook out")
}

-(void)unhooku3dsystemfuncAddr64{
    long thisAddr=_u3dSystemFuncAddr[0];
    if (vm_protect(mach_task_self(), (vm_address_t) (thisAddr ), 0x10, 0, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY)== KERN_SUCCESS)
    {
        XLog(@"unhook u3dsystemfuncAddr64_addr")
        *(long *)(thisAddr) =_u3dSystemFuncAddr[1];
        *(long *)(thisAddr+8) =_u3dSystemFuncAddr[2];
        vm_protect(mach_task_self(), (vm_address_t) (thisAddr ), 0x10, 0, VM_PROT_READ  | VM_PROT_EXECUTE);
    }
}

-(long)getTimeScaleAddr{
    long timeScaleAddr = ((long (*)(char *))u3dsystemfunc)("UnityEngine.Time::set_timeScale");
    if (!timeScaleAddr) return 0;
    
    [[ToolsManager shared] printMemory64:timeScaleAddr length:0x20 formatType:1];
    return timeScaleAddr;
}

- (void)setupTimeScaleHook:(long)address  {
    
    _timeScaleAddr[0] = address;
    _timeScaleAddr[1] = *(long *)address;
    _timeScaleAddr[2] = *(long *)(address + 8);
    
    MSHookFunction((void *)address, (void *)ne_sys_speed_control, (void **)&sys_speed_control);
    
    _timeScaleAddr[3] = *(long *)address;
    _timeScaleAddr[4] = *(long *)(address + 8);
}
- (void)setupDefaultSignatures {
    // 默认特征码配置
    _signatures = [@{
        @(HookArchFramework): @[
            @[@(0xFF03), @(0x02D1), @(0xF85F), @(0x04A9), @(0xF657), @(0x05A9),
              @(0xF44F), @(0x06A9), @(0xFD7B), @(0x07A9), @(0xFDC3), @(0x0191),
              @(0xF303), @(0x00AA), @(0xFFFF), @(0x02A9), @(0xFF13), @(0x00F9)]
        ],
        @(HookArchFrameworkV2): @[
            @[@(0xFFC3),@(0x01D1),@(0xF657),@(0x04A9),@(0xF44F),@(0x05A9),
              @(0xFD7B),@(0x06A9),@(0xFD83),@(0x0191),@(0xF303),@(0x00AA),
              @(0xE083),@(0x0091),@(0xE103),@(0x13AA),@(0x92FE),@(0xFF97)]
        ],
        @(HookArchBinary): @[
            @[@(0xF657), @(0xBDA9), @(0xF44F), @(0x01A9), @(0xFD7B), @(0x02A9),
              @(0xFD83), @(0x0091), @(0xFF43), @(0x01D1), @(0xF403), @(0x00AA),
              @(0xFF7F), @(0x04A9), @(0xFF1F), @(0x00F9)]
        ]
    } mutableCopy];
}

- (void)registerSignature:(NSArray<NSNumber *> *)sig
                 archType:(HookArchType)type
              description:(NSString *)desc {
    NSMutableArray *targets = [self.signatures[@(type)] mutableCopy] ?: [NSMutableArray new];
    [targets addObject:sig];
    self.signatures[@(type)] = targets;
    XLog(@"Registered new signature for %@: %@", desc, sig);
}

- (long)resolveFromSymbol {
    // 判断是否含有 il2cpp_resolve_icall_0 函数
    void *il2cpp_resolve_icall_0 = MSFindSymbol(0, "_il2cpp_resolve_icall");
    if (il2cpp_resolve_icall_0) {
        // il2cpp_resolve_icall 位置需要跳转的位置
        XLog(@"*(int*)il2cpp_resolve_icall_0 %lx %lx ", il2cpp_resolve_icall_0, *(long*)il2cpp_resolve_icall_0 & 0xff000000);
        
        // 往下查找第一个 0x14000000
        long baseaddr = (long)il2cpp_resolve_icall_0;
        for (int i = 0; i < 10; ++i) {
            long value = *(long*)baseaddr;
            if ((value & 0xff000000) == 0x14000000) {
                long bsr = ((value & 0xffffff) << 2); // 计算偏移
                long addrforil2cppresolveicall = baseaddr + bsr; // 加和
                XLog(@"il2cpp_resolve_icall_0 %lx", addrforil2cppresolveicall);
                return addrforil2cppresolveicall;
            }
            baseaddr += 4;
        }
    }
    return 0;
}



- (long)performSignatureSearch {
    XLog(@"performSignatureSearch in")
    long *ad1 = (long*)malloc(sizeof(long));
    long *ad2 = (long*)malloc(sizeof(long));
    *ad2 = [self getASLROffset];
    
    
    long result = 0;
    while ([ToolsManager getMemoryMap:(void*)(*ad2)
                         startAddress:ad1
                           endAddress:ad2] != 0) {
        //        result = [self searchInRange:*ad1 end:*ad2];
        result = searchintarget_new(*ad1, *ad2);
        if (result != 0) break;
    }
    
    free(ad1);
    free(ad2);
    return result;
}
long searchintarget_new(long ad1, long ad2) {
    XLog(@"searchintarget_new in")
    // framework 类型的unity
    int framework_target[] = {0xFF03, 0x02D1, 0xF85F, 0x04A9, 0xF657, 0x05A9, 0xF44F, 0x06A9, 0xFD7B, 0x07A9, 0xFDC3, 0x0191, 0xF303, 0x00AA, 0xFFFF, 0x02A9, 0xFF13, 0x00F9};
    int framework_target1[] = {0xFFC3,0x01D1,0xF657,0x04A9,0xF44F,0x05A9,0xFD7B,0x06A9,0xFD83,0x0191,0xF303,0x00AA,0xE083,0x0091,0xE103,0x13AA,0x92FE,0xFF97};
    // 普通类型的unity
    int bin_target[] = {0xF657, 0xBDA9, 0xF44F, 0x01A9, 0xFD7B, 0x02A9, 0xFD83, 0x0091, 0xFF43, 0x01D1, 0xF403, 0x00AA, 0xFF7F, 0x04A9, 0xFF1F, 0x00F9};
    
    long result = searchintarget1(ad1, ad2, framework_target, sizeof(framework_target) / sizeof(int));
    if (result){
        XLog(@"framework_target get")
        return  result;
    }
    result = searchintarget1(ad1, ad2, framework_target1, sizeof(framework_target1) / sizeof(int));
    if (result){
        XLog(@"framework_target1 get")
        return  result;
    }
    result = searchintarget1(ad1, ad2, bin_target, sizeof(bin_target) / sizeof(int));
    if (result){
        XLog(@"bin_target get")
        return  result;
    }
    XLog(@"searchintarget_new out")
    return 0;
    
}
static int biglittlecover(int x){
    //    short int x;
    unsigned char x0,x1;
    x0=((char*)&x)[0]; //低地址单元
    x1=((char*)&x)[1]; //高地址单元
    //    XLog(@"%x %x",x0,x1);
    return (x0<<8)+x1;
}

static bool cmpIndex(long nowaddr,int index,int * ary){
    if (index>11){
    }
    return *(unsigned short*)(nowaddr+index*2)==(unsigned short)*(ary+index);
}

long searchintarget1(long ad1, long ad2, int *target, unsigned long target_len) {
    long now = ad1;
    long end = ad2;
    long rev = 0;
    long temprev = 0;
    
    XLog(@"\tnow 0x%lx-0x%lx ", now, end);
    
    // 使用 target 数组进行查找（framework 类型）
    int *bearray = (int*)malloc(sizeof(int) * target_len);
    for (unsigned long i = 0; i < target_len; i++) {
        bearray[i] = biglittlecover(target[i]);
    }
    XLog(@"start for framework version");
    
    while (now < end - target_len * 2) {
        int index = 0;
        while (1 == cmpIndex(now, index, bearray)) {
            index++;
            if (index == target_len) {
                temprev = now;
                break;
            }
        }
        if (temprev != 0) {
            rev = temprev;
            XLog(@"FOUND in %lx ", temprev);
            free(bearray);
            return rev;
        }
        now += 1;
    }
    free(bearray);
    
    XLog(@"FOUND end");
    return rev;
}
#pragma mark - Core Search Logic
- (long)searchInRange:(long)start end:(long)end {
    HookArchType arch = [self detectSystemArchitecture];
    NSArray *candidates = self.signatures[@(arch)];
    
    for (NSArray<NSNumber *> *sig in candidates) {
        long addr = [self searchSignature:sig start:start end:end];
        if (addr) {
            XLog(@"Found signature at 0x%lx (Arch: %lu)", addr, (unsigned long)arch);
            return addr;
        }
    }
    return 0;
}

- (long)searchSignature:(NSArray<NSNumber *> *)sig
                  start:(long)start
                    end:(long)end {
    int *target = (int *)malloc(sig.count * sizeof(int));
    for (NSUInteger i = 0; i < sig.count; i++) {
        target[i] = [self swapEndian:sig[i].intValue];
    }
    
    long result = [self rawSearch:start end:end target:target length:sig.count];
    free(target);
    return result;
}

- (long)rawSearch:(long)start end:(long)end target:(int *)target length:(NSUInteger)len {
    // 保持原有搜索算法实现
    long now = start;
    while (now < end - len * 2) {
        int index = 0;
        while (index < len && *(unsigned short*)(now + index*2) == (unsigned short)target[index]) {
            index++;
        }
        if (index == len) return now;
        now++;
    }
    return 0;
}

#pragma mark - SaveAndRead
-(void)updateAddrToFileByFunctionName:(long)revaddr  func:(NSString*)func{
    long adjusted_revaddr = revaddr - [self getASLROffset];
    NSString *filePath = [self addrFilenameByFunctionName:func];
    NSString *addressString = [NSString stringWithFormat:@"%lx", adjusted_revaddr];
    NSError *error = nil;
    BOOL success = [addressString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (success) {
        XLog(@"Successfully wrote %@ addr to %@", func, filePath);
    } else {
        XLog(@"Failed to write : %@", [error localizedDescription]);
    }
}

-(NSString *) addrFilenameByFunctionName:(NSString *) func{
    // 1. 获取应用的版本号
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if (!version) {
        version = @"unknown";
    }
    // 3. 获取Documents目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    if (!documentsDirectory) {
        XLog(@"Failed to get Documents directory.");
        return nil;
    }
    
    // 4. 构建文件名和完整路径
    NSString *fileName = [NSString stringWithFormat:@"func_addr_%@_%@.txt", version, func];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    return filePath;
}

- (BOOL)getStoredAddressByName:(long *)storedAddress func:(NSString *)func{
    if (!storedAddress) {
        return NO;
    }
    long ASLR ;
    ASLR = [self getASLROffset];
    
    NSString *filePath = [self addrFilenameByFunctionName:func];
    if (!filePath) {
        XLog(@"File path is nil. Cannot read address.");
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *readError = nil;
        NSString *addressString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&readError];
        if (readError) {
            XLog(@"Failed to read address file: %@", [readError localizedDescription]);
            return NO;
        }
        
        if (addressString.length > 0) {
            // 将地址字符串转换为 long
            unsigned long addr = strtoul([addressString UTF8String], NULL, 16);
            if (addr != 0) {
                *storedAddress = addr;
                XLog(@"Using stored %@: 0x%lx",func, *storedAddress);
                *storedAddress = *storedAddress+ASLR;
                XLog(@"apply aslr: 0x%lx", *storedAddress);
                
                // 删除文件，以防存了错误的地址，导致进入闪退循环。
                NSError *deleteError = nil;
                BOOL deleted = [fileManager removeItemAtPath:filePath error:&deleteError];
                if (deleted) {
                    XLog(@"Successfully deleted address file: %@", filePath);
                } else {
                    XLog(@"Failed to delete address file: %@", [deleteError localizedDescription]);
                    // 根据需要决定是否将删除失败视为错误
                }
                return YES;
            } else {
                XLog(@"Stored address is invalid.");
                return NO;
            }
        } else {
            XLog(@"Address file is empty.");
            return NO;
        }
    } else {
        XLog(@"Address file does not exist.");
        return NO;
    }
}

#pragma mark - Utilities
- (int)swapEndian:(int)x {
    unsigned char *bytes = (unsigned char *)&x;
    return (bytes[0] << 8) | bytes[1];
}

- (long)getASLROffset {
    // 从ToolsManager获取ASLR偏移
    return [[ToolsManager shared] cachedASLR];
}

- (HookArchType)detectSystemArchitecture {
#if defined(__arm64__)
    return HookArchFramework;
#else
    return HookArchBinary;
#endif
}

@end
