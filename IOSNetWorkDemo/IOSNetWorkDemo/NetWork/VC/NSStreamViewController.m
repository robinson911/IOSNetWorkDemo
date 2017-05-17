//
//  NSStreamViewController.m
//  IOSNetWorkDemo
//
//  Created by 孙伟伟 on 16/7/31.
//  Copyright © 2016年 孙伟伟. All rights reserved.
//

#import "NSStreamViewController.h"
#import "AppDelegate.h"
#import <arpa/inet.h>
#import <netdb.h>
#import <CFNetwork/CFNetwork.h>
#import <SystemConfiguration/SCNetworkReachability.h>
#import "NSStream+StreamsToHost.h"

#define kBufferSize 1024
#define kHost @"www.tf56.com"
#define kPort @"80"

@interface NSStreamViewController ()<NSStreamDelegate>

// 需要发送的数据缓存
@property(nonatomic,strong)NSMutableData *sendData;

 // 接收数据流
@property(nonatomic,strong)NSInputStream *inputStream;

// 发送数据流
@property(nonatomic,strong)NSOutputStream *outputStream;

//网络数据
@property (nonatomic, strong) NSMutableData *receivedData;

//显示的网络图片
@property (nonatomic, strong) UIImageView *imageView;

//显示的网络图片
@property (nonatomic, assign) long totoalContentSize;

//状态提示
@property (nonatomic, strong) UILabel *hintLabel;

@end

@implementation NSStreamViewController

#pragma mark -- life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"NSStream DEMO";
    
    [self initStream];
    
    [self initContent];
}

#pragma mark -- init

- (void)initContent
{
    UIButton *_requestURLBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, 80, kDEVICEWIDTH - 30, 45)];
    _requestURLBtn.backgroundColor = [UIColor grayColor];
    [_requestURLBtn addTarget:self action:@selector(netClick:) forControlEvents:UIControlEventTouchUpInside];
    _requestURLBtn.tag = 999;
    [_requestURLBtn setTitle:@"网络连接" forState:UIControlStateNormal];
    _requestURLBtn.titleLabel.textColor = [UIColor whiteColor];
    _requestURLBtn.layer.cornerRadius = 4;
    [self.view addSubview:_requestURLBtn];
    
    UIButton *_closeBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, 160, kDEVICEWIDTH - 30, 45)];
    _closeBtn.backgroundColor = [UIColor grayColor];
    [_closeBtn addTarget:self action:@selector(netClick:) forControlEvents:UIControlEventTouchUpInside];
    _closeBtn.tag = 1000;
    [_closeBtn setTitle:@"关闭连接" forState:UIControlStateNormal];
    _closeBtn.titleLabel.textColor = [UIColor whiteColor];
    _closeBtn.layer.cornerRadius = 4;
    [self.view addSubview:_closeBtn];
    
    UIButton *_sendBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, 240, kDEVICEWIDTH - 30, 45)];
    _sendBtn.backgroundColor = [UIColor grayColor];
    [_sendBtn addTarget:self action:@selector(netClick:) forControlEvents:UIControlEventTouchUpInside];
    _sendBtn.tag = 1001;
    [_sendBtn setTitle:@"发送数据" forState:UIControlStateNormal];
    _sendBtn.titleLabel.textColor = [UIColor whiteColor];
    _sendBtn.layer.cornerRadius = 4;
    [self.view addSubview:_sendBtn];
    
    if (!self.hintLabel)
    {
        self.hintLabel = [[UILabel alloc]init];
        self.hintLabel.font = [UIFont systemFontOfSize:18.0];
        self.hintLabel.numberOfLines = 0;
        [self.hintLabel setFrame:CGRectMake(15, 400, kDEVICEWIDTH - 30, 60)];
        self.hintLabel.textAlignment = NSTextAlignmentCenter;
        [self.hintLabel setTextColor:[UIColor blackColor]];
        [self.view addSubview:self.hintLabel];
    }

    
    if (!_imageView)
    {
        _imageView = [[UIImageView alloc]init];
        [_imageView setFrame:CGRectMake((kDEVICEWIDTH - 300)/2.0, 320, 300, 300)];
        [self.view addSubview:_imageView];
    }
}

