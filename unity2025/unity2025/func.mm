//
//  hxshxx.m
//  hxshx
//
//  Created by 徐正达 on 2018/9/7.
//


#import "p_inc.h"
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <sys/socket.h>

#import "csharpfunc.h"
#define XLog(FORMAT, ...) NSLog(@"#pc %@" , [NSString stringWithFormat:FORMAT, ##__VA_ARGS__]);
#define psta XLog(@"%lx,%@",_dyld_get_image_vmaddr_slide(0),[NSThread callStackSymbols]);
int count=0;
/*
 Unity Common Function:
 public class WWW
 public void .ctor(string url, byte[] postData, Dictionary`2<string, string> headers);
 public static class Convert
 public static byte[] FromBase64String(string s); // 0x1010A4C98
 public sealed class RijndaelManaged
 public override ICryptoTransform CreateDecryptor(byte[] rgbKey, byte[] rgbIV); // 0x10117A86C
 public override ICryptoTransform CreateEncryptor(byte[] rgbKey, byte[] rgbIV); // 0x10117A99C
 public class UnityWebRequest
 public static UnityWebRequest UnityWebRequest_Post(string uri, WWWForm formData); // 0x100ED3980
 public static UnityWebRequest UnityWebRequest_Post_str(string uri, string postData); // 0x102582260
 internal UnityWebRequestError InternalSetRequestHeader(string name, string value); // 0x100ED2C94
 uri
 public override string uri_ToString(); // 0x1026C6DF0
 */
