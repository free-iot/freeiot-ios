//
//  MyDevicesViewController.m
//  OutletApp
//
//  Created by liming_llm on 15/3/14.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#import "MyDevicesViewController.h"
#import "AddDeviceViewController.h"
#import "DeviceDetailViewController.h"
#import "MBProgressHUD.h"
#import "../Common/Const.h"
#import "NSString+URLEncode.h"
#import "CHKeychain.h"
#import "DevicePermissionViewController.h"
#import "../Lib/PopMenu/PopMenu.h"
#import "ModifyDeviceViewController.h"
#import "DeviceAuthViewController.h"


extern NSString * const kKeyUsernamePassword;
extern NSString * const kKeyUsername;
extern NSString * const kKeyPassword;

extern NSMutableDictionary *errorCode;
extern NSString *HOST_URL;

#define TAG_LOGIN       @"login"
#define TAG_LOGOUT      @"logout"
#define TAG_PRODUCT_INFO  @"product_info"
#define TAG_DEVICE_LIST   @"device_list"
#define TAG_DEVICE_STATUS   @"device_status"
#define TAG_DEVICE_VALUE  @"device_value"
#define TAG_DEVICE_UNBIND   @"device_unbind"
#define TAG_DEVICE_DELETE   @"device_delete"

@interface MyDevicesViewController () <MBProgressHUDDelegate, UICollectionViewDataSource, UICollectionViewDelegate> {
  MBProgressHUD *_HUD;
  NSMutableData *_recvData;
  int _reqFlag;
  NSMutableDictionary *_connSet;
  NSMutableDictionary *_switchSet;
  NSArray *_deviceArray;
  NSMutableArray *_deviceStatus;
  NSDictionary *_productInfo;
  UIView *_greyView;
  UIAlertView *_unbindAlert;
  UIAlertView *_deleteAlert;
  UIAlertView *_tokenAlert;
  NSString *_currIdentifier;
}

@property (nonatomic, strong) PopMenu *popMenu;

@end

@implementation MyDevicesViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  [_barItem setTitle:LocalStr(@"MYDEVICE_TITLE")];
  //[_barItem.leftBarButtonItem setTitle:LocalStr(@"LEFT_BTN_TITLE")];
  
  _switchSet = [NSMutableDictionary dictionary];
  
  [self initCarGridView];
  
  _recvData = [NSMutableData data];
  
  //UIBarButtonItem *backItem = [[UIBarButtonItem alloc] init];
  //backItem.title = @"返回";
  //_barItem.backBarButtonItem = nil;
  
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated {
  _connSet = [NSMutableDictionary dictionary];
  
  [self userLogin];
}

-(void) initCarGridView {
  // 为UICollectionView设置dataSource和delegate
  self.deviceGrid.dataSource = self;
  self.deviceGrid.delegate = self;
  
  // 创建UICollectionViewFlowLayout布局对象
  UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
  
  // 设置UICollectionView中各单元格的大小
  flowLayout.itemSize = CGSizeMake(self.deviceGrid.frame.size.width, 80);
  
  // 设置该UICollectionView只支持垂直滚动
  flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
  
  //int space = (self.view.frame.size.width - 120)/6;
  
  // 设置各分区上、左、下、右空白的大小。
  flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
  
  // 为UICollectionView设置布局对象
  self.deviceGrid.collectionViewLayout = flowLayout;
  
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self action:@selector(controlEventValueChanged) forControlEvents:UIControlEventValueChanged];
  
  [self.deviceGrid addSubview:self.refreshControl];
  
  
  //添加长按手势
  UILongPressGestureRecognizer * longPressGr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(cellLongPress:)];
  longPressGr.minimumPressDuration = 1.0;
  //[self.deviceGrid addGestureRecognizer:longPressGr];
  
}


#pragma mark - network req

