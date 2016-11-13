//
//  ViewController.m
//  WZYRunningMap
//
//  Created by 王中尧 on 2016/11/12.
//  Copyright © 2016年 wzy. All rights reserved.
//

#import "ViewController.h"

#import "WZYStateView.h"

typedef enum : NSUInteger {
    TrailStart,
    TrailEnd
} Trail;

@interface ViewController () <BMKMapViewDelegate,BMKLocationServiceDelegate>

// 百度地图主面板
@property (nonatomic, strong) BMKMapView *mapView;

// 定位服务
@property (nonatomic, strong) BMKLocationService *service;

// 中心点
@property (nonatomic, assign) CLLocationCoordinate2D center;

/** 记录上一次的位置 */
@property (nonatomic, strong) CLLocation *preLocation;

/** 位置数组 */
@property (nonatomic, strong) NSMutableArray *locationArrayM;

/** 轨迹线 */
@property (nonatomic, strong) BMKPolyline *polyLine;

/** 轨迹记录状态 */
@property (nonatomic, assign) Trail trail;

/** 起点大头针 */
@property (nonatomic, strong) BMKPointAnnotation *startPoint;

/** 终点大头针 */
@property (nonatomic, strong) BMKPointAnnotation *endPoint;

/** 累计步行时间 */
@property (nonatomic,assign) NSTimeInterval sumTime;

/** 累计步行距离 */
@property (nonatomic,assign) CGFloat sumDistance;

/** 状态显示框 */
@property (nonatomic, strong) WZYStateView *stateView;

@end

@implementation ViewController

//- (CLLocationCoordinate2D)center {
//    _center.latitude = 22.597207;
//    _center.longitude = 113.844876;
//    return _center;
//}

- (UIView *)stateView {
    if (!_stateView) {
        _stateView = [WZYStateView stateView];
    }
    return _stateView;
}

- (NSMutableArray *)locationArrayM
{
    if (!_locationArrayM) {
        _locationArrayM = [NSMutableArray array];
    }
    return _locationArrayM;
}

- (BMKLocationService *)service {
    if (!_service) {
        _service = [[BMKLocationService alloc] init];
    }
    return _service;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.mapView viewWillAppear];
    self.mapView.delegate = self;
    self.service.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.mapView viewWillDisappear];
    self.mapView.delegate = nil;
    self.service.delegate = nil; // 此操作在于释放内存
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 01 UI 界面设置
    [self setupUI];
    
}

- (void)setupUI {
    // 0101 设置地图主体
    BMKMapView *mapView = [[BMKMapView alloc] initWithFrame:CGRectMake(0, 70, self.view.bounds.size.width, self.view.bounds.size.height - 70)];
    self.mapView = mapView;
    [self.view addSubview:mapView];
    
    self.mapView.mapType = BMKMapTypeStandard;
    self.mapView.zoomLevel = 19;
    self.mapView.showMapScaleBar = YES;
   
//    self.mapView.compassPosition = CGPointMake(100, 100);
//    self.mapView.centerCoordinate = self.center;
    // 允许旋转地图
    self.mapView.rotateEnabled = YES;
    
    // 定位图层自定义样式参数
    BMKLocationViewDisplayParam *displayParam = [[BMKLocationViewDisplayParam alloc]init];
    //跟随态旋转角度是否生效
    displayParam.isRotateAngleValid = NO;
    //精度圈是否显示
    displayParam.isAccuracyCircleShow = NO;
    //定位偏移量(经度)
    displayParam.locationViewOffsetX = 0;
    //定位偏移量（纬度）
    displayParam.locationViewOffsetY = 0;
    displayParam.locationViewImgName = @"walk";
    [self.mapView updateLocationViewWithParam:displayParam];
    
    
    
    
    // 必须在开始定位之前设置
    // 设置定位更新的最小距离（2M）
    self.service.distanceFilter = 10;
    // 设置定位精度
    self.service.desiredAccuracy = kCLLocationAccuracyBest;
    
    
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = BMKUserTrackingModeNone;
    
//    [self clean];
    
    // 0102 设置状态展示框
    self.stateView.frame = CGRectMake(20, self.view.bounds.size.height - 110, self.view.bounds.size.width - 40, 90);
//    self.stateView.backgroundColor = [UIColor colorWithRed:128/255.0 green:64/255.0 blue:0 alpha:0.6];
    [self.view addSubview:self.stateView];
    
}


