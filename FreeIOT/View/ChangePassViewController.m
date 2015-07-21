//
//  ChangePassViewController.m
//  OutletApp
//
//  Created by liming_llm on 15/5/3.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "ChangePassViewController.h"
#import "Const.h"
#import "NSString+URLEncode.h"
#import "CHKeychain.h"

extern NSString *const kKeyUsernamePassword;
extern NSString *const kKeyUsername;
extern NSString *const kKeyPassword;

extern NSMutableDictionary *errorCode;
extern NSString *HOST_URL;

@interface ChangePassViewController() {
  MBProgressHUD *_HUD;
  NSMutableData *_recvData;
  UIAlertView   *_tokenAlert;
}

@end

@implementation ChangePassViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _okBtn.layer.cornerRadius = 6;
  _okBtn.layer.masksToBounds = YES;
  [_okBtn setBackgroundColor:[UIColor grayColor]];
  [_okBtn setAlpha:0.6];
  [_okBtn setEnabled:NO];
  
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(observeTextChange)
                                              name:UITextFieldTextDidChangeNotification
                                            object:_passText];
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(observeTextChange)
                                              name:UITextFieldTextDidChangeNotification
                                            object:_freshPassText];
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(observeTextChange)
                                              name:UITextFieldTextDidChangeNotification
                                            object:_confirmText];
  
  _recvData = [NSMutableData data];
}

#pragma mark - local

- (void)observeTextChange {
  if (_passText.text.length > 0 && _freshPassText.text.length > 0 && _confirmText.text.length >0) {
    [_okBtn setBackgroundColor:[UIColor redColor]];
    [_okBtn setEnabled:YES];
  }
  else {
    [_okBtn setBackgroundColor:[UIColor grayColor]];
    [_okBtn setAlpha:0.6];
    [_okBtn setEnabled:NO];
  }
}

- (void)doChangPassword {
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:_passText.text,
                 @"password",
                 _freshPassText.text,
                 @"new_password",
                 nil];
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
    
  //NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSLog(@"req = %@", [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding]);


  NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"%@%@", HOST_URL, CHANGE_PASS_PATH] URLEncodedString]];
  
  NSLog(@"url = %@", url);
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  
  [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
  [request addValue:PRODUCT_KEY forHTTPHeaderField:@"Product-Key"];
  [request setHTTPBody:jsonInputData];
  [request setHTTPMethod:@"PUT"];
  
  NSUserDefaults *deviceDefaults = [NSUserDefaults standardUserDefaults];
  NSString *accessToken = [deviceDefaults objectForKey:KEY_ACCESS_TOKEN];
  
  if (accessToken != nil) {
    [request addValue:accessToken forHTTPHeaderField:@"Access-Token"];
  }

  
  NSOperationQueue *queue = [[NSOperationQueue alloc] init];
  
  NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
  [conn setDelegateQueue:queue];
  [conn start];
  
  
  _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _HUD.dimBackground = YES;
}


#pragma mark - action

- (IBAction)backPressed {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)okBtnTouchUpInside:(id)sender {
  if ([_freshPassText.text isEqualToString:_confirmText.text] == YES) {
    [self doChangPassword];
  }
  else {
    UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_ERROR")
                             message:@"两次密码不一致"
                            delegate:nil
                       cancelButtonTitle:LocalStr(@"STR_OK")
                       otherButtonTitles:nil];
    [temp show];
  }
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
  NSLog(@"请求完成...");
  
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    
    NSDictionary * respDic = [NSJSONSerialization JSONObjectWithData:_recvData options:NSJSONReadingMutableLeaves error:nil];
    
    if (respDic != nil) {
      NSLog(@"resp = %@", respDic);
      
      if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
        NSMutableDictionary *usernamepasswdKVPairs = (NSMutableDictionary *)[CHKeychain load:kKeyUsernamePassword];
        [usernamepasswdKVPairs setObject:_freshPassText.text forKey:kKeyPassword];
        [CHKeychain save:kKeyUsernamePassword data:usernamepasswdKVPairs];
        
        UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_SUCCESS")
                                                       message:nil
                                                      delegate:self
                                             cancelButtonTitle:LocalStr(@"STR_OK")
                                             otherButtonTitles:nil];
        [temp show];
      }
      else if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:10010]]) {
        [CHKeychain delete:kKeyUsernamePassword];
        
        _tokenAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                                 message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                                delegate:self
                                       cancelButtonTitle:LocalStr(@"STR_OK")
                                       otherButtonTitles:nil];
        [_tokenAlert show];
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

//服务器端单项HTTPS 验证，iOS 客户端忽略证书验证。

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
  if (alertView == _tokenAlert) {
    UIViewController *myDevVC = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    myDevVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:myDevVC animated:YES completion:nil];
  }
  else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

@end
