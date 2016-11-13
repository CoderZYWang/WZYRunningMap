//
//  AppDelegate.m
//  WZYRunningMap
//
//  Created by 王中尧 on 2016/11/12.
//  Copyright © 2016年 wzy. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()



@end

@implementation AppDelegate

- (BMKMapManager *)mapManager {
    if (!_mapManager) {
        _mapManager = [[BMKMapManager alloc] init];
    }
    return _mapManager;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 要通过get方法去获取，不然为nil
    // 授权百度地图
    BOOL ret = [self.mapManager start:@"4y4XlbaUoeMrr8Z77HsdrtuWo54gEmMf"  generalDelegate:self];
    if (!ret) {
        NSLog(@"manager start failed!");
    }
    
    return YES;
}

- (void)onGetNetworkState:(int)iError
{
    if (0 == iError) {
        NSLog(@"联网成功");
    }
    else{
        NSLog(@"onGetNetworkState %d",iError);
    }
    
}

- (void)onGetPermissionState:(int)iError
{
    if (0 == iError) {
        NSLog(@"授权成功");
    }
    else {
        NSLog(@"onGetPermissionState %d",iError);
    }
}


@end