// 开始定位
- (IBAction)startLocation:(id)sender {
    
    // 先关闭显示的定位图层（一开始是定位到首都）
//    self.mapView.showsUserLocation = NO;
//    // 设置定位的状态（普通定位模式）
//    self.mapView.userTrackingMode = BMKUserTrackingModeNone;
//    // 打开定位图层
//    self.mapView.showsUserLocation = YES;
    
    // 清除上次路线以及状态提示
    [self clean];
    
    self.sumTime = 0;
    self.sumDistance = 0;
    
    // 开始定位服务
    [self.service startUserLocationService];
    
//    self.mapView.showsUserLocation = YES;
//    self.mapView.userTrackingMode = BMKUserTrackingModeNone;
    
    // 设置当前地图最合适的显示范围，直接显示到用户位置
    BMKCoordinateRegion adjustRegion = [self.mapView regionThatFits:BMKCoordinateRegionMake(self.service.userLocation.location.coordinate, BMKCoordinateSpanMake(0.02f,0.02f))];
    // 定位到指定经纬度
    [self.mapView setRegion:adjustRegion animated:YES];
    
    // 7.设置轨迹记录状态为：开始
    self.trail = TrailStart;
}

// 结束定位
- (IBAction)stopLocation:(id)sender {
    
    // 设置轨迹记录状态为：结束
    self.trail = TrailEnd;
    
    // 停止定位服务
    [self.service stopUserLocationService];
    // 关闭定位图层
//    self.mapView.showsUserLocation = NO;
    
    // 添加终点旗帜
    if (self.startPoint) {
        self.endPoint = [self creatPointWithLocaiton:self.preLocation title:@"终点"];
    }
}


#pragma mark BMKLocationServiceDelegate
/**
 *  在将要启动定位时，会调用此函数
 */
- (void)willStartLocatingUser {
    NSLog(@"开始定位");
}

/**
 *  在停止定位后，会调用此函数
 */
- (void)didStopLocatingUser {
    NSLog(@"停止定位");
}

/**
 *  用户方向更新后，会调用此函数
 *  userLocation 新的用户位置（百度坐标）
 */
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation {
    
//    [self.mapView updateLocationData:userLocation];
//    NSLog(@"方向为————%@", userLocation.heading);
    
    // 动态更新位置数据
    [self.mapView updateLocationData:userLocation];
}

/**
 *  用户位置更新后，会调用此函数
 *  userLocation 新的用户位置（百度坐标）
 */
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation {
   
    // 动态更新位置数据
    [self.mapView updateLocationData:userLocation];
//    NSLog(@"经度————%f,纬度————%f", userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
   
    // 如果精度更新的水平精准度大于10M，那么直接返回该方法
    if (userLocation.location.horizontalAccuracy > kCLLocationAccuracyHundredMeters)
        return;
    
    // GPS精度定位准确无误，那么就来开始记录轨迹吧
    [self startTrailRouteWithUserLocation:userLocation];

}

/**
 *  开始记录有效轨迹
 */
