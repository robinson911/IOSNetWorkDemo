//
//  NSURLViewController.m
//  IOSNetWorkDemo
//
//  Created by 孙伟伟 on 16/7/30.
//  Copyright © 2016年 孙伟伟. All rights reserved.
//

#import "NSURLViewController.h"
#import "AppDelegate.h"

@interface NSURLViewController ()<NSURLConnectionDataDelegate,NSURLConnectionDelegate>

//网络数据
@property (nonatomic, strong) NSMutableData *recieveData;

//显示的网络图片
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation NSURLViewController

#pragma mark -- life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"NSURL Test Demo";
    
    [self initContent];
}

#pragma mark -- init

- (void)initContent
{
    if (!self.recieveData)
    {
        self.recieveData = [[NSMutableData alloc]init];
    }
    
    UIButton *_requestBlockBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, 90, kDEVICEWIDTH - 30, 45)];
    _requestBlockBtn.backgroundColor = [UIColor grayColor];
    [_requestBlockBtn addTarget:self action:@selector(netClick:) forControlEvents:UIControlEventTouchUpInside];
    [_requestBlockBtn setTitle:@"异步Block网络请求图片" forState:UIControlStateNormal];
    //[_requestBlockBtn addTarget:self action:@selector(sendSynRequestForImage:) forControlEvents:UIControlEventTouchUpInside];
    //[_requestBlockBtn setTitle:@"同步网络请求" forState:UIControlStateNormal];
    _requestBlockBtn.tag = 999;
    _requestBlockBtn.titleLabel.textColor = [UIColor whiteColor];
    _requestBlockBtn.layer.cornerRadius = 4;
    [self.view addSubview:_requestBlockBtn];
    
    UIButton *_requestDelegateBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, 180, kDEVICEWIDTH - 30, 45)];
    _requestDelegateBtn.backgroundColor = [UIColor grayColor];
    [_requestDelegateBtn addTarget:self action:@selector(netClick:) forControlEvents:UIControlEventTouchUpInside];
    _requestDelegateBtn.tag =1000;
    [_requestDelegateBtn setTitle:@"异步Delegate网络请求图片" forState:UIControlStateNormal];
    _requestDelegateBtn.titleLabel.textColor = [UIColor whiteColor];
    _requestDelegateBtn.layer.cornerRadius = 4;
    [self.view addSubview:_requestDelegateBtn];
    
    
    if (!_imageView)
    {
        _imageView = [[UIImageView alloc]init];
        [_imageView setFrame:CGRectMake((kDEVICEWIDTH - 300)/2.0, 250, 300, 300)];
        [self.view addSubview:_imageView];
    }
}

//显示图片
- (void)showNetWorkImage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIImage *_showImage = [[UIImage alloc]initWithData:self.recieveData];
//        [_imageView setFrame:CGRectMake((kDEVICEWIDTH - 300)/2.0, 280, _showImage.size.width, _showImage.size.hight)];
        [_imageView setImage:_showImage];
        
    });
}

#pragma mark -- clicked function

- (void)netClick:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    NSInteger tag = btn.tag;
    
    [self clearCache];
    
    if (tag == 999)
    {
       [self sendAsynRequestByBlockForImage];
    }
    
    else if (tag == 1000)
    {
        [self sendAsynRequestByDelegateForImage];
    }
}

//清除缓存
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

#pragma mark -- 同步请求数据

- (void)sendSynRequestForImage:(id)sender
{
    //    1.设置请求路径
    NSURL *url = [NSURL URLWithString:requestPNGUrl];
    
    //    2.创建请求对象
    NSURLRequest *request=[NSURLRequest requestWithURL:url];
    
    //    3.发送请求
    //发送同步请求，在主线程执行,很容易卡死UI界面
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];

    NSLog(@"--%lu--",(unsigned long)data.length);
    
    [self.recieveData appendData:data];
    
    [self showNetWorkImage];
}

#pragma mark -- 异步请求数据

//异步连接（delegate）
- (void)sendAsynRequestByDelegateForImage
{
    //    1.设置请求路径
    NSURL *url = [NSURL URLWithString:requestPNGUrl];
    
    //    2.创建请求对象
    NSMutableURLRequest *mutablerequest = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    mutablerequest.HTTPMethod = @"GET";//请求方式，默认GET
    
    //    3.发送请求
    [NSURLConnection connectionWithRequest:mutablerequest delegate:self];
}

//异步连接（block）
- (void)sendAsynRequestByBlockForImage
{
    //    1.设置请求路径
    NSURL *url = [NSURL URLWithString:requestUrl];
    
    //    2.创建请求对象
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
   
    //    3.发送请求
    //如果数据接收完毕，data为接收到的数据。如果出错，那么错误信息保存在error中。
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue ] completionHandler: ^(NSURLResponse *response, NSData *data, NSError * connectionError)
     {
         if (response)
         {
              NSLog(@"已经接收到的响应%@",response);
         }
         
         if (data.length > 0)
         {
             [self.recieveData appendData:data];
             
             NSString * resultsString = [[NSString alloc] initWithData:self.recieveData encoding:NSUTF8StringEncoding];
             NSLog(@"receive data %@",resultsString);
             
             [self showNetWorkImage];
         }
         
         NSLog(@"已经接收到的数据长度%lu字节",(unsigned long)self.recieveData.length);
         
         if (connectionError)
         {
             NSLog(@"错误原因%@",connectionError);
         }
     }
    ];
}


//异步连接（代理）
//设置NSURLConnection代理
//实现相应的代理方法：开始响应接受数据、接收数据 、成功、失败

#pragma mark -- NSURLConnectionDataDelegate

//收到服务器回应的时候此方法会被调用
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"已经接收到的响应%@",response);
}

//每次接收到服务器传输数据的时候调用,此方法根据数据大小会被调用多次
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //NSLog(@"已经接收到的数据%s",__FUNCTION__);
    
    [self.recieveData appendData:data];
}

//数据传输完成以后调用此方法,此方法中得到最终的数据recieveData
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"数据接收完毕%s",__FUNCTION__);
    
    NSLog(@"已经接收到的数据长度%lu字节",(unsigned long)self.recieveData.length);
    
    [self showNetWorkImage];
}

#pragma mark -- NSURLConnectionDelegate

//网络请求中，出现任何错误(断网，链接超时等)会进入此方法
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"数据接收失败，产生错误%s",__FUNCTION__);
    
    NSLog(@"数据接收失败，产生错误%@",error);
}

@end
