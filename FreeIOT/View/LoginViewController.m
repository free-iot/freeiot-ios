//
//  LoginViewController.m
//  OutletApp
//
//  Created by liming_llm on 15/3/14.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "LoginViewController.h"
#import "MBProgressHUD.h"
#import "Const.h"
#import "NSString+URLEncode.h"
#import "MyDevicesViewController.h"
#import "CHKeychain.h"
#import "RegisterViewController.h"

#define TAG_USER_LOGIN @"user_login"
#define TAG_DEVICE_REGISTER @"device_register"
#define TAG_DEVICE_LOGIN @"device_login"
#define TAG_DEVICE_BIND @"device_bind"


NSString * const kKeyUsernamePassword = @"com.PandoCloud.OutletApp.usernamepassword";
NSString * const kKeyUsername = @"com.PandoCloud.OutletApp.username";
NSString * const kKeyPassword = @"com.PandoCloud.OutletApp.password";
NSString * const kKeyUUID = @"com.PandoCloud.OutletApp.uuid";
NSString * const kKeyPushToken = @"com.PandoCloud.OutletApp.pushtoken";

extern NSMutableDictionary *errorCode;

@interface LoginViewController () <MBProgressHUDDelegate> {
  MBProgressHUD *_HUD;
  NSMutableData *_recvData;
  NSString *_accessToken;
  NSMutableDictionary *_connSet;
}

@end

@implementation LoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  [NSThread sleepForTimeInterval:3.0];   //设置进程停止3秒
  
  _connSet = [NSMutableDictionary dictionary];
  
  [_forgetBtn setTitle:LocalStr(@"FORGET_BTN_TLTLE") forState:UIControlStateNormal];
  [_registerBtn setTitle:LocalStr(@"SIGNUP_BTN_TITLE") forState:UIControlStateNormal];
  
  [_loginBtn setTitle:LocalStr(@"LOGIN_BTN_TITLE") forState:UIControlStateNormal];
  _loginBtn.layer.cornerRadius = 6;
  _loginBtn.layer.masksToBounds = YES;
  [_loginBtn setBackgroundColor:[UIColor grayColor]];
  [_loginBtn setAlpha:0.6];
  [_loginBtn setEnabled:NO];

#if IS_MAIL
  [_usernameText setPlaceholder:LocalStr(@"USERNAME_TEXT_PLACEHOLDER")];
#else
  [_usernameText setPlaceholder:LocalStr(@"USERNAME_TEXT_PLACEHOLDER_PHONE")];
#endif
  
  [_passwordText setPlaceholder:LocalStr(@"PASSWORD_TEXT_PLACEHOLDER")];
  
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(observeTextChange)
                                              name:UITextFieldTextDidChangeNotification
                                            object:_usernameText];
  
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(observeTextChange)
                                              name:UITextFieldTextDidChangeNotification
                                            object:_passwordText];
  
}

-(void)viewDidAppear:(BOOL)animated {
  NSMutableDictionary *usernamepasswdKVPairs = (NSMutableDictionary *)[CHKeychain load:kKeyUsernamePassword];

  if (usernamepasswdKVPairs != nil) {
    UIViewController *myDevVC = [self.storyboard instantiateViewControllerWithIdentifier:@"RootViewController"];
    
    myDevVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    //((MyDevicesViewController *)myDevVC).accessToken = accessToken;
    
    
    [self presentViewController:myDevVC animated:YES completion:nil];
  }
  else {
    NSLog(@"No user record");
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)loginBtnTouchUpInside:(id)sender {
  _recvData = [NSMutableData data];
  
  [_usernameText resignFirstResponder];
  [_passwordText resignFirstResponder];
  
  [self userLogin];
}

- (IBAction)registerBtnTouchUpInside:(id)sender {
  UIViewController *regVC = [self.storyboard instantiateViewControllerWithIdentifier:@"RegisterViewController"];
  
  regVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  ((RegisterViewController *)regVC).titleStr = LocalStr(@"REGISTER_TITLE");
  
  [self presentViewController:regVC animated:YES completion:nil];
}

- (IBAction)forgetBtnTouchUpInside:(id)sender {
  UIViewController *regVC = [self.storyboard instantiateViewControllerWithIdentifier:@"RegisterViewController"];
  
  regVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  ((RegisterViewController *)regVC).titleStr = LocalStr(@"RESET_TITLE");
  
  [self presentViewController:regVC animated:YES completion:nil];
}

- (void)observeTextChange {
  if (_usernameText.text.length > 0 && _passwordText.text.length > 0) {
    [_loginBtn setBackgroundColor:[UIColor redColor]];
    [_loginBtn setEnabled:YES];
  }
  else {
    [_loginBtn setBackgroundColor:[UIColor grayColor]];
    [_loginBtn setAlpha:0.6];
    [_loginBtn setEnabled:NO];
  }
}

- (void)userLogin {
#if IS_MAIL
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:_usernameText.text,
                 @"mail",
                 _passwordText.text,
                 @"password", nil];
#else
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:_usernameText.text,
                 @"mobile",
                 _passwordText.text,
                 @"password", nil];
