//
//  DeviceDetailViewController.m
//  OutletApp
//
//  Created by liming_llm on 15/3/19.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "DeviceDetailViewController.h"
#import "Const.h"
#import "MBProgressHUD.h"
#import "WebViewJavascriptBridge.h"
#import "NSString+URLEncode.h"
#import "CHKeychain.h"

extern NSString * const kKeyUsernamePassword;
extern NSString * const kKeyUsername;
extern NSString * const kKeyPassword;

extern NSMutableDictionary *errorCode;
extern NSString *HOST_URL;

#define TAG_DEVICE_STATUS   @"device_status"
#define TAG_DEVICE_VALUE  @"device_value"


@interface DeviceDetailViewController () <UIWebViewDelegate, MBProgressHUDDelegate, WebViewJSBridgeDelegate> {
  IBOutlet UIWebView *_devWebView;
  MBProgressHUD *_HUD;
  WebViewJavascriptBridge *_bridge;
  NSMutableDictionary *_connSet;
  NSMutableData   *_recvData;
}

@end

@implementation DeviceDetailViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  //handlerMap = [[NSDictionary alloc]initWithObjectsAndKeys:  , @"currentStatus", nil];
  
  
  _devWebView.scalesPageToFit = YES;
  //devWebView.delegate = self;
  
  _connSet = [NSMutableDictionary dictionary];
  _recvData = [NSMutableData data];
  
  _bridge = [WebViewJavascriptBridge bridgeForWebView:_devWebView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
    NSLog(@"ObjC received message from JS: %@", data);
    //responseCallback(@"Response for message from ObjC");
  }];
  
  [_barItem setTitle:_dtitle];
  
  if (_url == nil) {
    [self loadLocalPage:_devWebView path:@"index" type:@"html"];
  }
  else {
    NSLog(@"url = %@", _url);
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:_url]];
    if (req != nil) {
      _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      _HUD.dimBackground = YES;
      _HUD.delegate = self;
      [_devWebView loadRequest:req];
      [_HUD showWhileExecuting:@selector(doCheckLoading) onTarget:self withObject:nil animated:YES];
    }
    else {
      
    }
  }
}

- (void)doCheckLoading {
  while (_devWebView.loading) {
    sleep(1);
  }
}

- (void)loadLocalPage:(UIWebView*)webView path:(NSString *)path type:(NSString *)type {
  NSString* htmlPath = [[NSBundle mainBundle] pathForResource:path ofType:type];
  NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
  NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
  [webView loadHTMLString:appHtml baseURL:baseURL];
}

- (void)handleJSCall:(NSDictionary *)handlerMsg {
  if ([[handlerMsg objectForKey:@"handlerName"] isEqualToString:@"currentStatus"]) {
    [self getCurrentStatus:handlerMsg];
  }
  else if ([[handlerMsg objectForKey:@"handlerName"] isEqualToString:@"sendCommand"]) {
    [self setDeviceValue:handlerMsg];
  }
}

- (void)getCurrentStatus:(NSDictionary *)handlerMsg {

  NSString *req = [NSString stringWithFormat:@"%@"DEVICE_STATUS, HOST_URL, _identifier];
  [self request:req content:nil tag:TAG_DEVICE_STATUS cbId:handlerMsg[@"callbackId"]];
  
  _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _HUD.dimBackground = YES;
  _HUD.delegate = self;
}

- (void)setDeviceValue:(NSDictionary *)handlerMsg {
  NSString *req = [NSString stringWithFormat:@"%@"SET_DEVICE_VALUE, HOST_URL, _identifier];
  
  //NSArray *params = handlerMsg[@"data"];
  //NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:params, @"switch", nil];
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:handlerMsg[@"data"] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSLog(@"http req = %@", jsonInputString);
  
  [self request:req content:jsonInputString tag:TAG_DEVICE_VALUE cbId:handlerMsg[@"callbackId"]];
  
  _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _HUD.dimBackground = YES;
  _HUD.delegate = self;
}

