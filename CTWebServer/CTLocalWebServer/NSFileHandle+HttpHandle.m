//
//  NSFileHandle+HttpHandle.m
//  MOA
//
//  Created by ChenTong on 2016/12/9.
//  Copyright © 2016年 ChenTong. All rights reserved.
//

#import "NSFileHandle+HttpHandle.h"
#import <objc/runtime.h>

static char *kRequestMessage = "kRequestMessage";
static char *kRequest = "kRequest";
static char *kResponse = "kResponse";
static char *kHandleRequestBlock = "kHandleRequestBlock";
static char *kSemaphore = "kSemaphore";

static NSInteger kTruncateSize = 8*1024*1024;

@implementation NSFileHandle (HttpHandle)
@dynamic request;
@dynamic response;
@dynamic handleRequestBlock;
//@dynamic semaphore;

#pragma mark - GETTER
-(CFHTTPMessageRef)requestMessage
{
    CFHTTPMessageRef _requestMessage = (__bridge CFHTTPMessageRef)(objc_getAssociatedObject(self, kRequestMessage));
    if (_requestMessage == NULL) {
        _requestMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
        objc_setAssociatedObject(self, kRequestMessage, (__bridge id)(_requestMessage), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return _requestMessage;
}

-(void)setHandleRequestBlock:(HandleRequestBlock)handleRequestBlock
{
    objc_setAssociatedObject(self, kHandleRequestBlock, handleRequestBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(HandleRequestBlock)handleRequestBlock
{
    HandleRequestBlock block = objc_getAssociatedObject(self, kHandleRequestBlock);

    return block;
}

-(LocalHttpRequest *)request{
    LocalHttpRequest *_request = objc_getAssociatedObject(self, kRequest);
    if (!_request) {
        //根据请求类型判断Request
        _request = [[LocalHttpRequest alloc] init];
        objc_setAssociatedObject(self, kRequest, _request, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return _request;
    
}

-(LocalhttpResponse *)response{
    LocalhttpResponse *_response = objc_getAssociatedObject(self, kResponse);
    if (!_response) {
        _response = [[LocalhttpResponse alloc] init];
        objc_setAssociatedObject(self, kResponse, _response, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return _response;
}

//-(dispatch_semaphore_t)semaphore
//{
//    dispatch_semaphore_t se = objc_getAssociatedObject(self, kSemaphore);
//    if (se == NULL) {
//        se = dispatch_semaphore_create(0);
//        objc_setAssociatedObject(self, kSemaphore, se, OBJC_ASSOCIATION_ASSIGN);
//    }
//
//    return se;
//}

#pragma mark - Data Handle
-(void)waitAndReceiveData
{
    //Attach Incoming Data Listener
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveIncomingDataNotification:) name:NSFileHandleDataAvailableNotification object:self];
    [self waitForDataInBackgroundAndNotify];
    NSLog(@"%@ waitAndReceiveData",self);
}

-(void) receiveIncomingDataNotification:(NSNotification *)notification{
    NSFileHandle *incomingFileHandle = [notification object];
    NSData *data = [incomingFileHandle availableData];
    NSLog(@"%@ receiveIncomingDataNotification DataLength:%zd",self,data.length);
    
    if (data.length == 0) {
        if (self.request.isHttpHeadCompleted && ![self.request.HTTPMethod isEqualToString:@"POST"]) {
            [self handleRequest];
        }else if (self.request.isHttpHeadCompleted && self.request.isHttpBodyCompleted)
        {
            [self handleRequest];
        }else
        {
            //error or empty request
            [self closeFileHandle];
        }
        return;
    }
    
    CFHTTPMessageAppendBytes(self.requestMessage, [data bytes], [data length]);
    if (!self.request.isHttpHeadCompleted){
        if (CFHTTPMessageIsHeaderComplete(self.requestMessage)) {
            self.request.isHttpHeadCompleted = YES;
            self.request.URL = (__bridge NSURL * _Nullable)(CFHTTPMessageCopyRequestURL(self.requestMessage));
            self.request.HTTPMethod = (__bridge NSString * _Nullable)(CFHTTPMessageCopyRequestMethod(self.requestMessage));
            self.request.allHTTPHeaderFields = (__bridge NSDictionary<NSString *,NSString *> * _Nullable)(CFHTTPMessageCopyAllHeaderFields(self.requestMessage));
            
            if ([self receivedBodyData]) {
                [self handleRequest];
            }else
                [incomingFileHandle waitForDataInBackgroundAndNotify];
        }
        else{
            [incomingFileHandle waitForDataInBackgroundAndNotify];
        }
    }else{
        
        if ([self receivedBodyData]) {
            [self handleRequest];
        }else
            [incomingFileHandle waitForDataInBackgroundAndNotify];
    }
}

-(BOOL) receivedBodyData
{
    if (![self.request.HTTPMethod isEqualToString:@"POST"]) {
        return YES;
    }
    
    CFDataRef dataRef = CFHTTPMessageCopyBody(self.requestMessage);
    unsigned long long dataLength = CFDataGetLength(dataRef);
    if (dataLength >= self.request.contentLength) {
        self.request.isHttpBodyCompleted = YES;
        self.request.bodyData = (__bridge NSData * _Nullable)(dataRef);
        
        return YES;
    }
    return NO;
}

-(void) handleRequest
{
    NSString *path = self.request.URLComponents.path;
    if (path == nil) {
        NSLog(@"Error: Wrong request:%@",self.request);
        return;
    }
    NSLog(@"Handleing Request:%@",self.request.URL);
    if (self.handleRequestBlock) {
        self.handleRequestBlock(self, self.request);
    }
    
    return;
    
    
    
    
    
    
    static NSDictionary *selectorDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        selectorDict = @{@"/getfile":@"handleFileRequest",
                         @"/mainScreen":@"handleShowScreen",
                         @"/mainScreen/refresh":@"handleMainScreenRefresh",
                         @"/mainScreen/click":@"handleMainScreenClicked",
                         @"/mainScreen/inputText/":@"handleMainScreenInputText"
                         };
    });
    
    NSString *selectorString = selectorDict[path];
    if (selectorString == nil) {
        NSLog(@"Error: UnSupport Request:%@",self.request);
        [self responseNOTFound];
        return;
    }
    
    NSError *error = nil;
    if ([self respondsToSelector:NSSelectorFromString(selectorString)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        error = [self performSelector:NSSelectorFromString(selectorString)];
#pragma clang diagnostic pop
    }else
    {
        NSAssert(0, 0);
    }

    if (error) {
        [self handleErrorRequest:error];
    }
}

-(void) handleErrorRequest:(NSError *)error
{
    NSDictionary *userInfo = error.userInfo;
    [self responseErrorWithStatusCode:error.code message:userInfo[@"message"]];
}

#pragma mark - Response Handle
-(void) responseNOTFound
{
    NSString *notFoundHtml = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"404" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
    [self responseErrorWithStatusCode:404 message:notFoundHtml];
}

-(void) responseErrorWithStatusCode:(NSInteger)statusCode message:(NSString *)message
{
    [self responseWithStatusCode:statusCode MIMEType:@"text/plain" content:message];
}

-(void) responseWithStatusCode:(NSInteger)statusCode MIMEType:(nullable NSString *)MIMEType content:(id)contentData
{
    [self responseWithStatusCode:statusCode MIMEType:MIMEType extraHeaderFields:nil content:contentData];
}

-(void) responseWithStatusCode:(NSInteger)statusCode MIMEType:(nullable NSString *)MIMEType extraHeaderFields:(NSDictionary *)extraHeaderFields content:(id _Nullable )contentData
{
    self.response.headerMessage = [self getHeaderDataWithWithStatusCode:statusCode MIMEType:MIMEType extraHeaderFields:extraHeaderFields content:contentData];
    self.response.content = contentData;
    
    //Sending Response
    [self sendResponse];
}

-(CFDataRef) getHeaderDataWithWithStatusCode:(NSInteger)statusCode MIMEType:(nullable NSString *)MIMEType extraHeaderFields:(NSDictionary *)extraHeaderFields content:(id)contentData
{
    //Create HTTP Response
    NSInteger responseCode = statusCode;
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, responseCode, NULL, kCFHTTPVersion1_1);
    //Add Response header fields
    CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Type", (__bridge CFStringRef)(MIMEType?:@"text/plain"));
    CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Connection", (CFStringRef)@"close");
    //Add Data Length in header fields
    int64_t length = 0;
    if ([contentData isKindOfClass:[NSString class]]) {
        NSData *data = [contentData dataUsingEncoding:NSUTF8StringEncoding];
        length = [data length];
    }
    else if ([contentData isKindOfClass:[NSData class]]) {
        length = [contentData length];
    }else if([contentData isKindOfClass:[NSFileHandle class]])
    {
        NSString *fileNameFiled = [NSString stringWithFormat:@"attachment;filename*=UTF-8''%@",[NSUUID UUID].UUIDString];
        CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Disposition", (__bridge CFStringRef)fileNameFiled);
        
        length = [(NSFileHandle *)contentData seekToEndOfFile];
    }
    
    NSString *dataLength = [NSString stringWithFormat:@"%zd", length];
    
    self.response.contentLength = length;
    
    CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (__bridge CFStringRef)dataLength);
    
    [extraHeaderFields enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSAssert([key isKindOfClass:[NSString class]], nil);
        NSAssert([obj isKindOfClass:[NSString class]], nil);
        if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
            CFHTTPMessageSetHeaderFieldValue(response, (__bridge CFStringRef)key, (__bridge CFStringRef)obj);
        }
    }];
    
    //Serialise HTTP Response in Data
    CFDataRef headerData = CFHTTPMessageCopySerializedMessage(response);

    return headerData;
}


#pragma mark - Send Data

-(void) sendResponse{
    BOOL success = [self sendHeaderData:self.response.headerMessage];
    if (success) {
        [self sendBodyData:self.response.content];
    }
}

-(BOOL) sendHeaderData:(CFDataRef)headerData
{
    //Write HTTP Header Data
    NSAssert(headerData, nil);
    return [self sendNSData:(__bridge NSData*)headerData];
}

-(void)sendBodyData:(id)bodyData
{
    __weak typeof(self) weakself = self;
    if ([bodyData isKindOfClass:[NSString class]]) {
        NSData *data = [bodyData dataUsingEncoding:NSUTF8StringEncoding];
        [self sendNSData:data];
    }
    else if ([bodyData isKindOfClass:[NSData class]]) {
        [self sendNSData:bodyData];
    }
    else if([bodyData isKindOfClass:[NSFileHandle class]])
    {
        NSFileHandle *fileHandle = (NSFileHandle *)bodyData;
        @autoreleasepool {
            NSData *readData = [fileHandle readDataOfLength:kTruncateSize];
            
            BOOL success = [self sendNSData:readData];
            if (success) {
                if (fileHandle.offsetInFile < weakself.response.contentLength)
                    [weakself sendBodyData:fileHandle];
                else{
                    //write finish
                    [weakself closeFileHandle];
                }
            }else{
                [weakself closeFileHandle];
            }
        }
    }else{
        NSAssert(0, 0);
    }
}

-(BOOL)sendNSData:(NSData *)data
{
    __block BOOL success = NO;
    //Write Response Data
    dispatch_semaphore_t se = dispatch_semaphore_create(0);
    @autoreleasepool {
        dispatch_data_t buffer = dispatch_data_create(data.bytes, data.length, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [data self];// Keeps ARC from releasing data too early
        });
        
        @try {
            NSLog(@"fileDescriptor:%d wirite buffer length: %ld",self.fileDescriptor,dispatch_data_get_size(buffer));

            dispatch_write(self.fileDescriptor, buffer, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(dispatch_data_t  _Nullable data, int error) {
                @autoreleasepool {
                    
                    if (error == 0 && data == NULL) {
                        success = YES;
                    }else
                    {
                        success = NO;
                        NSLog(@"Error while writing to socket %i: %s (%i)", self.fileDescriptor, strerror(error), error);
                    }
                }
                
                dispatch_semaphore_signal(se);
            });
        } @catch (NSException *exception) {
            NSLog(@"%@",exception);
            dispatch_semaphore_signal(se);
        } @finally {
            
        }
    }
    
    dispatch_semaphore_wait(se, DISPATCH_TIME_FOREVER);
    
    return success;
}

#pragma mark - File Handle close
-(void) closeFileHandle
{
    //Close file handler and Remove Listeners
    [self closeFile];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:self];
}

@end
