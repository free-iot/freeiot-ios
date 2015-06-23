//
//  RegisterViewController.m
//  OutletApp
//
//  Created by liming_llm on 15/3/22.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "RegisterViewController.h"
#import "MBProgressHUD.h"
#import "NSString+URLEncode.h"
#import "Const.h"
#import "CHKeychain.h"

extern NSString * const kKeyUsernamePassword;
extern NSString * const kKeyUsername;
extern NSString * const kKeyPassword;

extern NSMutableDictionary *errorCode;
extern NSString *HOST_URL;

#define TAG_AUTH_CODE @"authcode"
#define TAG_REGISTER  @"register"
#define TAG_RESET   @"reset"

@interface RegisterViewController () <MBProgressHUDDelegate> {
  MBProgressHUD     *_HUD;
  NSMutableData     *_recvData;
  NSMutableDictionary *_connSet;
}

@end

@implementation RegisterViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  [_authcodeBtn setTitle:LocalStr(@"STR_GETAUTHCODE") forState:UIControlStateNormal];
  
  _authcodeBtn.layer.cornerRadius = 6;
  [_authcodeBtn setBackgroundColor:[UIColor grayColor]];
  [_authcodeBtn setAlpha:0.6];
  _authcodeBtn.layer.masksToBounds = YES;
  [_authcodeBtn setEnabled:NO];
  
  _registerBtn.layer.cornerRadius = 6;
  _registerBtn.layer.masksToBounds = YES;
  [_registerBtn setBackgroundColor:[UIColor grayColor]];
  [_registerBtn setAlpha:0.6];
  [_registerBtn setEnabled:NO];
  
  [_barItem setTitle:_titleStr];
  
#if IS_MAIL
  if ([_titleStr isEqualToString:NSLocalizedStringFromTable(@"REGISTER_TITLE", @"Strings", nil)]) {

    [_authcodeBtn setHidden:YES];
    [_authcodeText setHidden:YES];
  }

  [_usernameText setPlaceholder:LocalStr(@"USERNAME_TEXT_PLACEHOLDER")];
#else
  [_usernameText setPlaceholder:LocalStr(@"USERNAME_TEXT_PLACEHOLDER_PHONE")];
#endif
  [_passwordText setPlaceholder:LocalStr(@"PASSWORD_TEXT_PLACEHOLDER")];
  
  [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(textChange)name:UITextFieldTextDidChangeNotification object:_usernameText];
  
  [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(textChange)name:UITextFieldTextDidChangeNotification object:_passwordText];
  
  [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(textChange)name:UITextFieldTextDidChangeNotification object:_authcodeText];
  
  _connSet = [NSMutableDictionary dictionary];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)textChange {
  if (_usernameText.text.length > 0 && _passwordText.text.length > 0 && (_authcodeText.text.length > 0 || _authcodeText.isHidden == YES)) {
    [_registerBtn setBackgroundColor:[UIColor redColor]];
    [_registerBtn setEnabled:YES];
  }
  else {
    [_registerBtn setBackgroundColor:[UIColor grayColor]];
    [_registerBtn setAlpha:0.6];
    [_registerBtn setEnabled:NO];
  }
  
  if (_usernameText.text.length > 0 && [_authcodeBtn.titleLabel.text isEqualToString:LocalStr(@"STR_GETAUTHCODE")]) {
    [_authcodeBtn setBackgroundColor:[UIColor redColor]];
    [_authcodeBtn setEnabled:YES];
  }
#if 1
  else {
    [_authcodeBtn setBackgroundColor:[UIColor grayColor]];
    [_authcodeBtn setEnabled:NO];
  }
#endif
}

- (void)startRegister {
#if IS_MAIL
  NSString *tempStr = @"mail";
  
#else
  NSString *tempStr = @"mobile";
#endif
  
  //register
  if ([_titleStr isEqualToString:NSLocalizedStringFromTable(@"REGISTER_TITLE", @"Strings", nil)]) {
    
#if IS_MAIL
      NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:
                   _usernameText.text,
                   tempStr,
                   _passwordText.text,
                   @"password",
                   nil];
#else
      NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:
             _usernameText.text,
             tempStr,
             _passwordText.text,
             @"password",
             _authcodeText.text,
             @"verification",
             nil];
