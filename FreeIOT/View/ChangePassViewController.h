//
//  ChangePassViewController.h
//  OutletApp
//
//  Created by liming_llm on 15/5/3.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface ChangePassViewController : UIViewController<MBProgressHUDDelegate>

@property (nonatomic, retain) IBOutlet UITextField  *passText;
@property (nonatomic, retain) IBOutlet UITextField  *freshPassText;
@property (nonatomic, retain) IBOutlet UITextField  *confirmText;
@property (nonatomic, retain) IBOutlet UIButton     *okBtn;

@end
