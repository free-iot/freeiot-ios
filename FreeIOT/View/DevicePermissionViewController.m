//
//  DevicePermissionViewController.m
//  OutletApp
//
//  Created by liming_llm on 15/3/22.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "DevicePermissionViewController.h"
#import "MBProgressHUD.h"
#import "Const.h"
#import "NSString+URLEncode.h"
#import "CHKeychain.h"

extern NSString * const kKeyUsernamePassword;

extern NSMutableDictionary *errorCode;
extern NSString *HOST_URL;


@interface DevicePermissionViewController () <MBProgressHUDDelegate,UIPickerViewDelegate, UITextFieldDelegate,UIPickerViewDataSource> {
  MBProgressHUD *_HUD;
  NSMutableData *_recvData;
  NSArray *_pickerArray;
  UIAlertView *_tokenAlert;
}

@end

@implementation DevicePermissionViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  [_barItem setTitle:LocalStr(@"DEVICEAUTH_TITLE")];
  
  
  NSUserDefaults *deviceDefaults = [NSUserDefaults standardUserDefaults];
  _accessToken = [deviceDefaults objectForKey:KEY_ACCESS_TOKEN];
  
  _pickerArray = [NSArray arrayWithObjects:LocalStr(@"STR_READONLY"), LocalStr(@"STR_RANDW"), nil];
  
  _permitionText.inputView = _selectView;
  _permitionText.inputAccessoryView = _selectBar;
  _permitionText.delegate = self;
  _selectView.delegate = self;
  _selectView.dataSource = self;
  
  _permitBtn.layer.cornerRadius = 6;
  _permitBtn.layer.masksToBounds = YES;
  [_permitBtn setBackgroundColor:[UIColor grayColor]];
  [_permitBtn setAlpha:0.6];
  [_permitBtn setEnabled:NO];
  
  //_permitionText.text = LocalStr(@"STR_READONLY");
  
  if (_phone != nil) {
    _usernameText.text = _phone;
    [_usernameText setEnabled:NO];
  }
  
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(observeTextChange)
                                              name:UITextFieldTextDidChangeNotification
                                            object:_usernameText];
  
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(observeTextChange)
                                              name:UITextFieldTextDidChangeNotification
                                            object:_permitionText];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)observeTextChange {
  if (_permitionText.text.length > 0 && _usernameText.text.length == 11) {
    [_permitBtn setBackgroundColor:[UIColor redColor]];
    [_permitBtn setEnabled:YES];
  }
  else {
    [_permitBtn setBackgroundColor:[UIColor grayColor]];
    [_permitBtn setAlpha:0.6];
    [_permitBtn setEnabled:NO];
  }
}

#pragma mark - action

- (IBAction)selectDonePressed:(id)sender {
  [_permitionText endEditing:YES];
  
  if (_usernameText.text.length > 0 && _permitBtn.enabled == NO) {
    [_permitBtn setBackgroundColor:[UIColor redColor]];
    [_permitBtn setEnabled:YES];
  }
}

- (IBAction)backPressed:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)viewTouchDown:(id)sender {
  [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

- (IBAction)permitBtnTouchUpInside:(id)sender {
  _recvData = nil;
  _recvData = [NSMutableData data];
  
  [self allowPermitions];
  
  _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _HUD.dimBackground = YES;
  _HUD.delegate = self;
  //HUD.labelText = @"正在授权";
}

- (void)allowPermitions {
  
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:_usernameText.text,
                                    @"user",
        [_permitionText.text isEqualToString:LocalStr(@"STR_READONLY")]?[NSNumber numberWithInt:1]:[NSNumber numberWithInt:2],
                                    @"privilege",nil];
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSString *req = [NSString stringWithFormat:@"%@"ALLOW_PERMITIONS, HOST_URL, _identifier];
  
  NSLog(@"req = %@\n%@", req, jsonInputString);
  
  [self request:req content:jsonInputString tag:nil];
}

-(void) request:(NSString *)reqUrl content:(NSString *)content tag:(id)tag {
  NSURL *url = [NSURL URLWithString:[reqUrl URLEncodedString]];
  NSString *method = @"GET";
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  
  [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
  [request addValue:PRODUCT_KEY forHTTPHeaderField:@"Product-Key"];
  
  if (_accessToken != nil)
  {
    [request addValue:_accessToken forHTTPHeaderField:@"Access-Token"];
  }
  
  if (content != nil)
  {
    [request setHTTPBody: [content dataUsingEncoding:NSUTF8StringEncoding]];
    method = @"POST";
  }
  
  [request setHTTPMethod:method];
  
  NSOperationQueue *queue = [[NSOperationQueue alloc] init];
  
  NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
  [conn setDelegateQueue:queue];
  [conn start];
  
  if (conn) {
    NSLog(@"connect ok");
  }
  else {
    NSLog(@"connect error");
  }
  
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
  if (textField == _permitionText) {
    NSInteger row = [_selectView selectedRowInComponent:0];
    self.permitionText.text = [_pickerArray objectAtIndex:row];
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
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    
    NSLog(@"请求完成...");
    
    NSDictionary *respDic = [NSJSONSerialization JSONObjectWithData:_recvData options:NSJSONReadingMutableLeaves error:nil];
    
    NSLog(@"resp %@", respDic);
    
    if (respDic != nil) {
      if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {

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
