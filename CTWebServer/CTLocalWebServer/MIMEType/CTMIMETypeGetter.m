//
//  CTMIMETypeGetter.m
//  CTWebServer
//
//  Created by ctinus on 2018/3/1.
//  Copyright © 2018年 ChenTong. All rights reserved.
//

#import "CTMIMETypeGetter.h"

@implementation CTMIMETypeGetter
+ (NSString *)MIMETypeForFile:(NSString *)filePath
{
    BOOL isDirectory = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    if(!isExist || isDirectory) {
        return [self mimeForExtension:nil];
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if(!fileHandle) {
        return [self mimeForExtension:nil];
    }
    
    NSData *data = [fileHandle readDataOfLength:100];
    NSString *guessExtenion = [self probeFileExtension:data];
    if(guessExtenion == nil) {
        guessExtenion = filePath.pathExtension;
        NSLog(@"can't guess file extension (%@)\n%@", filePath.lastPathComponent, data);
    }
    
    return [self mimeForExtension:guessExtenion];
}

+ (NSString *)mimeForExtension:(NSString *)extension {
    NSString *defaultType = @"text/*";
    if(extension == nil) {
        return defaultType;
    }
    
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"mime" ofType:@"plist"];
        map = [NSDictionary dictionaryWithContentsOfFile:path];
    });
    
    NSAssert(map.count, nil);
    if (map.count == 0) {
        return defaultType;
    }
    
    NSString *mime = map[extension];
    if(mime == nil) {
        NSLog(@"unknown mime type for extenion(%@)", extension);
    }
    
    return mime? mime: defaultType;
}

