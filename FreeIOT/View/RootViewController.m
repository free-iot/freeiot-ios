//
//  RootViewController.m
//  OutletApp
//
//  Created by liming_llm on 15/4/28.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)awakeFromNib {
  self.menuPreferredStatusBarStyle = UIStatusBarStyleLightContent;
  self.contentViewShadowColor = [UIColor blackColor];
  self.contentViewShadowOffset = CGSizeMake(0, 0);
  self.contentViewShadowOpacity = 0.6;
  self.contentViewShadowRadius = 12;
  self.contentViewShadowEnabled = YES;
  
  self.contentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"contentViewController"];
  self.leftMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ProfileMenuViewController"];
  self.rightMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ProfileMenuViewController"];
  self.backgroundImage = [UIImage imageNamed:@"menu"];
  self.delegate = self;
}

#pragma mark -
#pragma mark RESideMenu Delegate

- (void)sideMenu:(RESideMenu *)sideMenu willShowMenuViewController:(UIViewController *)menuViewController {
  NSLog(@"willShowMenuViewController: %@", NSStringFromClass([menuViewController class]));
}

- (void)sideMenu:(RESideMenu *)sideMenu didShowMenuViewController:(UIViewController *)menuViewController {
  NSLog(@"didShowMenuViewController: %@", NSStringFromClass([menuViewController class]));
}

- (void)sideMenu:(RESideMenu *)sideMenu willHideMenuViewController:(UIViewController *)menuViewController {
  NSLog(@"willHideMenuViewController: %@", NSStringFromClass([menuViewController class]));
}

- (void)sideMenu:(RESideMenu *)sideMenu didHideMenuViewController:(UIViewController *)menuViewController {
  NSLog(@"didHideMenuViewController: %@", NSStringFromClass([menuViewController class]));
}

@end

