//
//  DeviceDetailViewController.h
//  OutletApp
//
//  Created by liming_llm on 15/3/19.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceDetailViewController : UIViewController

@property (copy, nonatomic)          NSString     *accessToken;

@property (copy, nonatomic)          NSString     *identifier;

@property (copy, nonatomic)          NSString     *url;

@property (copy, nonatomic)          NSString     *dtitle;

@property (nonatomic, retain) IBOutlet UINavigationItem *barItem;

@end

#if 0
typedef void (* FUNCMD)(NSDictionary *);

typedef struct _functionString
{
    char *handlerName;
    void (*FUNCMD) (NSDictionary *);
    
} FunCmd;

FUNCMD getCurrentStatus(NSDictionary *handle);
#endif
