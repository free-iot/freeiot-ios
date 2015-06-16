//
//  DevicePermissionViewController.h
//  OutletApp
//
//  Created by liming_llm on 15/3/22.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DevicePermissionViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIPickerView     *selectView;

@property (retain, nonatomic) IBOutlet UIToolbar        *selectBar;

@property (nonatomic, retain) IBOutlet UIButton         *permitBtn;

@property (nonatomic, retain) IBOutlet UITextField      *usernameText;

@property (nonatomic, retain) IBOutlet UITextField      *permitionText;

@property (copy, nonatomic)          NSString         *accessToken;

@property (copy, nonatomic)          NSString         *identifier;

@property (copy, nonatomic)          NSString         *phone;

@property (nonatomic, retain) IBOutlet UINavigationItem *barItem;

@end