//显示图片
- (void)showNetWorkImage:(NSData*)reData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIImage *_showImage = [[UIImage alloc]initWithData:reData];
        [_imageView setImage:_showImage];
        
    });
}

#pragma mark -- clicked function

- (void)netClick:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    NSInteger tag = btn.tag;
    
    if (tag == 999)
    {
        [self  connectToServerUsingStream:kHost portNo:kPort];  //10.3.12.199  7845
    }
    
    else if (tag == 1000)
    {
        [self closeConnection];
    }
    
    else if (tag == 1001)
    {
//        NSString *_sendStr1 = @"GET /?tn=sitehao123 HTTP/1.1\r\nConnection: close\r\n";
//        NSString *_sendStr2 = @"\r\n";
//        NSString *_sendSting = [NSString stringWithFormat:@"%@%@%@",_sendStr0,_sendStr1,_sendStr2];
       
          //HTTP请求头与请求定位地址拼接
          NSString *_httpRequestStr = @"GET /index.html HTTP/1.1\r\nHost:kHost\r\nConnection: close\r\n\r\n";
          char *sendChar = (char *)[_httpRequestStr UTF8String];
          [self send:sendChar length:_httpRequestStr.length];
    }
}


- (void)requestURLData:(NSString *)serverHost
                portNo: (NSString *)serverPort
{
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@", serverHost, serverPort]];
    //[self connectServerWithURL:url];
    NSThread * backgroundThread = [[NSThread alloc] initWithTarget:self
                                                          selector:@selector(connectServerWithURL:)
                                                            object:url];
    [backgroundThread start];
}

#pragma mark -- NSStream

//初始化数据流
- (void)initStream
{
    _inputStream = nil;
    
    _outputStream = nil;
    
    if (_sendData == nil)
    {
        _sendData = [[NSMutableData alloc] init];
    }
    
    if (_receivedData == nil)
    {
        _receivedData = [[NSMutableData alloc] init];
    }
}

//连接服务器
- (BOOL)connectToServerUsingStream:(NSString *)serverHost
                            portNo: (NSString *)serverPort
{
    if (serverHost == nil || [serverHost isEqualToString:@""])
    {
        [self.hintLabel setText:@"服务器地址不能为空!"];
        return NO;
    }
    
    if (serverPort == nil || [serverPort isEqualToString:@""])
    {
        [self.hintLabel setText:@"服务器端口不能为空!"];
        return NO;
    }

    
    if (_inputStream || _outputStream)
    {
        [self closeConnection];
    }

    NSInputStream * readStream;
    NSOutputStream * writeStream;
    
    [NSStream getStreamsToHostNamed:serverHost
                               port:[serverPort integerValue]
                        inputStream:&readStream
                       outputStream:&writeStream];
    
    _inputStream = readStream;
    _outputStream = writeStream;
    
    if (!_inputStream || !_outputStream)
    {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"提示"
                                                       message:@"open连接失败，原因：inputStream、outputStream初始化失败"
                                                      delegate:nil
                                             cancelButtonTitle:@"确定"
                                             otherButtonTitles:nil] ;
            
        [alert show];

        return NO;
    }

    [_inputStream setDelegate:self];
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_outputStream setDelegate:self];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_inputStream open];
    [_outputStream open];
    
    [self.hintLabel setText:@"网络已连接"];
    
    return YES;
}

