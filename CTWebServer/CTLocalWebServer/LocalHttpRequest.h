//
//  LocalHttpRequest.h
//  MOA
//
//  Created by ChenTong on 2016/12/9.
//  Copyright © 2016年 ChenTong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LocalHttpRequest;
typedef NSError *(^HandleRequestBlock)(NSFileHandle * _Nullable httpHandle, LocalHttpRequest * _Nullable request);

@interface LocalHttpRequest : NSObject
@property (nonatomic, assign) BOOL isHttpHeadCompleted;
@property (nonatomic, assign) BOOL isHttpBodyCompleted;

@property (nullable, copy) NSURL *URL;
@property (nullable, copy) NSString *HTTPMethod;
@property (nullable, copy) NSDictionary<NSString *, NSString *> *allHTTPHeaderFields;

@property (nonatomic, readonly) NSInteger contentLength;
@property (nonatomic, readonly, nullable) NSURLComponents *URLComponents;
@property (nonatomic, readonly, nullable) NSDictionary *queryItems;
@property (nullable, copy) NSData *bodyData;

@end
