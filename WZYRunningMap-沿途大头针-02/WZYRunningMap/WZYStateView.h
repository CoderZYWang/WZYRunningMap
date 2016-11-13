//
//  WZYStateView.h
//  WZYRunningMap
//
//  Created by 王中尧 on 2016/11/13.
//  Copyright © 2016年 wzy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WZYStateView : UIView

@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionLabel;

+ (instancetype)stateView;

@end
