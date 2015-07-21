//
//  DeviceAuthViewController.m
//  OutletApp
//
//  Created by liming_llm on 15/5/4.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "DeviceAuthViewController.h"
#import "MBProgressHUD.h"
#import "Const.h"
#import "NSString+URLEncode.h"
#import "../Lib/PopMenu/PopMenu.h"
#import "DevicePermissionViewController.h"
#import "CHKeychain.h"

extern NSString * const kKeyUsernamePassword;
extern NSMutableDictionary *errorCode;
extern NSString *HOST_URL;

#define TAG_USERS_LIST    @"device_value"
#define TAG_DELETE_USER   @"device_unbind"

@interface DeviceAuthViewController () <MBProgressHUDDelegate, UICollectionViewDataSource, UICollectionViewDelegate> {
  MBProgressHUD *_HUD;
  NSMutableData *_recvData;
  NSMutableDictionary *_connSet;
  NSMutableDictionary *_configSet;
  NSArray *_userArray;
  UIAlertView *_unbindAlert;
  NSNumber *_currPId;
}

@property (nonatomic, strong) PopMenu *popMenu;

@end

@implementation DeviceAuthViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  //[_barItem setTitle:LocalStr(@"MYDEVICE_TITLE")];
  //[_barItem.leftBarButtonItem setTitle:LocalStr(@"LEFT_BTN_TITLE")];
  
  [self initGridView];
  
  NSUserDefaults *deviceDefaults = [NSUserDefaults standardUserDefaults];
  _accessToken = [deviceDefaults objectForKey:KEY_ACCESS_TOKEN];
  
  _recvData = [NSMutableData data];
  _configSet = [NSMutableDictionary dictionary];
}

- (void)viewDidAppear:(BOOL)animated {
  _connSet = [NSMutableDictionary dictionary];
  
  [self getUserList];
}

- (void) initGridView {
  // 为UICollectionView设置dataSource和delegate
  self.userGrid.dataSource = self;
  self.userGrid.delegate = self;
  
  // 创建UICollectionViewFlowLayout布局对象
  UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
  
  // 设置UICollectionView中各单元格的大小
  flowLayout.itemSize = CGSizeMake(self.userGrid.frame.size.width, 80);
  
  // 设置该UICollectionView只支持垂直滚动
  flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
  
  //int space = (self.view.frame.size.width - 120)/6;
  
  // 设置各分区上、左、下、右空白的大小。
  flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
  
  // 为UICollectionView设置布局对象
  self.userGrid.collectionViewLayout = flowLayout;
  
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self action:@selector(controlEventValueChanged) forControlEvents:UIControlEventValueChanged];
  
  [self.userGrid addSubview:self.refreshControl];
}

- (void)getUserList {
  NSString *req = [NSString stringWithFormat:@"%@"DEVICE_USERS_PATH, HOST_URL, _identifier];
  [self request:req content:nil tag:TAG_USERS_LIST type:@"GET"];
  
  NSLog(@"%@", req);

  _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _HUD.dimBackground = YES;
  _HUD.delegate = self;
}

- (void)deleteUser:(NSNumber *)pId {
  NSString *req = [NSString stringWithFormat:@"%@"DELETE_USER_PATH, HOST_URL, _identifier, pId];
  
  [self request:req content:nil tag:TAG_DELETE_USER type:@"DELETE"];
  
  _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _HUD.dimBackground = YES;
  _HUD.delegate = self;
}