//发送数据
- (void)send:(char*)dataBuf length:(NSInteger)len
{
    NSLog(@"send发送数据长度=====%ld\n", (long)len);
    
    [_sendData appendBytes:(void*)dataBuf length:len];
    
    if([_outputStream hasSpaceAvailable] && [_sendData length] > 0)
    {
        [_outputStream write:[_sendData bytes] maxLength:[_sendData length]];
        [_sendData setData:nil];
        
        [self.hintLabel setText:@"数据发送成功"];
        NSLog(@"send发送数据成功======》\n");
    }
    else
    {
        [_sendData setData:nil];
        [self.hintLabel setText:@"数据发送失败"];
        NSLog(@"send发送数据失败======》\n");
    }
}

//关闭连接
- (void)closeConnection
{
    if (_inputStream)
    {
        [_inputStream setDelegate:nil];
        [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_sendData setData:nil];
        [_inputStream close];
    }
    _inputStream = nil;
    
    if (_outputStream)
    {
        [_outputStream setDelegate:nil];
        [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_outputStream close];
    }
    _outputStream = nil;
    
    [self.hintLabel setText:@"连接已断开"];
}

#pragma mark -- NSStreamDelegate

- (void)stream:(NSStream *)eventStream handleEvent:(NSStreamEvent)streamEvent
{
    if (eventStream == _outputStream)
    {
        //_writeEvnet = streamEvent;
        
        switch(streamEvent) {
            case NSStreamEventOpenCompleted:
            {
                NSLog(@"TCP - O/OpenCompleted");
               
                break;
            }
            case NSStreamEventHasSpaceAvailable:
            {
                NSLog(@"TCP - O/HasSpace");
                
                if(_sendData != nil && [_sendData length] > 0)
                {
                    NSLog(@"TCP - stream write");
                    [_outputStream write:[_sendData bytes] maxLength:[_sendData length]];
                    [_sendData setData:nil];
                }
                break;
            }
            case NSStreamEventErrorOccurred:
            {
                NSLog(@"TCP - O/Error");
                
            }
                break;
            case NSStreamEventEndEncountered:
            {
                NSLog(@"TCP - O/End");
            }
                break;
            default:
                break;
        }
        
    }
    else if (eventStream == _inputStream)
    {
        //_readEvent = streamEvent;
        
        switch(streamEvent) {
            case NSStreamEventOpenCompleted:
            {
                NSLog(@"TCP - I/OpenCompleted");
                
                //[self inputStreamCompleted];
            }
                break;
            case NSStreamEventHasBytesAvailable:
            {
                Byte dataBuff[kBufferSize] = {0};
                
                NSMutableData *newData = [[NSMutableData alloc]init];
                while ([_inputStream hasBytesAvailable])
                {
                    NSInteger readLength = [_inputStream read:(void*)&dataBuff maxLength:kBufferSize];
                    
                    if (readLength > 0)
                    {
                        [newData appendBytes:dataBuff length:kBufferSize];
                        
                        NSString * resultsString = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
                        NSLog(@"receive data %@",resultsString);
                    }
                    else
                    {
                       NSLog(@"TCP - I/read error");
                        
                        break;
                    }
                }
                [self.receivedData appendData:newData];
//                NSLog(@"receive self.receivedData Length %lu",(unsigned long)[self.receivedData length]);
//                NSString * resultsString = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
//                NSLog(@"receive data %@",resultsString);
            }
                break;
                
            case NSStreamEventErrorOccurred:
            {
                NSLog(@"TCP - I/Error");
                NSError * error = [_inputStream streamError];
                if (error)
                {
                    NSLog(@"====>%@ %ld\n", [error localizedDescription],(long)[error code]);
                }
                
                [self closeConnection];
            }
                break;
            case NSStreamEventEndEncountered:
            {
                NSLog(@"TCP - I/End");
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    
                    NSString * resultsString = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
                    
                    //NSArray *_tfArray = [resultsString componentsSeparatedByString:@"\r\n\r\n"];
                    
                    NSLog(@"receive data %@",resultsString);
                   // [self showNetWorkImage:_imageData];
                }];
            
                //[self closeConnection];
            }
                break;
            default:
                break;
        }
    }
}

@end
