//
//  LocalHttpRequest.m
//  MOA
//
//  Created by ChenTong on 2016/12/9.
//  Copyright © 2016年 ChenTong. All rights reserved.
//

#import "LocalHttpRequest.h"
#import <UIKit/UIKit.h>

#define ISIOS8   ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface LocalHttpRequest ()
@property (nonatomic, nullable) NSURLComponents *URLComponents;
@property (nonatomic, nullable) NSDictionary *queryItems;

@end

@implementation LocalHttpRequest

-(NSInteger)contentLength
{
    return [self.allHTTPHeaderFields[@"Content-Length"] longLongValue];
}

-(NSURLComponents *)URLComponents
{
    if (_URLComponents == nil) {
        _URLComponents = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:YES];
    }
    return _URLComponents;
}

-(NSDictionary *)queryItems
{
    if (_queryItems == nil) {
        NSMutableDictionary *queryItems = [NSMutableDictionary dictionaryWithCapacity:1];
        if (ISIOS8) {
            for (NSURLQueryItem *item in self.URLComponents.queryItems) {
                if (item.name == nil) {
                    NSAssert(0, @"参数错误");
                    continue;
                }
                
                if (queryItems[item.name]) {
                    NSAssert(0, @"参数重复");
                    continue;
                }
                queryItems[item.name] = item.value;
            }
        }else
        {
            NSString *queryString = self.URLComponents.query;
            NSArray *querys = [queryString componentsSeparatedByString:@"&"];
            for (NSString *query in querys) {
                NSArray *queryItem = [query componentsSeparatedByString:@"="];
                if (queryItem.count >=2) {
                    if (queryItems[queryItem[0]]) {
                        NSAssert(0, @"参数重复");
                        continue;
                    }
                    queryItems[queryItem[0]] = queryItem[1];
                }else
                {
                    NSAssert(0, @"参数错误");
                    continue;
                }
            }
        }
        _queryItems = queryItems;
    }
    return _queryItems;
}

@end
