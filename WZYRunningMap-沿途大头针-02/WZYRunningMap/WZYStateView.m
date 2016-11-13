//
//  WZYStateView.m
//  WZYRunningMap
//
//  Created by 王中尧 on 2016/11/13.
//  Copyright © 2016年 wzy. All rights reserved.
//

#import "WZYStateView.h"

@implementation WZYStateView

+ (instancetype)stateView {
    return [[[NSBundle mainBundle] loadNibNamed:@"WZYStateView" owner:nil options:nil] firstObject];
}

@end
