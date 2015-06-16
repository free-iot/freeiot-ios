//
//  HttpApi.h
//  OutletApp
//
//  Created by liming_llm on 15/3/14.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#ifndef OutletApp_HttpApi_h
#define OutletApp_HttpApi_h

@interface HttpApi : NSObject

//接收从服务器返回数据。
@property (strong,  nonatomic) NSMutableData *data;

-(void) request:(NSString *)reqUrl content:(NSString *)content;

@end

@interface NSString (URL)

- (NSString *)URLEncodedString;
- (NSString *)URLDecodedString;

@end


#endif
