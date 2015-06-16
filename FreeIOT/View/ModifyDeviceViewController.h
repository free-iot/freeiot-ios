//
//  ModifyDeviceViewController.h
//  OutletApp
//
//  Created by liming_llm on 15/5/4.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface ModifyDeviceViewController : UIViewController<MBProgressHUDDelegate, UIPickerViewDelegate, UITextFieldDelegate,UIPickerViewDataSource>

@property (nonatomic, retain) IBOutlet UITextField      *nameText;
@property (nonatomic, retain) IBOutlet UITextField      *authText;
@property (retain, nonatomic) IBOutlet UIPickerView     *selectView;
@property (retain, nonatomic) IBOutlet UIToolbar        *selectBar;
@property (retain, nonatomic) IBOutlet UIButton         *okBtn;
@property (retain, nonatomic)          NSString         *identifier;
@property (retain, nonatomic)          NSString         *name;


@end
