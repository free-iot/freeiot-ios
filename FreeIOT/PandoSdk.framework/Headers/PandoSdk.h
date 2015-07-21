//
//  PandoSdk.h
//  PandoSdk
//
//  Created by liming_llm on 15/3/26.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for PandoSdk.
FOUNDATION_EXPORT double PandoSdkVersionNumber;

//! Project version string for PandoSdk.
FOUNDATION_EXPORT const unsigned char PandoSdkVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <PandoSdk/PublicHeader.h>


@protocol  PandoSdkDelegate;

@interface PandoSdk : NSObject

- (instancetype)initWithDelegate:(id<PandoSdkDelegate>) delegate;

- (void)configDeviceToWiFi:(NSString *)ssid withPassword:(NSString *)password isHidden:(BOOL)isHidden;

- (void)stopConfig;

@end




@protocol  PandoSdkDelegate<NSObject>

@optional

- (void)pandoSdk:(PandoSdk *)pandoSdk didConfigDeviceToWiFi:(NSString *)bssid deviceKey:(NSString *) deviceKey error:(NSError *)error;

- (void)pandoSdk:(PandoSdk *)pandoSdk didStopConfig:(NSString *)resault error:(NSError *)error;


@end





