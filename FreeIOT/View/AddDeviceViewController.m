//
//  AddDeviceViewController.m
//  OutletApp
//
//  Created by liming_llm on 15/3/15.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <SystemConfiguration/CaptiveNetwork.h>

#import "AddDeviceViewController.h"
#import "MBProgressHUD.h"
#import "Const.h"
#import "NSString+URLEncode.h"
#import "CHKeychain.h"

#include <PandoSdk/PandoSdk.h>


extern NSString *const kKeyUsernamePassword;
extern NSMutableDictionary *errorCode;
extern NSString *HOST_URL;

@interface AddDeviceViewController () <MBProgressHUDDelegate, PandoSdkDelegate> {
  MBProgressHUD *_HUD;
  MBProgressHUD *_checkWifiHud;
  UIAlertView *_exitAlert;
  UIAlertView *_passEmptyAlert;
    UIAlertView *_ssidEmptyAlert;
    NSTimer *_sendTimer;
  NSString *_token;
  NSInteger _tryCounts;
  NSInteger _bindCounts;
  NSMutableData *_recvData;
  BOOL _isNessesaryToCheckWifi;
    NSString *_host;
    NSInteger _tokenCounts;
    PandoSdk *_psdk;
}

@end

@implementation AddDeviceViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  _configBtn.layer.cornerRadius = 6;
  _configBtn.layer.masksToBounds = YES;
  [_configBtn setBackgroundColor:[UIColor grayColor]];
  [_configBtn setAlpha:0.6];
  [_configBtn setEnabled:NO];
  
  
  NSUserDefaults *deviceDefaults = [NSUserDefaults standardUserDefaults];
  _productInfo = [deviceDefaults objectForKey:KEY_PRODUCT_INFO];
  _accessToken = [deviceDefaults objectForKey:KEY_ACCESS_TOKEN];
  
  
  [_barItem setTitle:LocalStr(@"ADDDEVICE_TITLE")];
  
  _isNessesaryToCheckWifi = YES;
  
    NSString *ssid = [self getCurrentSSID];
    _ssidText.text = [ssid copy];
    _bssid = [self getCurrentBSSID];
    
    [_ssidText setUserInteractionEnabled:NO];
    
    _psdk = nil;
  
  if (_ssidText.text.length > 0)
  {
    [_configBtn setBackgroundColor:[UIColor redColor]];
    [_configBtn setEnabled:YES];
  }
  
  [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observeTextChange)name:UITextFieldTextDidChangeNotification object:_ssidText];
  
  [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observeTextChange)name:UITextFieldTextDidChangeNotification object:_passText];
    
    _tryCounts = 0;
    _bindCounts = 0;
  
  
    if (ssid == nil) {
        NSString *msg = [NSString stringWithFormat:LocalStr(@"CHANGEWIFI_ALERT_MSG")];
  
        _ssidEmptyAlert = [[UIAlertView alloc]initWithTitle:LocalStr(@"CHANGEWIFI_ALERT_TITLE")
                                                       message:msg
                                                      delegate:self
                                             cancelButtonTitle:LocalStr(@"STR_OK")
                                             otherButtonTitles:nil];
        [_ssidEmptyAlert show];
        
#if 0
        _checkWifiHud = [[MBProgressHUD alloc] initWithView:self.view];
        
        UITapGestureRecognizer *HUDSingleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(HUDSingleTap:)];
        
        [_checkWifiHud addGestureRecognizer:HUDSingleTap];
        
        _checkWifiHud.dimBackground = YES;
        _checkWifiHud.delegate = self;
        _checkWifiHud.labelText = [NSString stringWithFormat:LocalStr(@"STR_CHANGE_WIFI"), AP_SSID];
        
        [self.view addSubview:_checkWifiHud];
        
        [_checkWifiHud showWhileExecuting:@selector(doCheckSSID) onTarget:self withObject:nil animated:YES];
#endif
        
    }
}

- (void)viewWillDisappear:(BOOL)animated {
  //[_checkWifiHud hide:NO];
  //_isNessesaryToCheckWifi = NO;
    
    [_sendTimer invalidate];
    
//    if (self._esptouchTask != nil)
//    {
//        [self._esptouchTask interrupt];
//    }
    
    if (_psdk != nil) {
        [_psdk stopConfig];
    }
    
}

- (void)doCheckSSID {
  while (_isNessesaryToCheckWifi) {
    NSString *ssid = [self getCurrentSSID];
    
    if ([ssid isEqualToString:AP_SSID])
      break;
    
    sleep(3);
  }
}

- (void)observeTextChange {
  if (_ssidText.text.length > 0) {
    [_configBtn setBackgroundColor:[UIColor redColor]];
    [_configBtn setEnabled:YES];
  }
  else {
    [_configBtn setBackgroundColor:[UIColor grayColor]];
    [_configBtn setAlpha:0.6];
    [_configBtn setEnabled:NO];
  }
}