- (void) request:(NSString *)reqUrl content:(NSString *)content tag:(id)tag type:(NSString *)type {
  NSURL *url = [NSURL URLWithString:[reqUrl URLEncodedString]];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  
  [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
  
  if (_accessToken != nil) {
    NSLog(@"access %@", _accessToken);
    [request addValue:_accessToken forHTTPHeaderField:@"Access-Token"];
  }
  
  [request addValue:PRODUCT_KEY forHTTPHeaderField:@"Product-Key"];
  if (content != nil) {
    [request setHTTPBody: [content dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  [request setHTTPMethod:type];
  
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

- (void)controlEventValueChanged {
  [self getUserList];
}

- (void)showMenu:(NSString *)phone pId:(NSNumber *)pId {
  NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:3];
  MenuItem *menuItem = [[MenuItem alloc] initWithTitle:LocalStr(@"STR_MODIFY") iconName:@"modify" glowColor:[UIColor grayColor] index:0];
  [items addObject:menuItem];
  
  menuItem = [[MenuItem alloc] initWithTitle:@"删除授权" iconName:@"unbind" glowColor:[UIColor colorWithRed:0.000 green:0.840 blue:0.000 alpha:1.000] index:0];
  [items addObject:menuItem];

  
  if (!_popMenu) {
    _popMenu = [[PopMenu alloc] initWithFrame:self.view.bounds items:items];
    _popMenu.menuAnimationType = kPopMenuAnimationTypeNetEase;
  }
  if (_popMenu.isShowed) {
    return;
  }
  
  UIViewController *devDVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DevicePermissionViewController"];
  ((DevicePermissionViewController*)devDVC).identifier = _identifier;
  ((DevicePermissionViewController*)devDVC).accessToken = _accessToken;
  ((DevicePermissionViewController*)devDVC).phone = phone;
  devDVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  
  __weak id weakSelf = self;
  
  _unbindAlert = [[UIAlertView alloc] initWithTitle:@""
                       message:@"确认删除？"
                      delegate:self
                   cancelButtonTitle:LocalStr(@"STR_CANCEL")
                   otherButtonTitles:LocalStr(@"STR_OK"), nil];
  
  __weak UIAlertView *weakAlert = _unbindAlert;
   
  _popMenu.didSelectedItemCompletion = ^(MenuItem *selectedItem) {
    
    if (selectedItem.index == 0) {
      [weakSelf presentViewController:devDVC animated:YES completion:nil];
    }
    else if (selectedItem.index == 1) {
      _currPId = pId;
      [weakAlert show];
    }
  };
  
  //  [_popMenu showMenuAtView:self.view];
  
  [_popMenu showMenuAtView:self.view startPoint:CGPointMake(CGRectGetWidth(self.view.bounds) - 60, CGRectGetHeight(self.view.bounds)) endPoint:CGPointMake(60, CGRectGetHeight(self.view.bounds))];
}

#pragma mark - action

- (void) configAction:(id)sender {
  UIButton *configBtn = sender;
  NSNumber *pId;
  NSString *phone;
  
  for (NSNumber *key in _configSet) {
    if (configBtn == (UIButton *)_configSet[key]) {
      pId = key;
      break;
    }
  }
  
  for (int i = 0; i < [_userArray count]; ++i) {
    if ([pId isEqual:[[_userArray objectAtIndex:i] objectForKey:@"permission_id"]]) {
      phone = [[_userArray objectAtIndex:i] objectForKey:@"phone"];
      break;
    }
  }
  
  [self showMenu:phone pId:pId];
}

- (IBAction)backPressed {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addUser
{
  UIViewController *devDVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DevicePermissionViewController"];
  ((DevicePermissionViewController*)devDVC).identifier = _identifier;
  ((DevicePermissionViewController*)devDVC).accessToken = _accessToken;
  ((DevicePermissionViewController*)devDVC).phone = nil;
  
  devDVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  
  [self presentViewController:devDVC animated:YES completion:nil];
}

#pragma mark - NSURLConnection 回调方法
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [_recvData appendData:data];
  
  NSLog(@"connection : didReceiveData");
  
}

- (void) connection:(NSURLConnection *)connection didFailWithError: (NSError *)error {
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
    
    
    if (respDic == nil) {
      UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_ERROR")
                               message:LocalStr(@"STR_NO_RESPONSE")
                              delegate:nil
                         cancelButtonTitle:LocalStr(@"STR_OK")
                         otherButtonTitles:nil];
      [temp show];
      
      [_userGrid reloadData];
      
      [_HUD hide:YES];
    }
    else {
      
      if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:10010]]) {
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
      
      
      NSLog(@"%@", respDic);
      
      if (connection == [_connSet objectForKey:TAG_USERS_LIST]) {
        if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
          _userArray = [respDic objectForKey:@"data"];
          
          NSLog(@"users array %@", _userArray);
        }
        else {
          UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                   message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                  delegate:nil
                             cancelButtonTitle:LocalStr(@"STR_OK")
                             otherButtonTitles:nil];
          [temp show];
        }
        
        [_HUD hide:YES];
        [self.refreshControl endRefreshing];
        [self.userGrid reloadData];
      }
      else if (connection == [_connSet objectForKey:TAG_DELETE_USER]) {
        NSLog(@"resp %@", respDic);
        
        if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
          [_HUD hide:YES];

          [self getUserList];
        }
        else {
          UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                   message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                  delegate:nil
                             cancelButtonTitle:LocalStr(@"STR_OK")
                             otherButtonTitles:nil];
          [temp show];
          
          [_HUD hide:YES];
        }
      }
    }
    
    _recvData = [NSMutableData data];
    
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


