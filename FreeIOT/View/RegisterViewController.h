//
//  RegisterViewController.h
//  OutletApp
//
//  Created by liming_llm on 15/3/22.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIButton         *authcodeBtn;

@property (nonatomic, retain) IBOutlet UITextField      *usernameText;

@property (nonatomic, retain) IBOutlet UITextField      *passwordText;

@property (nonatomic, retain) IBOutlet UITextField      *authcodeText;

@property (nonatomic, retain) IBOutlet UIButton         *registerBtn;

@property (nonatomic, retain) IBOutlet UINavigationItem *barItem;

@property (nonatomic, retain)          NSString         *titleStr;

@end
