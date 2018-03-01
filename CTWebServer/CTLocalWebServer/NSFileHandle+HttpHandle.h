//
//  NSFileHandle+HttpHandle.h
//  MOA
//
//  Created by ChenTong on 2016/12/9.
//  Copyright © 2016年 ChenTong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocalHttpRequest.h"
#import "LocalhttpResponse.h"

@interface NSFileHandle (HttpHandle)
@property (nonatomic, readonly) CFHTTPMessageRef _Nullable requestMessage;

@property (nonatomic, strong) LocalhttpResponse * _Nullable response;
@property (nonatomic, strong) LocalHttpRequest * _Nullable request;
@property (nonatomic, copy) HandleRequestBlock _Nullable handleRequestBlock;
//@property (nonatomic, assign, readonly) dispatch_semaphore_t semaphore;

-(void)waitAndReceiveData;

-(void) responseNOTFound;
-(void) responseErrorWithStatusCode:(NSInteger)statusCode message:(NSString *_Nullable)message;
-(void) responseWithStatusCode:(NSInteger)statusCode MIMEType:(nullable NSString *)MIMEType content:(id _Nullable )contentData;
-(void) responseWithStatusCode:(NSInteger)statusCode MIMEType:(nullable NSString *)MIMEType extraHeaderFields:(NSDictionary *_Nullable)extraHeaderFields content:(id _Nullable )contentData;
@end
