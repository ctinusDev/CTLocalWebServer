//
//  ViewController.m
//  CTWebServer
//
//  Created by ChenTong on 2016/12/9.
//  Copyright © 2016年 ChenTong. All rights reserved.
//

#import "ViewController.h"
#import "LocalWebServer.h"
#import "CTMIMETypeGetter.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[LocalWebServer shareInstance] startWithHandleBlock:^NSError *(NSFileHandle *httpHandle, LocalHttpRequest * _Nullable request) {
        NSString *path = request.URLComponents.path;
        if ([path isEqualToString:[NSString stringWithFormat:@"/main"]]) {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"main" ofType:@"html"];
            NSString *string = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];

            [httpHandle responseWithStatusCode:200 MIMEType:@"text/html" content:string];
            
            return nil;
        }else if ([path isEqualToString:[NSString stringWithFormat:@"/getfile"]]) {
            NSString *name = request.queryItems[@"name"];
            if ([name isKindOfClass:[NSString class]] == NO) {
                NSLog(@"Error: parameter error");
                return [NSError errorWithDomain:NSCocoaErrorDomain code:503 userInfo:@{@"message":@"parameter error"}];
            }
            NSString *type = [name pathExtension];
            name = [name stringByDeletingPathExtension];
            NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:type];
            if (filePath == nil) {
                NSLog(@"Error: Local file not Exist");
                return [NSError errorWithDomain:NSCocoaErrorDomain code:404 userInfo:@{@"message":@"Local file not Exist"}];
            }
            
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            NSString *fileNameField = [NSString stringWithFormat:@"attachment;filename*=UTF-8''%@",filePath.lastPathComponent];
            [httpHandle responseWithStatusCode:200 MIMEType:[CTMIMETypeGetter MIMETypeForFile:filePath] extraHeaderFields:@{@"Content-Disposition":fileNameField} content:data];
            
            return nil;
        }
        
        NSLog(@"Error: UnSupport Request:%@",request);
        [httpHandle responseNOTFound];
        return nil;
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
