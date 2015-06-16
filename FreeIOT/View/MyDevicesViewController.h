//
//  MyDevicesViewController.h
//  OutletApp
//
//  Created by liming_llm on 15/3/14.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyDevicesViewController : UIViewController

@property (retain, nonatomic) IBOutlet UICollectionView *deviceGrid;

@property (copy, nonatomic)          NSString         *accessToken;

@property (retain, nonatomic) IBOutlet UIRefreshControl *refreshControl;

@property (nonatomic, retain) IBOutlet UINavigationItem *barItem;

@end