#pragma mark - CollectionView Delegate

// 该方法返回值决定各单元格的控件。
- (UICollectionViewCell *)collectionView:(UICollectionView *) collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  NSInteger cellNo = indexPath.section; // * 3 + indexPath.row;
  
  NSLog(@"cellNo = %ld", (long)cellNo);
  
  
  // 为单元格定义一个静态字符串作为标示符
  static NSString* cellId = @"userCell";
  
  // 从可重用单元格的队列中取出一个单元格
  UICollectionViewCell* cell = [collectionView
                  dequeueReusableCellWithReuseIdentifier:cellId
                  forIndexPath:indexPath];
  
  if (cellNo >= [_userArray count]) {
    cell.backgroundColor = [UIColor clearColor];
    return cell;
  }
  
  
  cell.backgroundColor = [UIColor whiteColor];
  cell.userInteractionEnabled = YES;
  
  
  UILabel* label = (UILabel*)[cell viewWithTag:2];
  label.text = [[_userArray objectAtIndex:cellNo] objectForKey:@"phone"];
  
  UILabel* label_id = (UILabel*)[cell viewWithTag:1];
  NSNumber *pre = [[_userArray objectAtIndex:cellNo] objectForKey:@"privilege"];
  
  if ([pre isEqualToNumber:[NSNumber numberWithInt:1]]) {
    label_id.text = @"仅接收消息";
  }
  else {
    label_id.text = @"操控设备并且接收消息";
  }
  
  
  label.textAlignment = NSTextAlignmentLeft;
  label.textColor = [UIColor blackColor];
  label.alpha = 1.0f;
  
  label_id.textAlignment = NSTextAlignmentLeft;
  label_id.textColor = [UIColor grayColor];
  label_id.alpha = 1.0f;
  
  
  UIButton *configBtn = (UIButton *)[cell viewWithTag:3];
  [configBtn setImage:[UIImage imageNamed:@"settings_red.png"] forState:UIControlStateNormal];
  
  [configBtn addTarget:self action:@selector(configAction:) forControlEvents:UIControlEventTouchUpInside];
  [_configSet setObject:configBtn forKey:[[_userArray objectAtIndex:cellNo] objectForKey:@"permission_id"]];
  
  return cell;
}

//显示多少行
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  //return deviceArray.count / 3 + ((deviceArray.count % 3) ? 1 : 0);
  
  return [_userArray count];
}

//显示多少列
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return 1;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  
  //NSInteger cellNo = indexPath.section;// * 3 + indexPath.row;
  
  NSLog(@"did select item %ld", (long)indexPath.section);
  
}

#pragma mark - alertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alertView == _unbindAlert) {
    if (buttonIndex == 1) {
      [self deleteUser:_currPId];
      _currPId = nil;
    }
  }
  else {
    UIViewController *myDevVC = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    myDevVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:myDevVC animated:YES completion:nil];
  }
}

@end
