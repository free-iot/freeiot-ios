//
//  AddDeviceViewController.h
//  OutletApp
//
//  Created by liming_llm on 15/3/15.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddDeviceViewController : UIViewController

@property(nonatomic, retain) IBOutlet UITextField *ssidText;
@property(nonatomic, retain) IBOutlet UITextField *passText;
@property(nonatomic, retain) IBOutlet UIButton *bindBtn;
@property(nonatomic, retain) IBOutlet UIButton *configBtn;
@property(nonatomic, retain) IBOutlet UINavigationItem *barItem;
@property(nonatomic, copy) NSDictionary *productInfo;
@property(nonatomic, copy) NSString *accessToken;
@property(copy, nonatomic) NSString *bssid;

@end
