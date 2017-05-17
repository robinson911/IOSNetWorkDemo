//
//  NSURLSessionViewController.m
//  IOSNetWorkDemo
//
//  Created by 孙伟伟 on 16/7/29.
//  Copyright © 2016年 孙伟伟. All rights reserved.
//

#import "NSURLSessionViewController.h"
#import "AppDelegate.h"
#import "TFNetWorkManager.h"
#import "Reachability.h"
#import <ImageIO/ImageIO.h>


@interface NSURLSessionViewController ()

//上一次网络状态
@property (nonatomic, assign) NetworkStatus preNetworkStatus;

@property (nonatomic, strong) UIImageView  *imageView;

//图片增量源
@property (nonatomic) CGImageSourceRef incrementallyImgSource;

@property (nonatomic, assign) CGImageRef imageRef;

//网络数据
@property (nonatomic, strong) NSMutableData *recieveData;

//网络图片加载进度
@property (nonatomic, strong) UILabel *progressLabel;

@end

@implementation NSURLSessionViewController

#pragma mark -- dealloc

- (void)dealloc
{
    if (_incrementallyImgSource)
    {
        _incrementallyImgSource = nil;
    }
    
    if (self.imageRef)
    {
        CFRelease(self.imageRef);
    }

}

#pragma mark -- life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"NSURLSession Test Demo";
    
    [self initContent];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    
    self.recieveData = nil;
}

- (void)initContent
{
    [self initUI];
    
    self.recieveData = [[NSMutableData alloc]init];
    
    _incrementallyImgSource = CGImageSourceCreateIncremental(NULL);
}

#pragma mark -- UI

- (void)initUI
{
    if (!self.imageView)
    {
        self.imageView = [[UIImageView alloc]init];
        [self.imageView setFrame:CGRectMake((kDEVICEWIDTH - 300)/2.0, 320, 300, 300)];
        [self.view addSubview:self.imageView];
    }
    
    if (!self.progressLabel)
    {
        self.progressLabel = [[UILabel alloc]init];
        self.progressLabel.font = [UIFont systemFontOfSize:18.0];
        self.progressLabel.numberOfLines = 0;
        [self.progressLabel setFrame:CGRectMake(15, 400, kDEVICEWIDTH - 30, 60)];
        self.progressLabel.textAlignment = NSTextAlignmentCenter;
        [self.progressLabel setTextColor:[UIColor blackColor]];
        [self.view addSubview:self.progressLabel];
    }
    
    UIButton *_requestBlockBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, 100, kDEVICEWIDTH - 30, 45)];
    _requestBlockBtn.backgroundColor = [UIColor grayColor];
    [_requestBlockBtn addTarget:self action:@selector(netClick:) forControlEvents:UIControlEventTouchUpInside];
    _requestBlockBtn.tag = 999;
    [_requestBlockBtn setTitle:@"delegate网络请求图片" forState:UIControlStateNormal];
    _requestBlockBtn.titleLabel.textColor = [UIColor whiteColor];
    _requestBlockBtn.layer.cornerRadius = 4;
    [self.view addSubview:_requestBlockBtn];
    
    UIButton *_requestDelegateBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, 220, kDEVICEWIDTH - 30, 45)];
    _requestDelegateBtn.backgroundColor = [UIColor grayColor];
    [_requestDelegateBtn addTarget:self action:@selector(netClick:) forControlEvents:UIControlEventTouchUpInside];
    _requestDelegateBtn.tag = 1000;
    [_requestDelegateBtn setTitle:@"delegate网络请求json数据" forState:UIControlStateNormal];
    _requestDelegateBtn.titleLabel.textColor = [UIColor whiteColor];
    _requestDelegateBtn.layer.cornerRadius = 4;
    [self.view addSubview:_requestDelegateBtn];
}

#pragma mark -- clicked function

- (void)netClick:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    NSInteger tag = btn.tag;
    
    [self clearCache];

    if (tag == 999)
    {
       [self loadImageFromNet];
    }
    
    else if (tag == 1000)
    {
       [self loadJSONDataFromNet];
    }
}

//清除缓存数据
- (void)clearCache
{
    if (self.recieveData)
    {
        self.recieveData = nil;
        
        self.recieveData = [[NSMutableData alloc]init];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = nil;
        });
    }
}

#pragma mark -- 图片网络数据请求
- (void)loadImageFromNet
{
    [[TFNetWorkManager sharedInstances] requestNetWork:requestPNGUrl
                                          successBlock:^(NSData *netData, NSString *progressStr, BOOL isFinished)
     {
         [self.recieveData appendData:netData];
         
         //在主线程中刷新界面
         dispatch_async(dispatch_get_main_queue(), ^{
             
             //增量下载网络图片，下载一点图片data，展示一点图片
             CGImageSourceUpdateData(self.incrementallyImgSource, (CFDataRef)self.recieveData, isFinished);
             self.imageRef = CGImageSourceCreateImageAtIndex(self.incrementallyImgSource, 0, NULL);
             self.imageView.image = [UIImage imageWithCGImage:self.imageRef];
             //CGImageRelease(self.imageRef); //ARC does not manage C-types, of which CGImage may be considered. You must release the ref manually when you are finished with CGImageRelease(image);

             [self.progressLabel setText: progressStr];
             
             if ([progressStr isEqualToString:@"100.00%"])
             {
                 [self.progressLabel setText: @""];
             }
         });
     } failure:^(NSError *error)
     {
         NSLog(@"-----failure---%@",error);
     }];
}

#pragma mark -- json网络数据请求
- (void)loadJSONDataFromNet
{
    //requestAppStoreInfoJsonUrl requestJsonUrl
    [[TFNetWorkManager sharedInstances] requestNetWork:requestAppStoreInfoJsonUrl successBlock:^(NSData *netData, NSString *progressStr, BOOL isFinished)
     {
         // 处理每次接收的数据
         [self.recieveData appendData:netData];
         
         if ([progressStr isEqualToString:@"100.00%"])
         {
             //在主线程中刷新界面
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 [self.progressLabel setText: @"json数据下载完毕"];
                 
            });
             
             NSString *jsonStr = [[NSString alloc] initWithData:self.recieveData encoding:NSUTF8StringEncoding];
             
             NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
             
             NSError *errorInfo = nil;
             NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&errorInfo];
             
             NSLog(@"打印收到的json data:%@",resultDict);
         }
     } failure:^(NSError *error)
     {
         NSLog(@"-----failure---%@",error);
     }];
}

@end