- (void)userLogin {
  NSMutableDictionary *usernamepasswdKVPairs = (NSMutableDictionary *)[CHKeychain load:kKeyUsernamePassword];
  NSString *username = [usernamepasswdKVPairs objectForKey:kKeyUsername];
  NSString *passwd = [usernamepasswdKVPairs objectForKey:kKeyPassword];
  
#if IS_MAIL
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:username, @"mail", passwd, @"password", nil];
#else
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:username, @"mobile", passwd, @"password", nil];
#endif
  
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, LOGIN_PATH];
  
  NSLog(@"req = %@\n%@", req, jsonInputString);
  
  _reqFlag = 0;
  
  _connSet = nil;
  _connSet = [NSMutableDictionary dictionary];
  
  
  [self request:req content:jsonInputString tag:TAG_LOGIN];
  
  _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _HUD.dimBackground = YES;
  _HUD.delegate = self;
  //HUD.labelText = @"获取列表";
}

- (void)getDevicesReq {
  
  NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, GET_DEVICES_PATH];
  
  _reqFlag = 0;
  
  
  [self request:req content:nil tag:TAG_DEVICE_LIST];
 
#if 0
  HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  HUD.dimBackground = YES;
  HUD.delegate = self;
  HUD.labelText = @"获取列表";
#endif
  
}

- (void)getProduceInfo {
  
  NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, PRODUCT_INFO];
  
  
  NSLog(@"3 = %@", req);
  
  [self request:req content:nil tag:TAG_PRODUCT_INFO];
  
  
  // Do something usefull in here instead of sleeping ...
  //sleep(3);
}

- (BOOL)getDeviceStatus:(int) index {
  if ([[[_deviceArray objectAtIndex:index]objectForKey:@"status"] isEqualToString:@"online"]) {
    NSString *req = [NSString stringWithFormat:@"%@"DEVICE_STATUS, HOST_URL, [[_deviceArray objectAtIndex:index]objectForKey:@"identifier"]];
  
    //reqFlag = index;
  
    NSLog(@"%d = %@", _reqFlag, req);
      
    //NSDictionary *deviceStatusTag = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:i], TAG_DEVICE_STATUS, nil];
  
    [self request:req content:nil tag:TAG_DEVICE_STATUS];
  }
  else {
    [_deviceStatus insertObject:[NSNumber numberWithInt:0] atIndex:_reqFlag];
      
    _reqFlag++;
      
    if (_reqFlag < [_deviceArray count]) {
      [self getDeviceStatus:_reqFlag];
    }
    else {
      [_HUD hide:YES];
      [self.refreshControl endRefreshing];
      [self.deviceGrid reloadData];
    }
  }
    
  return YES;
}

- (void)setDeviceValue:(NSNumber*) value identifier:(NSString *)identifier {
  NSString *req = [NSString stringWithFormat:@"%@"SET_DEVICE_VALUE, HOST_URL, identifier];
  
  NSArray *params = [[NSArray alloc]initWithObjects:value, nil];
  
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:params, @"switch", nil];
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSLog(@"5 = %@", req);
  NSLog(@"%@", jsonInputString);
  
  [self request:req content:jsonInputString tag:TAG_DEVICE_VALUE];
}

- (void)unbindDevice:(NSString *)identifier {
  NSString *req = [NSString stringWithFormat:@"%@"DEVICE_UNBIND_PATH, HOST_URL, identifier];
  
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"", nil];
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  [self request:req content:jsonInputString tag:TAG_DEVICE_UNBIND];
}

