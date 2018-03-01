//
//  CTMIMETypeGetter.h
//  CTWebServer
//
//  Created by ctinus on 2018/3/1.
//  Copyright © 2018年 ChenTong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CTMIMETypeGetter : NSObject
+ (NSString *)MIMETypeForFile:(NSString *)filePath;
@end
