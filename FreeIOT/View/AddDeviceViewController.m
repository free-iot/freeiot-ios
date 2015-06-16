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
#import "GCDAsyncSocket.h"
#import "NSString+URLEncode.h"
#import "CHKeychain.h"

extern NSString *const kKeyUsernamePassword;
extern NSMutableDictionary *errorCode;

@interface AddDeviceViewController () <MBProgressHUDDelegate, GCDAsyncSocketDelegate> {
  MBProgressHUD *_HUD;
  MBProgressHUD *_checkWifiHud;
  UIAlertView *_exitAlert;
  UIAlertView *_passEmptyAlert;
  GCDAsyncSocket *_asyncSocket;
  NSTimer *_sendTimer;
  NSString *_token;
  NSInteger _tryCounts;
  NSInteger _bindCounts;
  NSMutableData *_recvData;
  BOOL _isNessesaryToCheckWifi;
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
  
  _ssidText.text = [self getCurrentSSID];
  
  if (_ssidText.text.length > 0)
  {
    [_configBtn setEnabled:YES];
  }
  
  [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observeTextChange)name:UITextFieldTextDidChangeNotification object:_ssidText];
  
  [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observeTextChange)name:UITextFieldTextDidChangeNotification object:_passText];
  
  
  NSString *msg = [NSString stringWithFormat:LocalStr(@"CHANGEWIFI_ALERT_MSG"), AP_SSID];
  
  UIAlertView *alert = [[UIAlertView alloc]initWithTitle:LocalStr(@"CHANGEWIFI_ALERT_TITLE")
                       message:msg
                       delegate:nil
                       cancelButtonTitle:LocalStr(@"STR_OK")
                       otherButtonTitles:nil];
  [alert show];
  
  
  _tryCounts = 0;
  _bindCounts = 0;
  
  _checkWifiHud = [[MBProgressHUD alloc] initWithView:self.view];
  
  UITapGestureRecognizer *HUDSingleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(HUDSingleTap:)];
  
  [_checkWifiHud addGestureRecognizer:HUDSingleTap];
  
  _checkWifiHud.dimBackground = YES;
  _checkWifiHud.delegate = self;
  _checkWifiHud.labelText = [NSString stringWithFormat:LocalStr(@"STR_CHANGE_WIFI"), AP_SSID];
  
  [self.view addSubview:_checkWifiHud];
  
  [_checkWifiHud showWhileExecuting:@selector(doCheckSSID) onTarget:self withObject:nil animated:YES];
  
}

- (void)viewWillDisappear:(BOOL)animated {
  [_checkWifiHud hide:NO];
  _isNessesaryToCheckWifi = NO;
}

- (void)doCheckSSID {
  while (_isNessesaryToCheckWifi) {
    NSString *ssid = [self getCurrentSSID];
    //NSLog(@"ssid = %@, code = %@", ssid, [self.productInfo objectForKey:@"code"]);
    
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

- (IBAction)backPressed:(id)sender {
  [self dismissViewControllerAnimated:NO completion:nil];
  [self.view removeFromSuperview];
}

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
  
  if ([self.passText.text isEqualToString:@""]) {
    _passEmptyAlert = [[UIAlertView alloc] initWithTitle:@""
                          message:LocalStr(@"PASSEMPTY_ALERT_MSG")
                           delegate:self
                      cancelButtonTitle:LocalStr(@"STR_CANCEL")
                      otherButtonTitles:LocalStr(@"STR_OK"), nil];
    [_passEmptyAlert show];
  }
  else {
    [self configDevice];
    
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

- (void)checkConfig {
  NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:@"check_config", @"action", nil];
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
  
  [self sendData:jsonInputData withTag:1];
  
  _tryCounts++;
  
  if (_tryCounts >= 20) {
    [_sendTimer invalidate];
    
    [_HUD hide:YES];
    
    UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"CONFIGFAIL_ALERT_TITLE")
                             message:LocalStr(@"CONFIGFAIL_ALERT_MSG")
                            delegate:nil
                       cancelButtonTitle:LocalStr(@"STR_OK")
                       otherButtonTitles:nil];
    [temp show];
    
    _tryCounts = 0;
  }
}