+ (NSString *)probeFileExtension:(NSData *)data
{
    if(data.length == 0) {
        return nil;
    }
    
    static NSArray *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @[
                @{@"data": @"62706C6973743030D4", @"ext": @"archiver"},
                @{@"data": @"62706C6973743030DF", @"ext": @"plist"},
                @{@"data": @"3C21444F435459504520706C69737420", @"ext": @"plist", @"skip": @(0x27*2)},
                
                @{@"data": @"FFD8FF", @"ext": @"jpeg"},
                
                @{@"data": @"89504E47", @"ext": @"png"},
                @{@"data": @"47494638", @"ext": @"gif"},
                @{@"data": @"424D", @"ext": @"bmp"},
                @{@"data": @"68656963", @"ext":@"heic", @"skip": @16},
                @{@"data": @"68656966", @"ext":@"heif", @"skip": @16},
                @{@"data": @"667479707174", @"ext": @"mov", @"skip": @8},
                @{@"data": @"667479706D7034", @"ext": @"mp4", @"skip": @8},
                @{@"data": @"6674797069736F6D", @"ext": @"mp4", @"skip": @8},
                @{@"data": @"6674797033677035", @"ext": @"mp4", @"skip": @8},
                @{@"data": @"667479704D534E56", @"ext": @"mp4", @"skip": @8},
                @{@"data": @"667479706D703432", @"ext": @"m4v", @"skip": @8},
                @{@"data": @"667479704D3456", @"ext": @"m4v", @"skip": @8},
                @{@"data": @"000001BA", @"ext": @"mpv"},
                @{@"data": @"66747970336770", @"ext": @"3gp", @"skip": @8},
                @{@"data": @"6D6F6F76", @"ext": @"mov"},
                @{@"data": @"41564920", @"ext": @"avi", @"skip": @16},
                @{@"data": @"415649204C495354", @"ext": @"avi", @"skip": @16},
                @{@"data": @"2E524D46", @"ext": @"rmvb"},
                @{@"data": @"2E524D46", @"ext": @"rm"},
                @{@"data": @"3026B2758E66CF11", @"ext": @"asf"},
                @{@"data": @"3026B2758E66CF11", @"ext": @"asf"},
                @{@"data": @"3026B2758E66CF11", @"ext": @"wmv"},
                @{@"data": @"1A45DFA3", @"ext": @"mkv"},
                @{@"data": @"41564920", @"ext": @"avi", @"skip": @16},
                @{@"data": @"000001Bx", @"ext": @"mpg"},
                @{@"data": @"000001BA", @"ext": @"mpg"},
                @{@"data": @"6674797071742020", @"ext": @"mov",@"skip": @8},
                @{@"data": @"6D6F6F76", @"ext": @"mov",@"skip": @8},
                @{@"data": @"000001BA", @"ext": @"vob"},
                @{@"data": @"464C5601", @"ext": @"flv"},
                @{@"data": @"435753", @"ext": @"swf"},
                @{@"data": @"5A5753", @"ext": @"swf"},
                @{@"data": @"465753", @"ext": @"swf"},
                
                @{@"data": @"494433", @"ext": @"mp3"},
                @{@"data": @"FFEx", @"ext": @"mp3"},
                @{@"data": @"FFFx", @"ext": @"mp3"},
                
                @{@"data": @"3026B2758E66CF11", @"ext": @"wma"},
                @{@"data": @"57415645666D7420", @"ext": @"wav",@"skip": @16},
                @{@"data": @"4D546864", @"ext": @"midi"},
                @{@"data": @"4F67675300020000", @"ext": @"ogg"},
                @{@"data": @"664C614300000022", @"ext": @"flac"},
                @{@"data": @"FFF1", @"ext": @"aac"},
                @{@"data": @"FFF9", @"ext": @"aac"},
                @{@"data": @"4D414320960F000034", @"ext": @"ape"},
                @{@"data": @"2321414D52", @"ext": @"amr"},
                @{@"data": @"667479704D344120", @"ext": @"m4a",@"skip": @8},
                
                @{@"data": @"3C3F786D6C", @"ext": @"xml"},
                @{@"data": @"68746D6C3E", @"ext": @"html"},
                @{@"data": @"44656C69766572792D646174653A", @"ext": @"eml"},
                
                @{@"data": @"25504446", @"ext": @"pdf"},
                @{@"data": @"504B0304", @"ext": @"zip"},
                @{@"data": @"52617221", @"ext": @"rar"},
                @{@"data": @"2E524D46", @"ext": @"rm"},
                
                @{@"data": @"41433130", @"ext": @"tif"},
                @{@"data": @"49492A00", @"ext": @"dwg"},
                @{@"data": @"38425053", @"ext": @"psd"},
                @{@"data": @"7B5C727466", @"ext": @"rtf"},
                
                @{@"data": @"5374616E64617264204A", @"ext": @"mdb"},
                @{@"data": @"CFAD12FEC5FD746F", @"ext": @"dbx"},        //没有mime
                @{@"data": @"2142444E", @"ext": @"pst"},                //没有mime
                @{@"data": @"252150532D41646F6265", @"ext": @"eps"},    //没有mime
                @{@"data": @"AC9EBD8F", @"ext": @"qdf"},  //没有mime
                @{@"data": @"E3828596", @"ext": @"pwl"},  //没有mime
                @{@"data": @"2E7261FD", @"ext": @"ram"},
                
                @{@"data": @"4D546864", @"ext": @"mid"},
                
                
                @{@"data": @"D0CF11E0A1B11AE1", @"ext": @"doc"},
                @{@"data": @"0D444F43", @"ext": @"doc"},
                @{@"data": @"CF11E0A1B11AE100", @"ext": @"doc"},
                @{@"data": @"DBA52D00", @"ext": @"doc"},
                @{@"data": @"ECA5C100", @"ext": @"doc"},
                @{@"data": @"504B0304140006", @"ext": @"docx"},
                @{@"data": @"504B0304", @"ext": @"docx"},
                @{@"data": @"D0CF11E0A1B11AE1", @"ext": @"wps"},
                @{@"data": @"7B5C72746631", @"ext": @"rtf"},
                @{@"data": @"504B0304", @"ext": @"pages"},
                @{@"data": @"D0CF11E0A1B11AE1", @"ext": @"xls"},
                @{@"data": @"0908100000060500", @"ext": @"xls"},
                @{@"data": @"FDFFFFFF10", @"ext": @"xls"},
                @{@"data": @"FDFFFFFF1F", @"ext": @"xls"},
                @{@"data": @"FDFFFFFF22", @"ext": @"xls"},
                @{@"data": @"FDFFFFFF23", @"ext": @"xls"},
                @{@"data": @"FDFFFFFF28", @"ext": @"xls"},
                @{@"data": @"FDFFFFFF29", @"ext": @"xls"},
                @{@"data": @"504B0304", @"ext": @"xlsx"},
                @{@"data": @"504B030414000600", @"ext": @"xlsx"},
                @{@"data": @"006E1EF0", @"ext": @"ppt"},
                @{@"data": @"0F00E803", @"ext": @"ppt"},
                @{@"data": @"A0461DF0", @"ext": @"ppt"},
                @{@"data": @"FDFFFFFF0E000000", @"ext": @"ppt"},
                @{@"data": @"FDFFFFFF1C000000", @"ext": @"ppt"},
                @{@"data": @"FDFFFFFF43000000", @"ext": @"ppt"},
                @{@"data": @"504B0304", @"ext": @"pptx"},
                @{@"data": @"504B030414000600", @"ext": @"pptx"},
                @{@"data": @"D0CF11E0A1B11AE1", @"ext": @"pps"},
                @{@"data": @"504B0304140006", @"ext": @"ppsx"},
                ];
    });
    
    NSString *hexString = [self HexStringFromBytes:data.bytes andLength:data.length];
    
    NSString *result = nil;
    for(NSDictionary *d in map) {
        NSInteger skip = [d[@"skip"] integerValue];
        NSString *s = hexString;
        if(skip) {
            if(data.length < skip) {
                continue;
            }
            s = [hexString substringFromIndex:skip];
        }
        if([s hasPrefix:d[@"data"]]) {
            result = d[@"ext"];
            break;
        }
    }
    
    return result;
}

+ (NSString *)HexStringFromBytes:(const void *)bytes andLength:(NSUInteger)length
{
    char tmpChars[length * 2];
    for (NSUInteger i = 0; i < length; i++) {
        UInt8 *ch = (UInt8 *)bytes + i;
        UInt8 value = (*ch)>>4;
        tmpChars[i*2] = (value>=0x0A)?('A'+ value - 0x0A):('0'+ value);
        value = (*ch)&0x0F;
        tmpChars[i*2 + 1] = (value>=0x0A)?('A'+ value - 0x0A):('0'+ value);
    }
    return [[NSString alloc] initWithBytes:tmpChars length:length*2 encoding:NSUTF8StringEncoding];
}

@end
