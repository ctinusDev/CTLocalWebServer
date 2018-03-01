//
//  LocalWebServer.h
//  MOA
//
//  Created by ChenTong on 2016/12/9.
//  Copyright © 2016年 ChenTong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocalHttpRequest.h"
#import "NSFileHandle+HttpHandle.h"
/*
 share URL Format
  file:   /ip:8090/getfile?value=hash&option=option
 */

@interface LocalWebServerConfig :NSObject
@property (nonatomic, weak) id responser; //用来接受请求响应
@end

@interface LocalWebServer : NSObject

+(instancetype) shareInstance;

-(void) startWithHandleBlock:(HandleRequestBlock)handleBlock;
-(void) stop;

@property (nonatomic, assign, readonly) BOOL running;

@end