- (void)requestToken {
  NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:@"token", @"action", nil];
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
  
  [self sendData:jsonInputData withTag:2];
}

- (void)exitConfig {
  NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:@"exit_config", @"action", nil];
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
  
  [self sendData:jsonInputData withTag:3];
  
  [_sendTimer invalidate];
  _sendTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(waitChangeSSID) userInfo:nil repeats:NO];
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

- (void)configDevice {
#if 1

  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:self.passText.text,
                 @"password",
                 @"config",
                 @"action",
                 self.ssidText.text,
                 @"ssid", nil];
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  
  
  [self sendData:jsonInputData withTag:0];
  
  
  _sendTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(checkConfig) userInfo:nil repeats:YES];
  
  
#endif
}

- (void) sendData:(NSData *)data withTag:(long)tag {
  NSString *HOST = [self getIPAddress];
  NSError *error = nil;
  
  if (_asyncSocket == nil) {
    _asyncSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    _asyncSocket.delegate = self;
  }
  
  if (_asyncSocket.isConnected == NO) {
    if ([_asyncSocket connectToHost:HOST onPort:8890 withTimeout:-1 error:&error]) {
      NSLog(@"connectToHost return ok");
    }
  }
  
  UInt32 dataLen = htonl((UInt32)[data length]);
  UInt16 magic = htons(0x7064);
  UInt16 type = htons(0x0001);
  
  NSMutableData *writeData = [NSMutableData dataWithBytes:&magic length:sizeof(magic)];
  [writeData appendData:[NSData dataWithBytes:&type length:sizeof(type)]];
  [writeData appendData:[NSData dataWithBytes:&dataLen length:sizeof(dataLen)]];
  [writeData appendData:data];
  
  NSString *jsonInputString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  
  NSLog(@"write = %@", jsonInputString);
  
  [_asyncSocket writeData:writeData withTimeout:-1 tag:tag];
  
  if (tag != 0) {
    [_asyncSocket readDataWithTimeout:-1 tag:tag];
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
  return ssid;
}

#pragma mark -
#pragma mark GCDAsyncSocket

#if 1
- (void)socket:(GCDAsyncSocket *)sock willDisconnectWithError:(NSError *)err {
  NSLog(@"willDisconnectWithError");
  //[self logInfo:FORMAT(@"Client Disconnected: %@:%hu", [sock connectedHost], [sock connectedPort])];
  if (err) {
    NSLog(@"错误报告：%@",err);
  }else{
    NSLog(@"连接工作正常");
  }
  _asyncSocket = nil;
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
  NSLog(@"didConnectToHost");
  
  

  //[sock readDataWithTimeout:0.5 tag:0];
  
  //[sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
  NSLog(@"didReadData");
  
  if (tag != 0) {
    if ([data length] > 8) {
      NSData *content = [data subdataWithRange:NSMakeRange(8, [data length] - 8)];
      //NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
      
      NSDictionary * respDic = [NSJSONSerialization JSONObjectWithData:content options:NSJSONReadingMutableLeaves error:nil];
      
      if (tag == 1) {
        if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
          [_sendTimer invalidate];
          _sendTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(requestToken) userInfo:nil repeats:YES];
        }
      }
      else if (tag == 2) {
        _token = [respDic objectForKey:@"token"];
        
        NSLog(@"token = %@", _token);
        
        if (_token != nil) {
          [_sendTimer invalidate];
          
          _sendTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(exitConfig) userInfo:nil repeats:NO];
        }
      }
    
    }
  }
  
  [sock disconnect];
  //[sock readDataWithTimeout:-1 tag:0]; //一直监听网络
  
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
  NSLog(@"didWriteDataWithTag %ld", tag);
  if (tag == 3)
  {
    [sock disconnectAfterWriting];
  }
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
  
  
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
  //DDLogInfo(@"socketDidDisconnect:%p withError: %@", sock, err);
  NSLog(@"socketDidDisconnect:%p withError: %@", sock, err);
  //dispatch_async(dispatch_get_main_queue(), ^{
   //   [itcpClient OnConnectionError:err];
  //});
}
#endif

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
      [self configDevice];
      
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

@end