- (void)deleteDevice:(NSString *)identifier {
  NSString *req = [NSString stringWithFormat:@"%@"DEVICE_DELETE_PATH, HOST_URL, identifier];
  [self request:req content:nil tag:TAG_DEVICE_DELETE];
  
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
  
  if (_accessToken != nil) {
    [request addValue:_accessToken forHTTPHeaderField:@"Access-Token"];
  }
  
  if (content != nil) {
    [request setHTTPBody: [content dataUsingEncoding:NSUTF8StringEncoding]];
    method = @"POST";
  }
  
  if ([tag isEqualToString:TAG_DEVICE_DELETE]) {
    method = @"DELETE";
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

- (IBAction)addDevice:(id)sender {
  UIViewController *addDevVC = [self.storyboard instantiateViewControllerWithIdentifier:@"AddDeviceViewController"];
  ((AddDeviceViewController *)addDevVC).productInfo = _productInfo;
  ((AddDeviceViewController *)addDevVC).accessToken = _accessToken;
  
  addDevVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  
  ((AddDeviceViewController *)addDevVC).barItem.backBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"d" style:UIBarButtonItemStylePlain target:nil action:nil];
  
  [self presentViewController:addDevVC animated:YES completion:nil];
}

-(void) switchAction:(id)sender {
  UIButton *configBtn = sender;
  NSString *identifier;
  NSString *status;
  NSString *name;
  NSNumber *isOwner;
  
  for (NSString *key in _switchSet) {
    if (configBtn == (UIButton *)_switchSet[key]) {
      identifier = key;
      break;
    }
  }
  
  for (int i = 0; i < [_deviceArray count]; ++i) {
    if ([identifier isEqualToString:[[_deviceArray objectAtIndex:i] objectForKey:@"identifier"]]) {
      status = [[_deviceArray objectAtIndex:i] objectForKey:@"status"];
      name = [[_deviceArray objectAtIndex:i] objectForKey:@"name"];
      isOwner = [[_deviceArray objectAtIndex:i] objectForKey:@"is_owner"];
      break;
    }
  }
  
  if ([name isEqualToString:@""]) {
    name = [NSString stringWithFormat:@"%@", [_productInfo objectForKey:@"name"]];
  }
  
  NSLog(@"%@ %@", identifier, isOwner);
  
  [self showMenu:identifier name:name isOwner:isOwner];
  
#if 0
  
  if ([status isEqualToString:@"online"]) {
    

    NSLog(@"SWITCH %@", identifier);
  
    if (czSwitch.on == YES) {
      value = [NSNumber numberWithInt:1];
    }
    else {
      value = [NSNumber numberWithInt:0];
    }
  
    [self setDeviceValue:value identifier:identifier];
  
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  
    HUD.dimBackground = YES;
  
    // Regiser for HUD callbacks so we can remove it from the window at the right time
    HUD.delegate = self;
  }
  else {
    //[czSwitch setOn:!czSwitch.on animated:YES];
    
    UIAlertView *temp = [[UIAlertView alloc] initWithTitle:@"设备不在线"
                             message:@"设备不在线，无法进行设置"
                            delegate:nil
                       cancelButtonTitle:@"确定"
                       otherButtonTitles:nil];
    [temp show];
    
  }
#endif
  
}

- (IBAction)userExit:(id)sender {
  NSDictionary *inputData = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"", nil];
  NSData *jsonInputData = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingPrettyPrinted error:nil];
  NSString *jsonInputString = [[NSString alloc] initWithData:jsonInputData encoding:NSUTF8StringEncoding];
  
  NSString *req = [NSString stringWithFormat:@"%@%@", HOST_URL, LOGOUT_PATH];
  
  [self request:req content:jsonInputString tag:TAG_LOGOUT];
  
  _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _HUD.dimBackground = YES;
  _HUD.delegate = self;
}

- (void)controlEventValueChanged {
  //HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  
  //HUD = [[MBProgressHUD alloc] initWithView:self.view];
  
  //HUD.dimBackground = YES;
  //HUD.delegate = self;
  //HUD.labelText = @"获取列表";
  
  //[self.view addSubview:HUD];
  
  //[HUD showWhileExecuting:@selector(test) onTarget:self withObject:nil animated:YES];
  
  //self.refreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:@"刷新设备列表"];
  
  [self getDevicesReq];
  
}

- (void)cellLongPress:(UILongPressGestureRecognizer *)gesture {
  if(gesture.state == UIGestureRecognizerStateBegan) {
    CGPoint point = [gesture locationInView:self.deviceGrid];
    NSIndexPath * indexPath = [self.deviceGrid indexPathForItemAtPoint:point];
    
    if(indexPath == nil) {
      return;
    }
    
    //UICollectionViewCell *cell = [self.deviceGrid cellForItemAtIndexPath:indexPath];
    
    if (![[[_deviceArray objectAtIndex:indexPath.section] objectForKey:@"status"] isEqualToString:@"online"]) {
      return;
    }
    
    UIViewController *devDVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DevicePermissionViewController"];
    ((DevicePermissionViewController*)devDVC).identifier = [[_deviceArray objectAtIndex:indexPath.section] objectForKey:@"identifier"];
    ((DevicePermissionViewController*)devDVC).accessToken = _accessToken;
    
    devDVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:devDVC animated:YES completion:nil];
  }
}

