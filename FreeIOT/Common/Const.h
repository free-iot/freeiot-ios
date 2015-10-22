//
//  Const.h
//  OutletApp
//
//  Created by liming_llm on 15/3/14.
//  Copyright (c) 2015年 liming_llm. All rights reserved.
//

#ifndef OutletApp_Const_h
#define OutletApp_Const_h

#ifndef __OPTIMIZE__
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...) {}
#endif

//#define HOST_URL                @"https://api.pandocloud.com"
#define HOST_URL_FORMAL         @"https://api.pandocloud.com"
#define HOST_URL_TEST           @"https://testapi.pandocloud.com"
#define HOST_URL_STAGE          @"https://stageapi.pandocloud.com"

#define LOGIN_PATH              @"/v1/users/authentication"
#define LOGOUT_PATH             @"/v1/users/logout"
#define REGISTER_PATH           @"/v1/users/registration"
#define PASS_RESET_PATH         @"/v1/users/reset"
#define GET_AUTH_CODE           @"/v1/users/verification"
#define CHANGE_PASS_PATH        @"/v1/users/password"

#define GET_DEVICES_PATH        @"/v1/devices"
#define BIND_DEVICE_PATH        @"/v1/devices/binding"
#define DEVICE_REGSTER_PATH     @"/v1/devices/registration"
#define DEVICE_LOGIN_PATH       @"/v1/devices/authentication"
#define SET_DEVICE_VALUE        @"/v1/devices/%@/commands"
#define DEVICE_STATUS           @"/v1/devices/%@/status/current"
#define SET_DEVICE_STATUS       @"/v1/devices/%@/status"
#define ALLOW_PERMITIONS        @"/v1/devices/%@/permissions"
#define DEVICE_UNBIND_PATH      @"/v1/devices/%@/unbinding"
#define MODIFY_DEVICE_PATH      @"/v1/devices/%@"
#define DEVICE_USERS_PATH       @"/v1/devices/%@/permissions"
#define DELETE_USER_PATH        @"/v1/devices/%@/permissions/%@"
#define DEVICE_DELETE_PATH      @"/v1/devices/%@"

#define PRODUCT_INFO            @"/v1/product/info"

#define VENDOR_KEY              @"570f93557db3532727b54336e47f1a3500b3c0e564"
//#define PRODUCT_KEY             @"4518befdb4c18f0061c642b8637d687aa8c4bb9165"
#define PRODUCT_KEY             @"f07fd3f2782ff4964b74d51e89ad0aabf0192ec066"
#define DEVICE_PRODUCT_KEY      @"f07fd3f2782ff4964b74d51e89ad0aabf0192ec066"

#define LocalStr(a)             NSLocalizedStringFromTable(a, @"Strings", nil)

#define KEY_PUSH_TOKEN          @"push_token"
#define KEY_ACCESS_TOKEN        @"access_token"
#define KEY_DEVICE_REGISTERED   @"devcie_registered"
#define KEY_DEVICE_ID           @"device_id"
#define KEY_DEVICE_SECRET       @"device_secret"
#define KEY_DEVICE_KEY          @"device_key"
#define KEY_DEVICE_BINDED       @"device_binded"
#define KEY_PRODUCT_INFO        @"product_info"

#define AP_SSID                 @"freeiot" //[self.productInfo objectForKey:@"code"]

#define IS_MAIL                 NO

#endif
