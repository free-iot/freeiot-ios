//
//  ModifyDeviceViewController.m
//  OutletApp
//
//  Created by liming_llm on 15/5/4.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "ModifyDeviceViewController.h"
#import "Const.h"
#import "NSString+URLEncode.h"
#import "CHKeychain.h"

extern NSString * const kKeyUsernamePassword;

extern NSMutableDictionary *errorCode;
extern NSString *HOST_URL;

@interface ModifyDeviceViewController() {
  MBProgressHUD   *_HUD;
  NSMutableData   *_recvData;
  NSArray     *_pickerArray;
  UIAlertView   *_tokenAlert;
}

@end


@implementation ModifyDeviceViewController


- (void)viewDidLoad {
  [super viewDidLoad];
  
  _pickerArray = [NSArray arrayWithObjects:@"不需解绑即可重新绑定", @"需要解绑才可以重新绑定", nil];
  
  _authText.inputView = _selectView;
  _authText.inputAccessoryView = _selectBar;
  _authText.delegate = self;
  
  _selectView.delegate = self;
  _selectView.dataSource = self;
  
  _okBtn.layer.cornerRadius = 6;
  _okBtn.layer.masksToBounds = YES;
  [_okBtn setBackgroundColor:[UIColor grayColor]];
  [_okBtn setAlpha:0.6];
  [_okBtn setEnabled:NO];
  
  _nameText.text = _name;
  
  
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(observeTextChange)
                                              name:UITextFieldTextDidChangeNotification
                                            object:_authText];
  
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(observeTextChange)
                                              name:UITextFieldTextDidChangeNotification
                                            object:_nameText];
  
  _recvData = [NSMutableData data];
}

- (void)observeTextChange {
  if (_authText.text.length > 0 && _nameText.text.length > 0) {
    [_okBtn setBackgroundColor:[UIColor redColor]];
    [_okBtn setEnabled:YES];
  }
  else {
    [_okBtn setBackgroundColor:[UIColor grayColor]];
    [_okBtn setAlpha:0.6];
    [_okBtn setEnabled:NO];
  }
}

- (void)doModifyDeviceInfo {
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:_nameText.text,
                 @"device_name",
                 [_authText.text isEqualToString:@"不需解绑即可重新绑定"]?[NSNumber numberWithInt:1]:[NSNumber numberWithInt:2],
                 @"secure_level",nil];
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  //NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSLog(@"req = %@", [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding]);
  
  
  NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"%@"MODIFY_DEVICE_PATH, HOST_URL, _identifier] URLEncodedString]];
  
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

- (IBAction)selectDonePressed:(id)sender {
  [_authText endEditing:YES];
  
  if (_nameText.text.length > 0 && _okBtn.enabled == NO) {
    [_okBtn setBackgroundColor:[UIColor redColor]];
    [_okBtn setEnabled:YES];
  }
}

- (IBAction)backPressed {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)okBtnTouchUpInside:(id)sender {
  [self doModifyDeviceInfo];
}

- (IBAction)viewTouchDown:(id)sender {
  [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

#pragma mark - pickerView delegate
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

-(NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return [_pickerArray count];
}

-(NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return [_pickerArray objectAtIndex:row];
}


#pragma mark - textField delegate
-(void)textFieldDidEndEditing:(UITextField *)textField {
  if (textField == _authText) {
    NSInteger row = [_selectView selectedRowInComponent:0];
    _authText.text = [_pickerArray objectAtIndex:row];
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
    
    UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_CONNECT_FAIL")
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:LocalStr(@"STR_OK")
                                              otherButtonTitles:nil];
    [tempAlert show];
    
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
        
        UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_SUCCESS")
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:LocalStr(@"STR_OK")
                                                  otherButtonTitles:nil];
        [tempAlert show];
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
        UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                                            message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                                           delegate:nil
                                                  cancelButtonTitle:LocalStr(@"STR_OK")
                                                  otherButtonTitles:nil];
        [tempAlert show];
      }
    }
    else {
      UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                                          message:LocalStr(@"STR_NO_RESPONSE")
                                                         delegate:nil
                                                cancelButtonTitle:LocalStr(@"STR_OK")
                                                otherButtonTitles:nil];
      [tempAlert show];
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
    
    [[challenge sender]  useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
            forAuthenticationChallenge:challenge];
    
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