#endif
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, LOGIN_PATH];
  
  NSLog(@"req = %@\n%@", req, jsonInputString);
  
  [self request:req content:jsonInputString tag:TAG_USER_LOGIN];
  
  _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _HUD.dimBackground = YES;
  _HUD.delegate = self;
  //HUD.labelText = @"正在登录";
}

- (void)deviceRegister {
  NSUserDefaults *deviceDefault = [NSUserDefaults standardUserDefaults];
  
  NSMutableDictionary *UUIDDic = (NSMutableDictionary *)[CHKeychain load:kKeyUUID];
    
  if (UUIDDic == nil) {
    UUIDDic = [NSMutableDictionary dictionary];
    [UUIDDic setObject:[[UIDevice currentDevice].identifierForVendor UUIDString] forKey:kKeyUUID];
    [CHKeychain save:kKeyUUID data:UUIDDic];
    
    
    NSLog(@"no uuid found %@", [[UIDevice currentDevice].identifierForVendor UUIDString]);
  }
  
  NSString *pushToken = [deviceDefault objectForKey:KEY_PUSH_TOKEN];
  
  //将 push token 保存到 keychain 中
  NSMutableDictionary *pushTokenDic = [NSMutableDictionary dictionary];
  if (pushToken != nil) {
    [pushTokenDic setObject:pushToken forKey:KEY_PUSH_TOKEN];
    [CHKeychain save:kKeyPushToken data:pushTokenDic];
  }
  else {
    pushToken = @"";
  }
  
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:DEVICE_PRODUCT_KEY,
                                                                       @"product_key",
                                                                       [UUIDDic objectForKey:kKeyUUID],
                                                                       @"device_code",
                                                                       [NSNumber numberWithInt:2],
                                                                       @"device_type",
                                                                       @"iOS",
                                                                       @"device_module",
                                                                       pushToken,
                                                                       @"ios_device_token",
                                                                       @"0.1.0",
                                                                       @"version", nil];
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, DEVICE_REGSTER_PATH];
  
  NSLog(@"req = %@\n%@", req, jsonInputString);
  
  [self request:req content:jsonInputString tag:TAG_DEVICE_REGISTER];
}

- (void)deviceLogin {
  NSUserDefaults *deviceDefault = [NSUserDefaults standardUserDefaults];
  
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:
                 [deviceDefault objectForKey:KEY_DEVICE_ID],
                 @"device_id",
                 [deviceDefault objectForKey:KEY_DEVICE_SECRET],
                 @"device_secret", nil];
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, DEVICE_LOGIN_PATH];
  
  NSLog(@"req = %@\n%@", req, jsonInputString);
  
  [self request:req content:jsonInputString tag:TAG_DEVICE_LOGIN];
}

- (void)deviceBind {
  NSUserDefaults *deviceDefault = [NSUserDefaults standardUserDefaults];
  
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:
                 [deviceDefault objectForKey:KEY_DEVICE_KEY],
                 @"device_key",nil];
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, BIND_DEVICE_PATH];
  
  NSLog(@"req = %@\n%@", req, jsonInputString);
  
  [self request:req content:jsonInputString tag:TAG_DEVICE_BIND];
}

