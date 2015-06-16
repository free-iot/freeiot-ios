//
//  LoginViewController.h
//  OutletApp
//
//  Created by liming_llm on 15/3/14.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIButton     *loginBtn;

@property (nonatomic, retain) IBOutlet UITextField  *usernameText;

@property (nonatomic, retain) IBOutlet UITextField  *passwordText;

@property (nonatomic, retain) IBOutlet UIButton     *registerBtn;

@property (nonatomic, retain) IBOutlet UIButton     *forgetBtn;

@end
