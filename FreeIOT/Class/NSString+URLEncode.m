//
//  NSString+URLEncode.m
//  OutletApp
//
//  Created by liming_llm on 15/3/19.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "NSString+URLEncode.h"

@implementation NSString (URLEncode)

- (NSString *)URLEncodedString
{
  NSString *result = ( NSString *)
  CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                (CFStringRef)self,
                                NULL,
                                CFSTR("!*();+$,%#[] "),
                                kCFStringEncodingUTF8));
  return result;
}

- (NSString*)URLDecodedString
{
  NSString *result = ( NSString *)
  CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                        (CFStringRef)self,
                                        CFSTR(""),
                                        kCFStringEncodingUTF8));
  return result;
}

@end