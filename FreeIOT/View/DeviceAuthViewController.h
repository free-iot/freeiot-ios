//
//  DeviceAuthViewController.h
//  OutletApp
//
//  Created by liming_llm on 15/5/4.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceAuthViewController : UIViewController

@property (retain, nonatomic) IBOutlet UICollectionView *userGrid;

@property (copy, nonatomic)          NSString         *accessToken;
@property (copy, nonatomic)          NSString         *identifier;


@property (retain, nonatomic) IBOutlet UIRefreshControl *refreshControl;

@property (nonatomic, retain) IBOutlet UINavigationItem *barItem;

@end