- (void)startTrailRouteWithUserLocation:(BMKUserLocation *)userLocation {
    // 如果该点不是第一个点，则可以进行下面的比较运算
    if (self.preLocation) {
        // 计算本次定位数据与上次定位数据之间的时间差
        NSTimeInterval dtime = [userLocation.location.timestamp timeIntervalSinceDate:self.preLocation.timestamp];
        
        // 累计步行时间
        self.sumTime += dtime;
//        self.statusView.sumTime.text = [NSString stringWithFormat:@"%.3f",self.sumTime];
        
        // 计算本次定位点与上次定位点之间的距离
        CGFloat distance = [userLocation.location distanceFromLocation:self.preLocation];
        // (5米距离的限值，存储到数组之中) 如果距离少于2米，则忽略本次数据直接返回该方法
        if (distance < 10) {
            NSLog(@"与前一记录点距离小于2m，直接返回该方法");
            return;
        }
        
        // 计算本地定位点与上次定位点的方向
        if (userLocation.location.coordinate.latitude > self.preLocation.coordinate.latitude && userLocation.location.coordinate.longitude > self.preLocation.coordinate.longitude) {
            self.stateView.directionLabel.text = @"东北方向行进中";
        }
        
        if (userLocation.location.coordinate.latitude > self.preLocation.coordinate.latitude && userLocation.location.coordinate.longitude < self.preLocation.coordinate.longitude) {
            self.stateView.directionLabel.text = @"西北方向行进中";
        }
        
        if (userLocation.location.coordinate.latitude < self.preLocation.coordinate.latitude && userLocation.location.coordinate.longitude > self.preLocation.coordinate.longitude) {
            self.stateView.directionLabel.text = @"东南方向行进中";
        }
        
        if (userLocation.location.coordinate.latitude < self.preLocation.coordinate.latitude && userLocation.location.coordinate.longitude < self.preLocation.coordinate.longitude) {
            self.stateView.directionLabel.text = @"西南方向行进中";
        }
        
        
        // 累加步行距离
        self.sumDistance += distance;
        self.stateView.distanceLabel.text = [NSString stringWithFormat:@"%.3f",self.sumDistance / 1000.0];
        NSLog(@"步行总距离为:%f",self.sumDistance);
        
        // 计算移动速度
        CGFloat speed = distance / dtime;
        self.stateView.speedLabel.text = [NSString stringWithFormat:@"%.3f",speed];
        NSLog(@"步行的当前移动速度为:%.3f", speed);
        
        // 计算平均速度
//        CGFloat avgSpeed  = self.sumDistance / self.sumTime;
//        self.statusView.avgSpeed.text = [NSString stringWithFormat:@"%.3f",avgSpeed];
    }
    
    // 2. 将符合的位置点存储到数组中
    [self.locationArrayM addObject:userLocation.location];
    self.preLocation = userLocation.location;
    
    // 3. 绘图
    [self drawWalkPolyline];
}

/**
 *  绘制轨迹路线
 */
- (void)drawWalkPolyline
{
    // 我们保存的符合轨迹点的个数
    NSUInteger count = self.locationArrayM.count;
    
    // 手动分配存储空间，结构体：地理坐标点，用直角地理坐标表示 X：横坐标 Y：纵坐标
    BMKMapPoint *tempPoints = new BMKMapPoint[count];
    
    [self.locationArrayM enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
        BMKMapPoint locationPoint = BMKMapPointForCoordinate(location.coordinate);
        tempPoints[idx] = locationPoint;
//        NSLog(@"idx = %ld,tempPoints X = %f Y = %f",idx,tempPoints[idx].x,tempPoints[idx].y);
        
        // 放置起点旗帜
        if (0 == idx && TrailStart == self.trail && self.startPoint == nil) {
            self.startPoint = [self creatPointWithLocaiton:location title:@"起点"];
        }
        
//            else { // 如果不是起点旗帜，那么肯定是中间的经过点得旗帜
            [self creatPointWithLocaiton:location title:@"过程点"];
//        }
    }];
    
    //移除原有的绘图
    if (self.polyLine) {
        [self.mapView removeOverlay:self.polyLine];
    }
    
    // 通过points构建BMKPolyline
    self.polyLine = [BMKPolyline polylineWithPoints:tempPoints count:count];
    
    //添加路线,绘图
    if (self.polyLine) {
        [self.mapView addOverlay:self.polyLine];
    }
    
    // 清空 tempPoints 内存
    delete []tempPoints;
    
    [self mapViewFitPolyLine:self.polyLine];
    
    
}