#endif
  
    NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
    NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, REGISTER_PATH];
    NSLog(@"req = %@\n%@", req, jsonInputString);
    [self request:req content:jsonInputString tag:TAG_REGISTER];
  }
  else {
    //reset password
    NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:
                   _usernameText.text,
                   tempStr,
                   _passwordText.text,
                   @"password",
                   _authcodeText.text,
                   @"verification",
                   nil];
    
    NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
    
    NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, PASS_RESET_PATH];
    NSLog(@"req = %@\n%@", req, jsonInputString);
    [self request:req content:jsonInputString tag:TAG_RESET];
  }
  
  _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _HUD.dimBackground = YES;
}

- (void)getAuthCode {
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:_usernameText.text, @"mail", nil];
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, GET_AUTH_CODE];
  
  NSLog(@"req = %@\n%@", req, jsonInputString);
  
  [self request:req content:jsonInputString tag:TAG_AUTH_CODE];
  
  [self startTimer];
  
}

- (void)startTimer {
  __block int timeout = 59; //倒计时时间
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
  dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0 * NSEC_PER_SEC, 0); //每秒执行
  dispatch_source_set_event_handler(_timer, ^{
    if(timeout <= 0) {
      //倒计时结束，关闭
      dispatch_source_cancel(_timer);
      dispatch_async(dispatch_get_main_queue(), ^{
        
        [_authcodeBtn setTitle:LocalStr(@"STR_GETAUTHCODE") forState:UIControlStateNormal];
        [_authcodeBtn setBackgroundColor:[UIColor redColor]];
        [_authcodeBtn setEnabled:YES];
      });
    }
    else {
      //      int minutes = timeout / 60;
      int seconds = timeout % 60;
      NSString *strTime = [NSString stringWithFormat:@"%.2d", seconds];
      dispatch_async(dispatch_get_main_queue(), ^{
        
 
        [_authcodeBtn setTitle:[NSString stringWithFormat:@"%@", strTime] forState:UIControlStateNormal];
        [_authcodeBtn setBackgroundColor:[UIColor grayColor]];
        [_authcodeBtn setEnabled:NO];
        
      });
      timeout--;
    }
  });
  dispatch_resume(_timer);
  
}

-(void) request:(NSString *)reqUrl content:(NSString *)content tag:(NSString *)tag
{
  NSURL *url = [NSURL URLWithString:[reqUrl URLEncodedString]];
  NSString *method = @"GET";
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  
  [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
  [request addValue:PRODUCT_KEY forHTTPHeaderField:@"Product-Key"];
  
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

#pragma mark - button action
- (IBAction)authcodeBtnTouchUpInside:(id)sender {
  _recvData = nil;
  _recvData = [NSMutableData new];
  
  [self getAuthCode];
}

- (IBAction)registerBtnTouchUpInside:(id)sender {
  [_usernameText resignFirstResponder];
  [_authcodeText resignFirstResponder];
  [_passwordText resignFirstResponder];
  
  _recvData = nil;
  _recvData = [NSMutableData new];
  
  [self startRegister];
}

- (IBAction)backBtnAction:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)viewTouchDown:(id)sender {
  [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
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
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    
    NSLog(@"请求完成...");
    
    NSDictionary *respDic = [NSJSONSerialization JSONObjectWithData:_recvData options:NSJSONReadingMutableLeaves error:nil];
    
    NSLog(@"resp %@", respDic);
    
    if (respDic != nil) {
      if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
        if (connection == [_connSet objectForKey:TAG_REGISTER]
          || connection == [_connSet objectForKey:TAG_RESET]) {
          [CHKeychain delete:kKeyUsernamePassword];
          
          //save username & password to keychain
          NSMutableDictionary *usernamepasswordKVPairs = [NSMutableDictionary dictionary];
          [usernamepasswordKVPairs setObject:_usernameText.text forKey:kKeyUsername];
          [usernamepasswordKVPairs setObject:_passwordText.text forKey:kKeyPassword];
          [CHKeychain save:kKeyUsernamePassword data:usernamepasswordKVPairs];
          
          UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_SUCCESS")
                                   message:nil
                                  delegate:self
                             cancelButtonTitle:LocalStr(@"STR_OK")
                             otherButtonTitles:nil];
          [temp show];
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
    else {
      UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
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
  [self dismissViewControllerAnimated:YES completion:nil];
}



@end
