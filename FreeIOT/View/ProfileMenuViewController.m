//
//  ProfileMenuViewController.m
//  OutletApp
//
//  Created by liming_llm on 15/4/28.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "ProfileMenuViewController.h"
#import "UIViewController+RESideMenu.h"
#import "Const.h"
#import "CHKeychain.h"
#import "NSString+URLEncode.h"

extern NSString * const kKeyUsernamePassword;
extern NSString * const kKeyUsername;
extern NSString * const kKeyPassword;

extern NSMutableDictionary *errorCode;

#define TAG_CHANGE_PASS   @"change_pass"
#define TAG_LOGOUT      @"logout"

@interface ProfileMenuViewController () {
  MBProgressHUD *_HUD;
  NSMutableData *_recvData;
  NSMutableDictionary *_connSet;
}

@property (strong, readwrite, nonatomic) UITableView *tableView;

@end

@implementation ProfileMenuViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.tableView = ({
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height - 54 * 3) / 2.0f, self.view.frame.size.width, 54 * 3) style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.opaque = NO;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.backgroundView = nil;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.bounces = NO;
    tableView.scrollsToTop = NO;
    tableView;
  });
  [self.view addSubview:self.tableView];
  
  _recvData = [NSMutableData data];
  _connSet = [NSMutableDictionary dictionary];
}

- (void)doLogout {
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"", nil];
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, LOGOUT_PATH];
  
  [self request:req content:jsonInputString tag:TAG_LOGOUT];
  
  _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _HUD.dimBackground = YES;
  _HUD.delegate = self;
}

-(void) request:(NSString *)reqUrl content:(NSString *)content tag:(id)tag {
  NSURL *url = [NSURL URLWithString:[reqUrl URLEncodedString]];
  NSString *method = @"GET";
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  
  [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
  [request addValue:PRODUCT_KEY forHTTPHeaderField:@"Product-Key"];
  
  NSUserDefaults *deviceDefaults = [NSUserDefaults standardUserDefaults];
  NSString *accessToken = [deviceDefaults objectForKey:KEY_ACCESS_TOKEN];
  
  if (accessToken != nil) {
    [request addValue:accessToken forHTTPHeaderField:@"Access-Token"];
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

- (void)doChangePass {
  UIViewController *addDevVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ChangePassViewController"];
  [self presentViewController:addDevVC animated:YES completion:nil];
}

#pragma mark -
#pragma mark UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  switch (indexPath.row) {
    case 0:
      [self.sideMenuViewController hideMenuViewController];
      break;
      
    case 1:
      [self doChangePass];
      break;
      
    case 2:
      [self doLogout];
      break;
      
    default:
      break;
  }
}

#pragma mark -
#pragma mark UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 54;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
  return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:21];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.highlightedTextColor = [UIColor lightGrayColor];
    cell.selectedBackgroundView = [[UIView alloc] init];
  }
  
  NSArray *titles = @[@"我的设备", @"修改密码", @"退出账号"];
  //NSArray *images = @[@"IconHome", @"IconCalendar", @"IconProfile", @"IconSettings", @"IconEmpty"];
  cell.textLabel.text = titles[indexPath.row];
  //cell.imageView.image = [UIImage imageNamed:images[indexPath.row]];
  
  return cell;
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
    
    //NSDictionary * respDic = [NSJSONSerialization JSONObjectWithData:recvData options:NSJSONReadingMutableLeaves error:nil];
    
      if (connection == [_connSet objectForKey:TAG_LOGOUT])
      {
        [CHKeychain delete:kKeyUsernamePassword];
        [_HUD hide:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
      }
    
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

@end

