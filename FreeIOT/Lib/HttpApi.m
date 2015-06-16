//
//  HttpApi.m
//  OutletApp
//
//  Created by liming_llm on 15/3/14.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpApi.h"
#import "Const.h"

@interface HttpApi()

@end

@implementation HttpApi

-(void) request:(NSString *)reqUrl content:(NSString *)content
{
    NSURL *url = [NSURL URLWithString:[reqUrl URLEncodedString]];
    NSString *method = @"GET";
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue:PRODUCT_KEY forHTTPHeaderField:@"Product-Key"];
    
    if (content != nil)
    {
        [request setHTTPBody: [content dataUsingEncoding:NSUTF8StringEncoding]];
        method = @"POST";
    }
    
    [request setHTTPMethod:method];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [conn setDelegateQueue:queue];
    [conn start];
    
    if (conn)
    {
        NSLog(@"connect ok");
    }
    else
    {
        NSLog(@"connect error");
    }
}

#pragma mark - NSURLConnection 回调方法
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.data appendData:data];
    
    NSLog(@"connection : didReceiveData");
}

-(void) connection:(NSURLConnection *)connection didFailWithError: (NSError *)error
{
    NSLog(@"Error (): %@", [error localizedDescription]);
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection
{
    NSLog(@"请求完成...");
}


@end




@implementation NSString (URL)

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