- (IBAction)viewTouchDown:(id)sender {
  [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

-(void) request:(NSString *)reqUrl content:(NSString *)content tag:(id)tag {
  NSURL *url = [NSURL URLWithString:[reqUrl URLEncodedString]];
  NSString *method = @"GET";
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  
  [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
  [request addValue:PRODUCT_KEY forHTTPHeaderField:@"Product-Key"];
  
  if ([(NSString *)tag isEqualToString:TAG_DEVICE_BIND]) {
    [request addValue:_accessToken forHTTPHeaderField:@"Access-Token"];
  }
  
  if (content != nil) {
    [request setHTTPBody: [content dataUsingEncoding:NSUTF8StringEncoding]];
    method = @"POST";
  }
  
  [request setHTTPMethod:method];
  
  NSOperationQueue *queue = [[NSOperationQueue alloc] init];
  
  NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
  [conn setDelegateQueue:queue];
  [conn start];
  
  [_connSet setObject:conn forKey:tag];
  
  if (conn) {
    NSLog(@"connect ok");
  }
  else {
    NSLog(@"connect error");
  }
}


#pragma mark - NSURLConnection 回调方法
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [_recvData appendData:data];
  
  NSLog(@"connection : didReceiveData");
}

-(void) connection:(NSURLConnection *)connection didFailWithError: (NSError *)error {
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    
    [_HUD hide:YES];
    
    NSLog(@"Error (): %@", [error localizedDescription]);
    
    UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_CONNECT_FAIL")
                                                   message:[error localizedDescription]
                                                  delegate:nil
                                         cancelButtonTitle:LocalStr(@"STR_OK")
                                         otherButtonTitles:nil];
    [temp show];
    
  });
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection {
  NSLog(@"请求完成...");
  
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
  
  NSDictionary *respDic = [NSJSONSerialization JSONObjectWithData:_recvData options:NSJSONReadingMutableLeaves error:nil];
    
  NSUserDefaults *deviceDefaults = [NSUserDefaults standardUserDefaults];
  
  if (respDic != nil) {
    if (connection == [_connSet objectForKey:TAG_USER_LOGIN]) {
      if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
        _accessToken = [[respDic objectForKey:@"data"] objectForKey:@"access_token"];
        
        NSLog(@"%@", _accessToken);
        
        
        if (_accessToken != nil) {
          [deviceDefaults setObject:_accessToken forKey:KEY_ACCESS_TOKEN];
          [deviceDefaults synchronize];
        }
        
        
        
        [CHKeychain delete:kKeyUsernamePassword];
        
        //save username & password to keychain
        NSMutableDictionary *usernamepasswordKVPairs = [NSMutableDictionary dictionary];
        [usernamepasswordKVPairs setObject:_usernameText.text forKey:kKeyUsername];
        [usernamepasswordKVPairs setObject:_passwordText.text forKey:kKeyPassword];
        [CHKeychain save:kKeyUsernamePassword data:usernamepasswordKVPairs];
        
        //查看设备（iPhone）是否注册过，没注册过先进行设备注册，否则直接登录
        if ([deviceDefaults objectForKey:KEY_DEVICE_REGISTERED] == nil ||
          [deviceDefaults objectForKey:KEY_DEVICE_REGISTERED] == NO) {
          [self deviceRegister];
        }
        else {
          NSDictionary *pushTokenDic = (NSDictionary *)[CHKeychain load:kKeyPushToken];
          
          //push token 变更或者 keychain 中不存在，也需要进行设备注册
          if (pushTokenDic == nil) {
            [self deviceRegister];
          }
          else {
            if (![[pushTokenDic objectForKey:KEY_PUSH_TOKEN] isEqualToString:[deviceDefaults objectForKey:KEY_PUSH_TOKEN]]) {
              [self deviceRegister];
            }
            else {
              [self deviceLogin];
            }
          }
        }
      }
      else {
        UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                                       message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                                      delegate:nil
                                             cancelButtonTitle:LocalStr(@"STR_OK")
                                             otherButtonTitles:nil];
        [temp show];
      }
    }
    else if (connection == [_connSet objectForKey:TAG_DEVICE_REGISTER]) {
      
      NSLog(@"device register resp %@", respDic);
      
      if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
        NSDictionary *data = [respDic objectForKey:@"data"];
        
        [deviceDefaults setBool:YES forKey:KEY_DEVICE_REGISTERED];
        
        if (data != nil) {
          NSLog(@"device register %@", data);
          
          [deviceDefaults setObject:[data objectForKey:@"device_id"] forKey:KEY_DEVICE_ID];
          [deviceDefaults setObject:[data objectForKey:@"device_secret"] forKey:KEY_DEVICE_SECRET];
          [deviceDefaults setObject:[data objectForKey:@"device_key"] forKey:KEY_DEVICE_KEY];
        }
        
        [deviceDefaults synchronize];
        
        [self deviceLogin];
      }
      else {
        UIViewController *myDevVC = [self.storyboard instantiateViewControllerWithIdentifier:@"RootViewController"];
        
        myDevVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        //((MyDevicesViewController *)myDevVC).accessToken = accessToken;
        
        
        [self presentViewController:myDevVC animated:YES completion:nil];
      }

    }
    else if (connection == [_connSet objectForKey:TAG_DEVICE_LOGIN]) {
      if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
        if ([deviceDefaults objectForKey:KEY_DEVICE_BINDED] == nil ||
          [deviceDefaults objectForKey:KEY_DEVICE_BINDED] == NO) {
          [self deviceBind];
        }
      }
      else {
        UIViewController *myDevVC = [self.storyboard instantiateViewControllerWithIdentifier:@"RootViewController"];
        
        myDevVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        //((MyDevicesViewController *)myDevVC).accessToken = accessToken;
        
        
        [self presentViewController:myDevVC animated:YES completion:nil];
      }
    }
    else if (connection == [_connSet objectForKey:TAG_DEVICE_BIND]) {
      UIViewController *myDevVC = [self.storyboard instantiateViewControllerWithIdentifier:@"RootViewController"];
      
      myDevVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
      
      //((MyDevicesViewController *)myDevVC).accessToken = accessToken;
      
      
      [self presentViewController:myDevVC animated:YES completion:nil];
    }
  }
  else {
    UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                             message:LocalStr(@"STR_NO_RESPONSE")
                            delegate:nil
                       cancelButtonTitle:LocalStr(@"STR_OK")
                       otherButtonTitles:nil];
    [temp show];
  }
    
    _recvData = [NSMutableData data];
    
  [_HUD hide:YES];
    
  });
}

//https
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
  return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  NSLog(@"didReceiveAuthenticationChallenge %@ %zd", [[challenge protectionSpace] authenticationMethod], (ssize_t) [challenge previousFailureCount]);
  
  if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
    
    [[challenge sender]  useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    
    [[challenge sender]  continueWithoutCredentialForAuthenticationChallenge: challenge];
  }
}



@end
