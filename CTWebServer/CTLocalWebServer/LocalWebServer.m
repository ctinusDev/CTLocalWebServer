//
//  LocalWebServer.m
//  MOA
//
//  Created by ChenTong on 2016/12/9.
//  Copyright © 2016年 ChenTong. All rights reserved.
//

#import "LocalWebServer.h"
#import <sys/socket.h>
//For #defines like AF_INET protocol family.

#import <netinet/in.h>
//Socket address structure and others defined parameter values.

#import <CFNetwork/CFNetwork.h>
//Core Network APIs (need to add into project).

#define kCDLocalWebServerPort @(8090)

@interface LocalWebServer()
{
    CFSocketRef socket;
    NSFileHandle *listeningHandle;
    
    NSThread *dealThread;
    
    HandleRequestBlock handleRequestBlock;
}

@property (nonatomic, assign) BOOL running;

@end

@implementation LocalWebServer

+(instancetype) shareInstance{
    static LocalWebServer *webServer = nil;
    if (!webServer) {
        webServer = [[LocalWebServer alloc] init];
    }
    return webServer;
}

-(instancetype)init
{
    if (self = [super init]) {
        dealThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadCycle) object:nil];
        dealThread.name = @"LocalWebServerThread";
        [dealThread start];
    }
    return self;
}

-(void) timeHandle:(NSTimer *)timer
{
}

-(void)threadCycle
{
    NSTimer *time = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timeHandle:) userInfo:nil repeats:YES];
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    [currentRunLoop addTimer:time forMode:NSRunLoopCommonModes];
    [currentRunLoop run];
}

-(void) startWithHandleBlock:(HandleRequestBlock)handleBlock
{
    handleRequestBlock = handleBlock;
    if ([NSThread currentThread] != dealThread) {
        [self performSelector:@selector(startWithHandleBlock:) onThread:dealThread withObject:handleBlock waitUntilDone:NO];
        return;
    }
    
    if (self.running) {
        [self stop];
    }
    
    //Create Socket object
    socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, NULL, NULL);
    if (!socket) {
        NSLog(@"[Proxy Server] Unable to create socket.");
        return;
    }
    
    //Get Native Socket
    int reuse = true;
    int fileDescriptor = CFSocketGetNative(socket);
    if (setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR, (void *)&reuse, sizeof(int))){
        NSLog(@"[Proxy Server] Unable to set socket options.");
        return;
    }
    
    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_ANY);
    NSInteger portNumber = kCDLocalWebServerPort.integerValue;
    address.sin_port = htons(portNumber);
    CFDataRef addressData = CFDataCreate(NULL, (const UInt8 *)&address, sizeof(address));
    if (CFSocketSetAddress(socket, addressData)){
        NSLog(@"[Proxy Server] Unable to bind socket to address.");
        return;
    }
    [self listening];
    
    self.running = YES;
}

-(void)listening
{
    NSLog(@"LocalWebServer start Listening");
    //Receive Incoming Notification
    //Constructing File Handler
    listeningHandle = [[NSFileHandle alloc] initWithFileDescriptor:CFSocketGetNative(socket) closeOnDealloc:YES];
    //Attach Connection Listener
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveIncomingConnectionNotification:) name:NSFileHandleConnectionAcceptedNotification object:nil];
    [listeningHandle acceptConnectionInBackgroundAndNotify];
}

-(void)receiveIncomingConnectionNotification:(NSNotification *)notification
{
    //Receive File Handler
    NSDictionary *userInfo = [notification userInfo];
    NSFileHandle *incomingFileHandle = [userInfo objectForKey:NSFileHandleNotificationFileHandleItem];
    incomingFileHandle.handleRequestBlock = handleRequestBlock;
    [incomingFileHandle waitAndReceiveData];
    
    // Need to call this func again for other requests
    [listeningHandle acceptConnectionInBackgroundAndNotify];

}

-(void) stop{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (socket) {
        CFSocketInvalidate(socket);
        CFRelease(socket);
        socket = NULL;
    }
    
    if (listeningHandle) {
        [listeningHandle closeFile];
        listeningHandle = nil;
    }
    
    self.running = NO;
    NSLog(@"LocalWebServer stop");
}

-(void)dealloc
{
    [self stop];
}

@end