/**
 *  添加一个大头针
 */
- (BMKPointAnnotation *)creatPointWithLocaiton:(CLLocation *)location title:(NSString *)title;
{
    BMKPointAnnotation *point = [[BMKPointAnnotation alloc] init];
    point.coordinate = location.coordinate;
    point.title = title;
    [self.mapView addAnnotation:point];
    
    return point;
}

/**
 *  根据polyline(轨迹线)设置地图范围
 */
- (void)mapViewFitPolyLine:(BMKPolyline *) polyLine {
    CGFloat ltX, ltY, rbX, rbY;
    if (polyLine.pointCount < 1) {
        return;
    }
    BMKMapPoint pt = polyLine.points[0];
    ltX = pt.x, ltY = pt.y;
    rbX = pt.x, rbY = pt.y;
    for (int i = 1; i < polyLine.pointCount; i++) {
        BMKMapPoint pt = polyLine.points[i];
        if (pt.x < ltX) {
            ltX = pt.x;
        }
        if (pt.x > rbX) {
            rbX = pt.x;
        }
        if (pt.y > ltY) {
            ltY = pt.y;
        }
        if (pt.y < rbY) {
            rbY = pt.y;
        }
    }
    BMKMapRect rect;
    rect.origin = BMKMapPointMake(ltX , ltY);
    rect.size = BMKMapSizeMake(rbX - ltX, rbY - ltY);
    [self.mapView setVisibleMapRect:rect];
    self.mapView.zoomLevel = self.mapView.zoomLevel - 0.3;
}

/**
 *  清空数组以及地图上的轨迹
 */
- (void)clean
{
    // 清空状态栏信息
    self.stateView.distanceLabel.text = nil;
    self.stateView.speedLabel.text = nil;
    self.stateView.directionLabel.text = nil;

    //清空数组
    [self.locationArrayM removeAllObjects];
    
    //清屏，移除标注点
    if (self.startPoint) {
        [self.mapView removeAnnotation:self.startPoint];
        self.startPoint = nil;
    }
    if (self.endPoint) {
        [self.mapView removeAnnotation:self.endPoint];
        self.endPoint = nil;
    }
    if (self.polyLine) {
        [self.mapView removeOverlay:self.polyLine];
        self.polyLine = nil;
    }
    
    
}

#pragma mark - BMKMapViewDelegate

/**
 *  根据overlay生成对应的View
 *  @param mapView 地图View
 *  @param overlay 指定的overlay
 *  @return 生成的覆盖物View
 */
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.fillColor = [[UIColor clearColor] colorWithAlphaComponent:0.7];
        polylineView.strokeColor = [[UIColor greenColor] colorWithAlphaComponent:0.7];
        polylineView.lineWidth = 10.0;
        return polylineView;
    }
    return nil;
}

/**
 *  只有在添加大头针的时候会调用，直接在viewDidload中不会调用
 *  根据anntation生成对应的View
 *  @param mapView 地图View
 *  @param annotation 指定的标注
 *  @return 生成的标注View
 */
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        BMKPinAnnotationView *annotationView = [[BMKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"myAnnotation"];
        
        
        if (!self.startPoint) { // 没有起点，自然要放置起点大头针（绿色）
            annotationView.pinColor = BMKPinAnnotationColorGreen; // 替换资源包内的图片
//            self.statusView.stopPointLabel.text = @"YES";
        } else if (self.trail == TrailEnd) { // 点击了结束定位，自然要放置终点大头针（红色）
            annotationView.pinColor = BMKPinAnnotationColorRed;
//            self.statusView.startPointLabel.text = @"YES";
        } else { // 过程大头针（紫色）
            annotationView.pinColor = BMKPinAnnotationColorPurple;
        }
        
        // 从天上掉下效果
        annotationView.animatesDrop = YES;
        
        // 不可拖拽
        annotationView.draggable = NO;
        
        return annotationView;
    }
    return nil;
}


@end