#pragma mark - button action

- (IBAction)viewTouchDown:(id)sender {
  [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}



- (void)startToBindDevice {
  _recvData = [NSMutableData data];
  
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:_token, @"device_key",nil];
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, BIND_DEVICE_PATH];
  
  NSLog(@"req = %@\n%@", req, jsonInputString);
  
  
  NSURL *url = [NSURL URLWithString:[req URLEncodedString]];
  NSString *method = @"POST";
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  
  [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
  [request addValue:PRODUCT_KEY forHTTPHeaderField:@"Product-Key"];
  [request addValue:self.accessToken forHTTPHeaderField:@"Access-Token"];
  
  
  [request setHTTPBody: [jsonInputString dataUsingEncoding:NSUTF8StringEncoding]];
  
  
  [request setHTTPMethod:method];
  
  NSOperationQueue *queue = [[NSOperationQueue alloc] init];
  
  NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
  [conn setDelegateQueue:queue];
  [conn start];
}

- (IBAction)startConfigBtnTouchUpInside:(id)sender {
  //[self.ssidText resignFirstResponder];
  [self.passText resignFirstResponder];
    
    if (_psdk == nil)
        _psdk = [[PandoSdk alloc]initWithDelegate:self];
  
  if ([self.passText.text isEqualToString:@""]) {
    _passEmptyAlert = [[UIAlertView alloc] initWithTitle:@""
                          message:LocalStr(@"PASSEMPTY_ALERT_MSG")
                           delegate:self
                      cancelButtonTitle:LocalStr(@"STR_CANCEL")
                      otherButtonTitles:LocalStr(@"STR_OK"), nil];
    [_passEmptyAlert show];
  }
  else {
      
      [_psdk configDeviceToWiFi:[_ssidText text] password:[_passText text] byMode:@"smartlink"];
    
    _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    _HUD.dimBackground = YES;
    
    // Regiser for HUD callbacks so we can remove it from the window at the right time
    _HUD.delegate = self;
    //HUD.labelText = @"正在配置";
  }
}

-(void)HUDSingleTap:(UITapGestureRecognizer*)sender {
#if 0
  exitAlert = [[UIAlertView alloc] initWithTitle:@""
                       message:LocalStr(@"GIVEUP_ALERT_MSG")
                      delegate:self
                 cancelButtonTitle:LocalStr(@"STR_CANCEL")
                 otherButtonTitles:LocalStr(@"STR_OK"), nil];
  
  [exitAlert show];
#endif
}

#pragma mark - local

- (NSString *)getCurrentSSID {
  NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
  NSLog(@"Supported interfaces: %@", ifs);
  id info = nil;
  NSString *ssid = nil;
  for (NSString *ifnam in ifs) {
    info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
    NSLog(@"%@ => %@", ifnam, info);
    
    if (info[@"SSID"]) {
      ssid = info[@"SSID"];
    }
    
    if (info && [info count]) {
      break;
    }
  }
    //return @"pandocloud";
  return ssid;
}

- (NSString *)getCurrentBSSID {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    NSLog(@"Supported interfaces: %@", ifs);
    id info = nil;
    NSString *bssid = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@ => %@", ifnam, info);
        
        if (info[@"BSSID"]) {
            bssid = info[@"BSSID"];
        }
        
        if (info && [info count]) {
            break;
        }
    }
    return bssid;
}


#pragma mark - NSURLConnection 回调方法
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [_recvData appendData:data];
  
  NSLog(@"connection : didReceiveData");
  
}

-(void) connection:(NSURLConnection *)connection didFailWithError: (NSError *)error {
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    
    if (_bindCounts > 1) {
      [_HUD hide:YES];
      
      NSLog(@"Error (): %@", [error localizedDescription]);
      
      UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_CONNECT_FAIL")
                               message:[error localizedDescription]
                              delegate:nil
                         cancelButtonTitle:LocalStr(@"STR_OK")
                         otherButtonTitles:nil];
      [temp show];
    }
    else {
      _bindCounts++;
      [_sendTimer invalidate];
      _sendTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(startToBindDevice) userInfo:nil repeats:NO];
    }
  });
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection {
  NSLog(@"请求完成...");
  
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    
    NSDictionary *respDic = [NSJSONSerialization JSONObjectWithData:_recvData options:NSJSONReadingMutableLeaves error:nil];
    
    if (respDic != nil) {
      NSLog(@"%@", respDic);
      
      if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
        UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"BINDDEVICE_SUCCESS_ALERT_TITLE")
                                 message:@""
                                delegate:self
                           cancelButtonTitle:LocalStr(@"STR_OK")
                           otherButtonTitles:nil];
        [temp show];
      }
      else if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:10010]]) {
        [CHKeychain delete:kKeyUsernamePassword];
        
        UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                 message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                delegate:self
                           cancelButtonTitle:LocalStr(@"STR_OK")
                           otherButtonTitles:nil];
        [temp show];
        
        [_HUD hide:YES];
        return;
      }
      else {
        UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"BINDDEVICE_FAIL_ALERT_TITLE")
                                 message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                delegate:nil
                           cancelButtonTitle:LocalStr(@"STR_OK")
                           otherButtonTitles:nil];
        [temp show];
      }
    }
    else {
      UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_ERROR")
                               message:LocalStr(@"STR_NO_RESPONSE")
                              delegate:nil
                         cancelButtonTitle:LocalStr(@"STR_OK")
                         otherButtonTitles:nil];
      [temp show];
    }
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