-(void) request:(NSString *)reqUrl content:(NSString *)content tag:(id)tag cbId:(NSString *)cbId {
  NSURL *url = [NSURL URLWithString:[reqUrl URLEncodedString]];
  NSString *method = @"GET";
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  
  [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
  [request addValue:PRODUCT_KEY forHTTPHeaderField:@"Product-Key"];
  
  if (_accessToken != nil) {
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
  
  NSArray *tmp = [NSArray arrayWithObjects:conn, cbId, nil];
  
  [_connSet setObject:tmp forKey:tag];
  
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
    
      UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_CONNECT_FAIL")
                                                          message:[error localizedDescription]
                                                         delegate:nil
                                                cancelButtonTitle:LocalStr(@"STR_OK")
                                                otherButtonTitles:nil];
      [tempAlert show];
    
  });
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection {
  NSLog(@"请求完成...");
  
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    
    NSDictionary * respDic = [NSJSONSerialization JSONObjectWithData:_recvData options:NSJSONReadingMutableLeaves error:nil];
    
    NSLog(@"http resp = %@", respDic);
    
    if (respDic == nil) {
      UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_ERROR")
                                                          message:LocalStr(@"STR_NO_RESPONSE")
                                                         delegate:nil
                                                cancelButtonTitle:LocalStr(@"STR_OK")
                                                otherButtonTitles:nil];
      [tempAlert show];
      
      
      
    }
    else {
      if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:10010]]) {
        [CHKeychain delete:kKeyUsernamePassword];
        
        UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                                            message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                                           delegate:self
                                                  cancelButtonTitle:LocalStr(@"STR_OK")
                                                  otherButtonTitles:nil];
        [tempAlert show];
        
        [_HUD hide:YES];
        return;
      }
      
      
      if (connection == [[_connSet objectForKey:TAG_DEVICE_STATUS] objectAtIndex:0]) {
        
        if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
          NSDictionary *respData = [respDic objectForKey:@"data"];
          
          NSDictionary *cbData = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],
                                                                            @"code",
                                                                            @"",
                                                                            @"message",
                                                                            respData,
                                                                            @"data", nil];
          
          NSDictionary *cbMessage = [NSDictionary dictionaryWithObjectsAndKeys:[[_connSet objectForKey:TAG_DEVICE_STATUS] objectAtIndex:1],
                                                                               @"responseId",
                                                                               cbData,
                                                                               @"responseData", nil];
          
          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:cbMessage options:NSJSONWritingPrettyPrinted error:nil];
          
#if 0
          NSString *messageJSON = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
          
          messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
          messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
          messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
          messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
          messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
          messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
          messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
          messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
          
          NSData *base64Data = [messageJSON dataUsingEncoding:NSUTF8StringEncoding];
#endif
          
          NSString *jsonBase64String = [jsonData base64EncodedStringWithOptions:0];
          
          NSLog(@"cbdata = %@", cbMessage);
          
          [_bridge send:jsonBase64String];
          
          
        }
        else {
          NSString *titl = [NSString stringWithFormat:LocalStr(@"DEVICESTATUS_FAIL_ALERT_TILTE"), _identifier];
          UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:titl
                                                              message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                                             delegate:nil
                                                    cancelButtonTitle:LocalStr(@"STR_OK")
                                                    otherButtonTitles:nil];
          [tempAlert show];
        }
      }
      else if (connection == [[_connSet objectForKey:TAG_DEVICE_VALUE] objectAtIndex:0]) {
        if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]] == NO) {
          UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                                              message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                                             delegate:nil
                                                    cancelButtonTitle:LocalStr(@"STR_OK")
                                                    otherButtonTitles:nil];
          [tempAlert show];
          
        }
        else {
          
          NSDictionary *cbData = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],
                                                                            @"code",
                                                                            @"",
                                                                            @"message",nil];
          
          NSDictionary *cbMessage = [NSDictionary dictionaryWithObjectsAndKeys:[[_connSet objectForKey:TAG_DEVICE_VALUE] objectAtIndex:1],
                                                                               @"responseId",
                                                                               cbData,
                                                                               @"responseData", nil];
          
          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:cbMessage options:NSJSONWritingPrettyPrinted error:nil];
          
          NSString *jsonBase64String = [jsonData base64EncodedStringWithOptions:0];
          
          NSLog(@"cbdata = %@", cbMessage);
          
          [_bridge send:jsonBase64String];
        }
        
      }
    }
    
    _recvData = [NSMutableData data];
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
    
    [[challenge sender]  useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
            forAuthenticationChallenge:challenge];
    
    [[challenge sender]  continueWithoutCredentialForAuthenticationChallenge: challenge];
    
  }
  
}

#pragma mark - button action

- (IBAction)backBtnPressed:(id)sender {
  [self dismissViewControllerAnimated:NO completion:nil];
  [self.view removeFromSuperview];
}

#pragma mark - UIWebView Delegate

#if 0

- (void)webViewDidStartLoad:(UIWebView *)webView
{

}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{

}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
  UIAlertView *alterview = [[UIAlertView alloc] initWithTitle:@"" message:[error localizedDescription]  delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
  
  [alterview show];
}
#endif

#pragma mark - JSBridge delegate

- (void) WebViewJSBridge:(id)bridge handleCostumProtocol:(NSURL *)url {
  NSLog(@"data = %@", [url lastPathComponent] );
  
  NSData *data = [[NSData alloc] initWithBase64EncodedString:[url lastPathComponent] options:0];
  
  NSString *decodeData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  
  NSLog(@"decode data = %@", decodeData);
  
  NSArray *action = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
  
  //sleep(5);
  
  for (int i = 0; i < [action count]; ++i) {
    [self handleJSCall:[action objectAtIndex:i]];
  }
}

#pragma mark - alertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  UIViewController *myDevVC = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
  myDevVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentViewController:myDevVC animated:YES completion:nil];
}

@end
