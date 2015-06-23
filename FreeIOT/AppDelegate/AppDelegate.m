//
//  AppDelegate.m
//  OutletApp
//
//  Created by liming_llm on 15/3/11.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "AppDelegate.h"
#import "Const.h"
#import "CHKeychain.h"


NSMutableDictionary *errorCode;
NSString *HOST_URL = HOST_URL_FORMAL;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
  
#if 0
  if (launchOptions != nil) {
    //opened from a push notification when the app is closed
    NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo != nil) {
      NSString *message = [[userInfo objectForKey:@"aps"]objectForKey:@"alert"];
      
      UIAlertView *createUserResponseAlert = [[UIAlertView alloc] initWithTitle:@"LAU提示"
                                        message:message
                                       delegate:nil
                                  cancelButtonTitle:LocalStr(@"STR_OK")
                                  otherButtonTitles:nil, nil];
      
      [createUserResponseAlert show];
    }
    
  }
#endif
  
#if 0
  // Register for push notifications
  
  if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
    // iOS 8 Notifications
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    
    [application registerForRemoteNotifications];
  }
  else {
    // iOS < 8 Notifications
    [application registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
  }
#endif
  
  
  errorCode = [NSMutableDictionary dictionary];
  
  [errorCode setObject:LocalStr(@"系统错误") forKey:[NSNumber numberWithInt:10001]];
  [errorCode setObject:LocalStr(@"系统错误") forKey:[NSNumber numberWithInt:10002]];
  [errorCode setObject:LocalStr(@"系统错误") forKey:[NSNumber numberWithInt:10003]];
  [errorCode setObject:LocalStr(@"系统错误") forKey:[NSNumber numberWithInt:10004]];
  [errorCode setObject:LocalStr(@"系统错误") forKey:[NSNumber numberWithInt:10005]];
  [errorCode setObject:LocalStr(@"权限错误") forKey:[NSNumber numberWithInt:10006]];
  [errorCode setObject:LocalStr(@"未知指令") forKey:[NSNumber numberWithInt:10007]];
  [errorCode setObject:LocalStr(@"参数错误") forKey:[NSNumber numberWithInt:10008]];
  [errorCode setObject:LocalStr(@"发送错误") forKey:[NSNumber numberWithInt:10009]];
  [errorCode setObject:LocalStr(@"请重新登录") forKey:[NSNumber numberWithInt:10010]];
  [errorCode setObject:LocalStr(@"设备不存在") forKey:[NSNumber numberWithInt:10011]];
  [errorCode setObject:LocalStr(@"密码错误") forKey:[NSNumber numberWithInt:10012]];
  [errorCode setObject:LocalStr(@"注册的电话号码已存在") forKey:[NSNumber numberWithInt:10013]];
  [errorCode setObject:LocalStr(@"手机验证码过期") forKey:[NSNumber numberWithInt:10014]];
  [errorCode setObject:LocalStr(@"手机验证码错误") forKey:[NSNumber numberWithInt:10015]];
  [errorCode setObject:LocalStr(@"用户名无效") forKey:[NSNumber numberWithInt:10016]];
  [errorCode setObject:LocalStr(@"未知属性") forKey:[NSNumber numberWithInt:10017]];
  [errorCode setObject:LocalStr(@"设备不在线") forKey:[NSNumber numberWithInt:10018]];
  [errorCode setObject:LocalStr(@"请求格式不正确") forKey:[NSNumber numberWithInt:10019]];
  [errorCode setObject:LocalStr(@"设备已经绑定") forKey:[NSNumber numberWithInt:10020]];
  
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  
  //[UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)pToken {
  
  NSLog(@"regisger success:%@", pToken);
  
  //注册成功，将deviceToken保存，因为在写向ios推送信息的服务器端程序时要用到这个
  
  NSUserDefaults *deviceDefaults = [NSUserDefaults standardUserDefaults];
  
  NSString *token = [[pToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
  
  token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
  
  [deviceDefaults setObject:token forKey:KEY_PUSH_TOKEN];
  
  NSLog(@"push token = %@", token);
  
  [deviceDefaults synchronize];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
  
  // 处理推送消息
  
  NSLog(@"userInfo == %@",userInfo);
  
#if 0
  NSData *jsonData= [NSJSONSerialization dataWithJSONObject:userInfo options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  
  //NSString *message = [[userInfo objectForKey:@"aps"]objectForKey:@"alert"];
  
  UIAlertView *createUserResponseAlert = [[UIAlertView alloc] initWithTitle:@"提示"
                                    message:jsonString
                                   delegate:self
                              cancelButtonTitle:@"取消"
                              otherButtonTitles: @"确认", nil];
  
  [createUserResponseAlert show];
#endif
  
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{

#if 0
  NSString *message = [[userInfo objectForKey:@"aps"]objectForKey:@"alert"];
  
  UIAlertView *createUserResponseAlert = [[UIAlertView alloc] initWithTitle:@"DF提示"
                                    message:message
                                   delegate:nil
                              cancelButtonTitle:LocalStr(@"STR_OK")
                              otherButtonTitles:nil, nil];
  
  [createUserResponseAlert show];
#endif
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  
  NSLog(@"Regist fail%@",error); 
  
}

@end