long doLoadFramework(){
    XLog(@"###############JBDETECT##################");
    id a =[NSBundle mainBundle];
    id path = [a bundlePath];
    id bp = [path stringByAppendingString:@"/Frameworks/UnityFramework.framework"];
    id c =[NSBundle bundleWithPath:bp];
    [c load];
    long alsr=0;
//    XLog(@"alsr main %lx",_dyld_get_image_vmaddr_slide(0));
    for (int i=0; i<_dyld_image_count(); i++) {
        
        if ([[NSString stringWithUTF8String:_dyld_get_image_name(i) ]  containsString:@"UnityFramework.framework/UnityFramework"]) {
            XLog(@"%d,%s",i,_dyld_get_image_name(i));
            XLog(@"0x%lx",_dyld_get_image_vmaddr_slide(i))
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return _dyld_get_image_vmaddr_slide(0);
}

#import <CommonCrypto/CommonCryptor.h>
NSString * deckey(NSString* baseStr){
    NSString * key=@"1231231231231231";
    NSData * baseData =[[NSData alloc] initWithBase64EncodedString:baseStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSUInteger dataLength = baseData.length +100+[key dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES].length;
    unsigned char buffer[dataLength];
    memset(buffer, 0,sizeof(char));
    size_t dataOffset = 0;
    CCCryptorStatus status=CCCrypt(kCCDecrypt,
                                   kCCAlgorithmAES,
                                   kCCOptionPKCS7Padding|kCCOptionECBMode,
                                   [key UTF8String],
                                   16,
                                   nil,
                                   [baseData bytes],
                                   [baseData length],
                                   buffer,
                                   dataLength,
                                   &dataOffset);
    NSString*decodingStr=nil;
    if(status==0){
        NSData*data=[[NSData alloc]initWithBytes:buffer length:dataOffset];
        decodingStr=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        //        XLog(@"解密后的串：");
    }
    //    else
    //        XLog(@"解密失败；");
    return decodingStr;
}
long (*WWW_ctor)(long,long,long,long);
long ne_WWW_ctor(long x0,long x1,long x2,long x3){
    long rev = WWW_ctor(x0,x1,x2,x3);psta
    NSString * str = [[ NSString alloc] initWithData:byteArraySaveToTmpDic(x2, [NSString stringWithFormat:@"%s_%d",__func__,count++]) encoding:4];
    XLog(@"WWW_ctor1 %s %@",getS(x1),str);
    return rev;
}
long (*Convert_FromBase64String)(long x0,long x1);long ne_Convert_FromBase64String(long x0,long x1){
    XLog(@"Convert_FromBase64String %s",getS(x1));
    return Convert_FromBase64String(x0,x1);
}
//public static string ToBase64String(byte[] inArray); // 0x101C13BAC
long (*ToBase64String)(long,long);
long ne_ToBase64String(long x0,long x1){
    long rev = ToBase64String(x0,x1);
    NSData * iv = byteArraySaveToTmpDic(x1, [NSString stringWithFormat:@"ToBase64String_in%d",count]);count++;
    XLog(@"ToBase64String %s %@",getS(rev),iv);
    return rev;
}
long (*RijndaelManaged_CreateEncryptor)(long,long,long);long ne_RijndaelManaged_CreateEncryptor(long x0,long x1,long x2){
    NSData * key = byteArraySaveToTmpDic(x1, [NSString stringWithFormat:@"key%d",count]);
    NSData * iv = byteArraySaveToTmpDic(x2, [NSString stringWithFormat:@"iv%d",count]);
    count++;
    XLog(@"RijndaelManaged_CreateEncryptor %@ %@",key,iv);psta
    return RijndaelManaged_CreateEncryptor(x0,x1,x2);
}
long (*RijndaelManaged_CreateDecryptor)(long,long,long);long ne_RijndaelManaged_CreateDecryptor(long x0,long x1,long x2){
    NSData * key = byteArraySaveToTmpDic(x1, [NSString stringWithFormat:@"key%d",count]);
    NSData * iv = byteArraySaveToTmpDic(x2, [NSString stringWithFormat:@"iv%d",count]);
    count++;
    XLog(@"RijndaelManaged_CreateDecryptor %@ %@",key,iv);psta
    return RijndaelManaged_CreateDecryptor(x0,x1,x2);
}
long (*UnityWebRequest_Post)(long,long,long);long ne_UnityWebRequest_Post(long x0,long x1,long x2){
    XLog(@"UnityWebRequest_Post %s",getS(x1));
    return UnityWebRequest_Post(x0,x1,x2);
}
void (*UnityWebRequest_SetupPost)(long,long,long);void ne_UnityWebRequest_SetupPost(long x0,long x1,long x2){
    XLog(@"UnityWebRequest_SetupPost %s",getS(x2));
    UnityWebRequest_SetupPost(x0,x1,x2);
}
long (*uri_ToString)(long);long ne_uri_ToString(long x0){
    return uri_ToString(x0);
}
long (*InternalSetRequestHeader)(long,long,long);
long ne_InternalSetRequestHeader(long x0,long x1,long x2){
    XLog(@"InternalSetRequestHeader %s %s",getS(x1),getS(x2));
    return InternalSetRequestHeader(x0,x1,x2);
}
//public byte[] WWWForm_get_data(); // 0x100E3D6FC
long (*WWWForm_get_data)(long);long ne_WWWForm_get_data(long x0){
    long rev=WWWForm_get_data(x0);
    XLog(@"WWWForm_get_data %d %@", count,byteArraySaveToTmpDic(rev, [NSString stringWithFormat:@"WWWForm_get_data_%d",count]));count++;
    return rev;
}
//public byte[] ComputeHash(byte[] buffer); // RVA: 0x1017E76D8 Offset: 0x17E76D8
__int64 __fastcall (*HashAlgorithm__ComputeHash)(__int64 a1, __int64 a2);
__int64 __fastcall ne_HashAlgorithm__ComputeHash(__int64 a1, __int64 a2){
    long rev=HashAlgorithm__ComputeHash(a1,a2);
    XLog(@"HashAlgorithm__ComputeHash %@",byteArraySaveToTmpDic(a2, @"hash"));
    XLog(@"HashAlgorithm__ComputeHash %@",byteArraySaveToTmpDic(rev, @"hash"));
    return rev;
}
//public static string GetString(string key, string defaultValue) { } // RVA: 0x1023CE9E8 Offset: 0x23CE9E8
//public static string GetString(string key) { } // RVA: 0x1023CEA38 Offset: 0x23CEA38
long (*GetString)(long,long);
long ne_GetString(long x0,long x1){ long rev=GetString(x0,x1); XLog(@"GetString %s %s",getS(x0),getS(rev))
    
    NSString * rr=[NSString stringWithUTF8String:getS(x0)];
    if( [rr isEqualToString:@"Painters.DeviceUniqueIdentifier"] ){
        XLog(@"uid is %s",getS(rev))
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)lastObject];
        documentPath = [NSString stringWithFormat:@"%@/tt",documentPath];
        NSString * data = deckey([NSString stringWithContentsOfFile:documentPath encoding:4 error:0]);
        NSString * subdata= [data componentsSeparatedByString:@" "][0];
        //        udkey 第四个
        setS(rev, (char*)[subdata UTF8String]);
        XLog(@"set uid  %s",getS(rev))
        //         setS(rev, "d-nbtp401rdno0p0ob9cshituhm53e087yeb1k5x12kfdz0py24x92yrgfcq3p69");
    }
    
    return rev;}
__int64 __fastcall (*System_Security_Cryptography_HMACSHA256___ctor_4341124628)(__int64 a1, __int64 a2);
__int64 __fastcall ne_System_Security_Cryptography_HMACSHA256___ctor_4341124628(__int64 a1, __int64 a2){
    XLog(@"hmac key %@",byteArraySaveToTmpDic(a2, @"1"))
    return System_Security_Cryptography_HMACSHA256___ctor_4341124628(a1,a2);
}
#define addr_WWW_ctor 0x10242B67C
#define addr_Convert_FromBase64String 0x101C13AD0
#define addr_Convert_ToBase64String 0x101C13BAC
#define addr_RijndaelManaged_CreateEncryptor 0x10251F280
#define addr_RijndaelManaged_CreateDecryptor 0x10251F3E8
#define addr_UnityWebRequest_Post 0x1024280A0
#define addr_uri_ToString 0x10218A5D8
#define addr_UnityWebRequest_InternalSetRequestHeader 0x102427A90
#define addr_WWWForm_get_data 0x1024282EC
void UnityCommonFunction(){
//    MSHookFunction((void*)( doLoadFramework() + addr_WWW_ctor),(void*)ne_WWW_ctor, (void**)&WWW_ctor);
//    MSHookFunction((void*)( doLoadFramework() + addr_UnityWebRequest_Post),(void*)ne_UnityWebRequest_Post, (void**)&UnityWebRequest_Post);
//    MSHookFunction((void*)( doLoadFramework() + 0x1022CFB98),(void*)ne_UnityWebRequest_SetupPost, (void**)&UnityWebRequest_SetupPost);
//    MSHookFunction((void*)( doLoadFramework() + addr_uri_ToString),(void*)ne_uri_ToString, (void**)&uri_ToString);
//    MSHookFunction((void*)( doLoadFramework() + addr_UnityWebRequest_InternalSetRequestHeader),(void*)ne_InternalSetRequestHeader, (void**)&InternalSetRequestHeader);
//    MSHookFunction((void*)( doLoadFramework() + addr_WWWForm_get_data),(void*)ne_WWWForm_get_data, (void**)&WWWForm_get_data);
    
    //            MSHookFunction((void*)( doLoadFramework() + addr_Convert_FromBase64String),(void*)ne_Convert_FromBase64String, (void**)&Convert_FromBase64String);
    //    MSHookFunction((void*)( doLoadFramework() + addr_Convert_ToBase64String),(void*)ne_ToBase64String, (void**)&ToBase64String);
    //    MSHookFunction((void*)( doLoadFramework() + addr_RijndaelManaged_CreateEncryptor),(void*)ne_RijndaelManaged_CreateEncryptor, (void**)&RijndaelManaged_CreateEncryptor);
    //    MSHookFunction((void*)( doLoadFramework() + addr_RijndaelManaged_CreateDecryptor),(void*)ne_RijndaelManaged_CreateDecryptor, (void**)&RijndaelManaged_CreateDecryptor);
//    MSHookFunction((void*)( doLoadFramework() + 0x1017E76D8),(void*)ne_HashAlgorithm__ComputeHash, (void**)&HashAlgorithm__ComputeHash);
//    MSHookFunction((void*)( doLoadFramework() + 0x1023CEA38), (void*)ne_GetString, (void**)&GetString);
    //    MSHookFunction((void*)( doLoadFramework() + 0x1023CEA38), (void*)ne_System_Security_Cryptography_HMACSHA256___ctor_4341124628, (void**)&System_Security_Cryptography_HMACSHA256___ctor_4341124628);
}

//public HTTPRequest_Send(); // 0x1012D2F34
//public string HTTPRequest_DumpHeaders(); // 0x1012D1EE0
//internal byte[] HTTPRequest_GetEntityBody(); // 0x1012D1274
#define addr_HTTPRequest_Send 0x100A87478
#define addr_HTTPRequest_DumpHeaders 0x1012FB5C8
#define addr_HTTPRequest_GetEntityBody 0x100A864C8
long (*HTTPRequest_DumpHeaders)(long); long ne_HTTPRequest_DumpHeaders(long x0){ return HTTPRequest_DumpHeaders(x0);}
long (*HTTPRequest_GetEntityBody)(long); long ne_HTTPRequest_GetEntityBody(long x0){ return HTTPRequest_GetEntityBody(x0);}
long (*HTTPRequest_Send)(long);long ne_HTTPRequest_Send(long x0){
    XLog(@"HTTPRequest_Send")
    long rev = HTTPRequest_Send(x0);
    id body = byteArraySaveToTmpDic_revdata(HTTPRequest_GetEntityBody(x0),[NSString stringWithFormat:@"%s_%d",__func__,count]) ;
    NSString * str  = [[NSString alloc] initWithData:body encoding:4];
    XLog(@"HTTPRequest_Send %d",count);
    XLog(@"HTTPRequest_Send %s ",getS(uri_ToString(*(long*)(x0+0x10))) );
    XLog(@"HTTPRequest_Send %s ",getS(ne_HTTPRequest_DumpHeaders(x0)) );
    XLog(@"HTTPRequest_Send %@ ",str );
    count++;
    return rev;
}

void BaseHttpCommonFunction(){
    //    MSHookFunction((void*)( doLoadFramework() + addr_HTTPRequest_Send),(void*)ne_HTTPRequest_Send, (void**)&HTTPRequest_Send);
//    MSHookFunction((void*)( doLoadFramework() + addr_HTTPRequest_DumpHeaders),(void*)ne_HTTPRequest_DumpHeaders, (void**)&HTTPRequest_DumpHeaders);
    //    MSHookFunction((void*)( doLoadFramework() + addr_HTTPRequest_GetEntityBody),(void*)ne_HTTPRequest_GetEntityBody, (void**)&HTTPRequest_GetEntityBody);
}


void execNewAc(){
    XLog(@"---START INJECT---")
    //    MSHookFunction((void*)( doLoadFramework() + 0x1012E8300), (void*)ne_SetUrl, (void**)&SetUrl);
    //
    //    MSHookFunction((void*)( doLoadFramework() + 0x1012EC18C), (void*)ne_SetHeader, (void**)&SetHeader);
    //    MSHookFunction((void*)( doLoadFramework() + 0x1012EB564), (void*)ne_SetContentString, (void**)&SetContentString);
    //
    //
    //    MSHookFunction((void*)( doLoadFramework() + 0x1011FCC48), (void*)ne_GetHash, (void**)&GetHash);
    //
    //    MSHookFunction((void*)( doLoadFramework() + 0x10172EFD4), (void*)ne_get_Uuid, (void**)&get_Uuid);
    //    MSHookFunction((void*)( doLoadFramework() + 0x1012CFD60), (void*)ne_get_Token, (void**)&get_Token);
    //    MSHookFunction((void*)( doLoadFramework() + 0x10183141C), (void*)ne_get_HasValidFirebaseSetting, (void**)&get_HasValidFirebaseSetting);
    //    MSHookFunction((void*)( doLoadFramework() + 0x10287F334), (void*)ne_SetRequestHeader, (void**)&SetRequestHeader);
    //    MSHookFunction((void*)( doLoadFramework() + 0x10287F7E0), (void*)ne_uget, (void**)&uget);
    //
    //    MSHookFunction((void*)( doLoadFramework() + 0x101823BF4), (void*)ne_SetDatabaseUrlInternal, (void**)&SetDatabaseUrlInternal);
    //
    //
    //
    //
    
}
















