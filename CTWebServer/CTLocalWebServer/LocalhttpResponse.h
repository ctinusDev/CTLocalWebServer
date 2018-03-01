//
//  LocalhttpResponse.h
//  MOA
//
//  Created by ChenTong on 2016/12/9.
//  Copyright © 2016年 ChenTong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocalhttpResponse : NSObject


@property (nonatomic, nullable) CFDataRef headerMessage;
@property (nonatomic, nullable) id content;
@property (nonatomic, assign) int64_t contentLength;

@end