#pragma mark - local

NSInteger deviceStatusSort(id obj1, id obj2, void* context) {
  if ([[(NSDictionary *)obj1 objectForKey:@"status"] isEqualToString:@"offline"]
    && [[(NSDictionary *)obj2 objectForKey:@"status"] isEqualToString:@"online"]) {
    return (NSComparisonResult)NSOrderedDescending;
  }
  
  if ([[(NSDictionary *)obj2 objectForKey:@"status"] isEqualToString:@"offline"]
    && [[(NSDictionary *)obj1 objectForKey:@"status"] isEqualToString:@"online"]) {
    return (NSComparisonResult)NSOrderedAscending;
  }
  
  return (NSComparisonResult)NSOrderedSame;
}

- (void)showMenu:(NSString *)identifier name:(NSString *)name isOwner:(NSNumber *)isOwner {
  _popMenu = nil;
  
  if ([isOwner intValue] == 1) {
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:3];
    MenuItem *menuItem = [[MenuItem alloc] initWithTitle:LocalStr(@"STR_DEVICEAUTH") iconName:@"auth" glowColor:[UIColor grayColor] index:0];
    [items addObject:menuItem];
    
    menuItem = [[MenuItem alloc] initWithTitle:LocalStr(@"STR_UNBIND") iconName:@"unbind" glowColor:[UIColor colorWithRed:0.000 green:0.840 blue:0.000 alpha:1.000] index:0];
    [items addObject:menuItem];
    
    menuItem = [[MenuItem alloc] initWithTitle:LocalStr(@"STR_MODIFY") iconName:@"modify" glowColor:[UIColor colorWithRed:0.000 green:0.840 blue:0.000 alpha:1.000] index:0];
    [items addObject:menuItem];
    
    
    if (!_popMenu) {
      _popMenu = [[PopMenu alloc] initWithFrame:self.view.bounds items:items];
      _popMenu.menuAnimationType = kPopMenuAnimationTypeNetEase;
    }
    if (_popMenu.isShowed) {
      return;
    }
    
    UIViewController *devDVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DeviceAuthViewController"];
    ((DeviceAuthViewController*)devDVC).identifier = identifier;
    devDVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    UIViewController *moDVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ModifyDeviceViewController"];
    ((ModifyDeviceViewController*)moDVC).identifier = identifier;
    ((ModifyDeviceViewController*)moDVC).name = name;
    moDVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    __weak id weakSelf = self;
    
    _unbindAlert = [[UIAlertView alloc] initWithTitle:@""
                         message:LocalStr(@"UNBIND_ALERT_MSG")
                        delegate:self
                     cancelButtonTitle:LocalStr(@"STR_CANCEL")
                     otherButtonTitles:LocalStr(@"STR_OK"), nil];
    
    __weak UIAlertView *weakAlert = _unbindAlert;
    
    _popMenu.didSelectedItemCompletion = ^(MenuItem *selectedItem) {
      
      if (selectedItem.index == 0) {
        [weakSelf presentViewController:devDVC animated:YES completion:nil];
      }
      else if (selectedItem.index == 1) {
        _currIdentifier = identifier;
        [weakAlert show];
      }
      else if (selectedItem.index == 2) {
        [weakSelf presentViewController:moDVC animated:YES completion:nil];
      }
    };
    
    //  [_popMenu showMenuAtView:self.view];
  }
  else {
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:3];
    MenuItem *menuItem;
    
    menuItem = [[MenuItem alloc] initWithTitle:@"删除设备" iconName:@"unbind" glowColor:[UIColor colorWithRed:0.000 green:0.840 blue:0.000 alpha:1.000] index:0];
    [items addObject:menuItem];
    
    //menuItem = [[MenuItem alloc] initWithTitle:LocalStr(@"STR_MODIFY") iconName:@"modify" glowColor:[UIColor colorWithRed:0.000 green:0.840 blue:0.000 alpha:1.000] index:0];
    //[items addObject:menuItem];
    
    
    if (!_popMenu) {
      _popMenu = [[PopMenu alloc] initWithFrame:self.view.bounds items:items];
      _popMenu.menuAnimationType = kPopMenuAnimationTypeNetEase;
    }
    if (_popMenu.isShowed) {
      return;
    }
    
    UIViewController *moDVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ModifyDeviceViewController"];
    ((ModifyDeviceViewController*)moDVC).identifier = identifier;
    ((ModifyDeviceViewController*)moDVC).name = name;
    moDVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    //__weak id weakSelf = self;
    
    
    _deleteAlert = [[UIAlertView alloc] initWithTitle:@""
                         message:@"确认删除？"
                        delegate:self
                     cancelButtonTitle:LocalStr(@"STR_CANCEL")
                     otherButtonTitles:LocalStr(@"STR_OK"), nil];
    
    __weak UIAlertView *weakAlert = _deleteAlert;
    
    
    _popMenu.didSelectedItemCompletion = ^(MenuItem *selectedItem) {
      
      if (selectedItem.index == 0) {
        _currIdentifier = identifier;
        [weakAlert show];
      }
      //else if (selectedItem.index == 1)
      //{
      //  [weakSelf presentViewController:moDVC animated:YES completion:nil];
      //}
    };
  }
  
  [_popMenu showMenuAtView:self.view startPoint:CGPointMake(CGRectGetWidth(self.view.bounds) - 60, CGRectGetHeight(self.view.bounds)) endPoint:CGPointMake(60, CGRectGetHeight(self.view.bounds))];
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
    
    
    if (respDic == nil) {
      UIAlertView *temp = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_ERROR")
                               message:LocalStr(@"STR_NO_RESPONSE")
                              delegate:nil
                         cancelButtonTitle:LocalStr(@"STR_OK")
                         otherButtonTitles:nil];
      [temp show];
      
      [_deviceGrid reloadData];
      
      [_HUD hide:YES];
    }
    else {
      if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:10010]]) {
        [CHKeychain delete:kKeyUsernamePassword];
        
        _tokenAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                            message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                             delegate:self
                        cancelButtonTitle:LocalStr(@"STR_OK")
                        otherButtonTitles:nil];
        [_tokenAlert show];
        
        [self.refreshControl endRefreshing];
        
        [self.deviceGrid reloadData];
        
        [_HUD hide:YES];
        
        return;
      }
    
      if (connection == [_connSet objectForKey:TAG_LOGIN]) {
        NSDictionary * dataDic = [respDic objectForKey:@"data"];
        _accessToken = [dataDic objectForKey:@"access_token"];
        
        if (_accessToken != nil) {
          NSUserDefaults *deviceDefaults = [NSUserDefaults standardUserDefaults];
          [deviceDefaults setObject:_accessToken forKey:KEY_ACCESS_TOKEN];
          [deviceDefaults synchronize];
        }
        
        [self getDevicesReq];
      }
      else if (connection == [_connSet objectForKey:TAG_DEVICE_LIST]) {
        
        if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
          
          NSLog(@"resp %@", respDic);
          
          _deviceArray = [respDic objectForKey:@"data"];
          
          NSLog(@"device array %@", _deviceArray);
          
          _deviceArray = [_deviceArray sortedArrayUsingFunction:deviceStatusSort context:nil];
          
          _deviceStatus = [NSMutableArray arrayWithCapacity:[_deviceArray count]];
          
          for (int i = 0; i < [_deviceArray count]; ++i) {
            [_deviceStatus addObject:[NSNumber numberWithInt:0]];
          }
          
          [self getProduceInfo];
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
      else if (connection == [_connSet objectForKey:TAG_PRODUCT_INFO]) {
        NSLog(@"resp %@", respDic);
        
        _productInfo = [respDic objectForKey:@"data"];
        
        NSUserDefaults *deviceDefaults = [NSUserDefaults standardUserDefaults];
        [deviceDefaults setObject:_productInfo forKey:KEY_PRODUCT_INFO];
        [deviceDefaults synchronize];
        
        if ([_deviceArray count] > 0) {
          //[self getDeviceStatus:reqFlag];
        }
        else {
          [self.refreshControl endRefreshing];
          [_HUD hide:YES];
        }
        
      }
      else if (connection == [_connSet objectForKey:TAG_DEVICE_STATUS]) {
        NSLog(@"resp %d %@", _reqFlag, respDic);
        
        if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
          NSDictionary *respData = [respDic objectForKey:@"data"];
          
          [_deviceStatus insertObject:[[respData objectForKey:@"switch"] objectAtIndex:0] atIndex:_reqFlag];
        }
        else {
          NSString *titl = [NSString stringWithFormat:@"获取设备%@状态失败", [[_deviceArray objectAtIndex:_reqFlag] objectForKey:@"identifier"]];
          UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:titl
                                                              message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                                             delegate:nil
                                                    cancelButtonTitle:@"确定"
                                                    otherButtonTitles:nil];
          [tempAlert show];
        }
        
        _reqFlag++;
        
        if (_reqFlag < [_deviceArray count]) {
          [self getDeviceStatus:_reqFlag];
        }
        else {
          [_HUD hide:YES];
          
          [self.refreshControl endRefreshing];
          
          [self.deviceGrid reloadData];
        }
      }
      else if (connection == [_connSet objectForKey:TAG_DEVICE_VALUE]) {
        if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]] == NO) {
          UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                                              message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                                             delegate:nil
                                                    cancelButtonTitle:LocalStr(@"STR_OK")
                                                    otherButtonTitles:nil];
          [tempAlert show];
          
          [self.deviceGrid reloadData];
        }
        
        [_HUD hide:YES];
      }
      else if (connection == [_connSet objectForKey:TAG_DEVICE_UNBIND]) {
        if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]] == NO) {
          UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                                              message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                                             delegate:nil
                                                    cancelButtonTitle:LocalStr(@"STR_OK")
                                                    otherButtonTitles:nil];
          [tempAlert show];
          
          [self.deviceGrid reloadData];
          
          [_HUD hide:YES];
        }
        else {
          [self getDevicesReq];
        }
      }
      else if (connection == [_connSet objectForKey:TAG_DEVICE_DELETE]) {
        if ([[respDic objectForKey:@"code"] isEqualToNumber:[NSNumber numberWithInt:0]] == NO) {
          UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"STR_FAIL")
                                                              message:[errorCode objectForKey:[respDic objectForKey:@"code"]]
                                                             delegate:nil
                                                    cancelButtonTitle:LocalStr(@"STR_OK")
                                                    otherButtonTitles:nil];
          [tempAlert show];
          
          [self.deviceGrid reloadData];
          
          [_HUD hide:YES];
        }
        else {
          [self getDevicesReq];
        }
      }
      
      
      [self.refreshControl endRefreshing];
      
      [self.deviceGrid reloadData];
      
      [_HUD hide:YES];
      
    }


    _recvData = [NSMutableData data];
    
    if (connection == [_connSet objectForKey:TAG_LOGOUT]) {
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


#pragma mark - CollectionView Delegate

// 该方法返回值决定各单元格的控件。
- (UICollectionViewCell *)collectionView:(UICollectionView *) collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  NSInteger cellNo = indexPath.section; // * 3 + indexPath.row;
  
  NSLog(@"cellNo = %ld", (long)cellNo);
  
  
  // 为单元格定义一个静态字符串作为标示符
  static NSString* cellId = @"deviceCell";
  
  // 从可重用单元格的队列中取出一个单元格
  UICollectionViewCell* cell = [collectionView
                  dequeueReusableCellWithReuseIdentifier:cellId
                  forIndexPath:indexPath];
  
  if (cellNo >= _deviceArray.count) {
    cell.backgroundColor = [UIColor clearColor];
    return cell;
  }

  cell.backgroundColor = [UIColor whiteColor];
  cell.userInteractionEnabled = YES;
  
  UILabel* label = (UILabel*)[cell viewWithTag:2];
  label.text = [[_deviceArray objectAtIndex:cellNo] objectForKey:@"name"];
  
  if ([label.text isEqualToString:@""]) {
    label.text = [NSString stringWithFormat:@"%@", [_productInfo objectForKey:@"name"]];
  }
  
  
  UILabel* label_id = (UILabel*)[cell viewWithTag:1];
  label_id.text = [[_deviceArray objectAtIndex:cellNo] objectForKey:@"identifier"];
  
  label.textAlignment = NSTextAlignmentLeft;
  label.textColor = [UIColor blackColor];
  label.alpha = 1.0f;
  
  label_id.textAlignment = NSTextAlignmentLeft;
  label_id.textColor = [UIColor grayColor];
  label_id.alpha = 1.0f;
  
  if ([[[_deviceArray objectAtIndex:cellNo] objectForKey:@"status"] isEqualToString:@"online"]) {
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = [UIColor blackColor];
    label.alpha = 1.0f;
    
    label_id.textAlignment = NSTextAlignmentLeft;
    label_id.textColor = [UIColor grayColor];
    label_id.alpha = 1.0f;
  }
  else {
    
    label.textColor = [UIColor grayColor];
    label.alpha = 0.8f;
    
    label_id.alpha = 0.8f;
  }

  UIButton *configBtn = (UIButton *)[cell viewWithTag:3];
  
  if ([[[_deviceArray objectAtIndex:cellNo] objectForKey:@"is_owner"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
    [configBtn setImage:[UIImage imageNamed:@"settings_red"] forState:UIControlStateNormal];
  }
  else {
    [configBtn setImage:[UIImage imageNamed:@"settings_yellow"] forState:UIControlStateNormal];
  }
  
  [configBtn addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventTouchUpInside];
  [_switchSet setObject:configBtn forKey:[[_deviceArray objectAtIndex:cellNo] objectForKey:@"identifier"]];
  
  return cell;
}

//显示多少行
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  //return deviceArray.count / 3 + ((deviceArray.count % 3) ? 1 : 0);
  
  return [_deviceArray count];
}

//显示多少列
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
#if 0
  if ((section + 1) * 3 <= [deviceArray count])
    return 3;
  else
    return [deviceArray count] % 3;
#endif
  
  return 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

  NSInteger cellNo = indexPath.section;// * 3 + indexPath.row;
  
  NSLog(@"did select item %ld", (long)cellNo);
  
  
  if ([[[_deviceArray objectAtIndex:cellNo] objectForKey:@"status"]  isEqualToString:@"online"]) {
    
    UIViewController *devDVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DeviceDetailViewController"];
    ((DeviceDetailViewController*)devDVC).identifier = [[_deviceArray objectAtIndex:cellNo] objectForKey:@"identifier"];
    ((DeviceDetailViewController*)devDVC).accessToken = _accessToken;
    ((DeviceDetailViewController*)devDVC).url = [[_deviceArray objectAtIndex:cellNo] objectForKey:@"app"];
    ((DeviceDetailViewController*)devDVC).dtitle = [[_deviceArray objectAtIndex:cellNo] objectForKey:@"name"];
    
    //NSLog(@"%@", [productInfo objectForKey:@"app"]);
    
    devDVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:devDVC animated:YES completion:nil];
  }
  else {
    
    UIAlertView *tempAlert = [[UIAlertView alloc] initWithTitle:LocalStr(@"DEVICEOFFLINE_ALERT_TITLE")
                                                        message:LocalStr(@"DEVICEOFFLINE_ALERT_MSG")
                                                       delegate:nil
                                              cancelButtonTitle:LocalStr(@"STR_OK")
                                              otherButtonTitles:nil];
    [tempAlert show];
  }
}

#pragma mark - alertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alertView == _unbindAlert) {
    if (buttonIndex == 1) {
      [self unbindDevice:_currIdentifier];
      
      _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      _HUD.dimBackground = YES;
      _HUD.delegate = self;
      
      _currIdentifier = nil;
    }
  }
  else if (alertView == _deleteAlert) {
    if (buttonIndex == 1) {
      [self deleteDevice:_currIdentifier];
      _currIdentifier = nil;
    }
  }
  else if (alertView == _tokenAlert) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}


@end