#pragma mark - alertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alertView == _exitAlert) {
    if (buttonIndex == 1) {
      [_checkWifiHud hide:NO];
      _isNessesaryToCheckWifi = NO;
      //[self dismissViewControllerAnimated:YES completion:nil];
      [self.navigationController popViewControllerAnimated:YES];
    }
  }
  else if (alertView == _passEmptyAlert) {
    if (buttonIndex == 1) {
      
        if (_psdk == nil)
            _psdk = [[PandoSdk alloc]initWithDelegate:self];
        
        [_psdk configDeviceToWiFi:[_ssidText text] password:[_passText text] byMode:@"smartlink"];
        
        
        
      _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      
      _HUD.dimBackground = YES;
      
      // Regiser for HUD callbacks so we can remove it from the window at the right time
      _HUD.delegate = self;
      //HUD.labelText = @"正在配置";
    }
  }
  else {
    //[self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
  }
}




- (void)pandoSdk:(PandoSdk *)pandoSdk didConfigDeviceToWiFi:(NSString *)bssid deviceKey:(NSString *)deviceKey error:(NSError *)error {
    
    if (error == nil) {
        //[[[UIAlertView alloc]initWithTitle:@"配置成功" message:nil delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil] show];
        
        _token = [deviceKey copy];
        
        [self startToBindDevice];
    }
    else {
        [[[UIAlertView alloc]initWithTitle:@"配置失败" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil] show];
    }
    
    
    [_HUD hide:YES];
    
}

- (void)pandoSdk:(PandoSdk *)pandoSdk didStopConfig:(BOOL)isStoped error:(NSError *)error {
    
}

#if 0

#pragma mark - esp

- (IBAction)bindDeviceBtnTouchUpInside:(id)sender {
    
    NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:_token, @"device_key",nil];
    NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
    
    NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, BIND_DEVICE_PATH];
    
    NSLog(@"req = %@\n%@", req, jsonInputString);
    
    
    
    NSURL *url = [NSURL URLWithString:[req URLEncodedString]];
    NSString *method = @"POST";
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue:PRODUCT_KEY forHTTPHeaderField:@"Product-Key"];
    [request addValue:self.accessToken forHTTPHeaderField:@"Access-Token"];
    
    
    [request setHTTPBody: [jsonInputString dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    [request setHTTPMethod:method];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [conn setDelegateQueue:queue];
    [conn start];
    
    if (conn) {
        NSLog(@"connect ok");
        
        _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        _HUD.dimBackground = YES;
        
        // Regiser for HUD callbacks so we can remove it from the window at the right time
        _HUD.delegate = self;
        //HUD.labelText = @"绑定中";
    }
    else {
        NSLog(@"connect error");
    }
}

- (void)waitChangeSSID {
    int n = 12;
    
    while (n) {
        NSString *ssid = [self getCurrentSSID];
        NSLog(@"ssid = %@, code = %@", ssid, [self.productInfo objectForKey:@"code"]);
        
        if ([ssid isEqualToString:[self.productInfo objectForKey:@"code"]] == NO)
            break;
        
        n--;
        sleep(5);
    }
    
    if (n > 0) {
        [self startToBindDevice];
    }
    else {
        UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"BINDDEVICE_FAIL_ALERT_TITLE")
                                                       message:nil
                                                      delegate:nil
                                             cancelButtonTitle:LocalStr(@"STR_OK")
                                             otherButtonTitles:nil];
        [temp show];
        
        [_HUD hide:YES];
    }
}


- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    NSString *gatewayIp = nil;
    
    for (int i = (int)[address length] - 1; i > 0; i--) {
        if ([address characterAtIndex:i] == '.') {
            gatewayIp = [NSString stringWithFormat:@"%@.1", [address substringToIndex:i]];
            break;
        }
    }
    
    return gatewayIp;
}
#endif




@end
