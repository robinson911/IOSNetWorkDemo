//
//  AppDelegate.h
//  IOSNetWorkDemo
//
//  Created by 孙伟伟 on 16/7/29.
//  Copyright © 2016年 孙伟伟. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIView+RGSize.h"

static  NSString *requestUrl = @"http://img1.126.net/channel6/2015/ad/2_1224a.jpg";

static  NSString *requestPNGUrl = @"http://file.test.tf56.com:5683/web/trade/51aa2529-705d-4708-9de3-04b5e09c3e76.png";

static  NSString *requestJsonUrl = @"http://site.test.tf56.com/tradeView/tradecs/get?cmd=banner.getBannersByType&datasource=ios&callback=json&token=c9551943392c70b9eff54077cc4e30ff_565612984&count=5&type=owner&sourcecode=0103010201&sourcecode=0103010201";

static  NSString *requestAppStoreInfoJsonUrl = @"http://itunes.apple.com/lookup?id=1003790292";

#define kTestHost @"telnet://towel.blinkenlights.nl"
#define kTestPort @"23"


#define kDEVICEWIDTH  [UIScreen mainScreen].bounds.size.width
#define kDEVICEHEIGHT  [UIScreen mainScreen].bounds.size.height

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

