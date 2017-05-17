//
//  CFNetworkViewController.m
//  IOSNetWorkDemo
//
//  Created by 孙伟伟 on 16/8/15.
//  Copyright © 2016年 孙伟伟. All rights reserved.
//

#import "CFNetworkViewController.h"
#import <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#import "AppDelegate.h"

#define bufferSize 1024

@interface CFNetworkViewController ()

//网络数据
@property (nonatomic, strong) NSMutableData *recievedData;

@property(nonatomic,strong)UILabel *hintLabel;

@property(nonatomic)CFReadStreamRef *readStream;

@property(nonatomic)CFWriteStreamRef *writeStream;

@end

@implementation CFNetworkViewController

#pragma mark -- life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"CFNetwork demo";
    
    [self initContent];
    
    if (_recievedData == nil)
    {
        _recievedData = [[NSMutableData alloc] init];
    }
    
    [self requestURLData:@"www.tf56.com" portNo:@"80"];
}

- (void)initContent
{
    UIButton *_requestURLBtn = [[UIButton alloc]initWithFrame:CGRectMake(15, 80, kDEVICEWIDTH - 30, 45)];
    _requestURLBtn.backgroundColor = [UIColor grayColor];
    [_requestURLBtn addTarget:self action:@selector(connectClick:) forControlEvents:UIControlEventTouchUpInside];
    _requestURLBtn.tag = 999;
    [_requestURLBtn setTitle:@"发送数据" forState:UIControlStateNormal];//连接服务器
    _requestURLBtn.titleLabel.textColor = [UIColor whiteColor];
    _requestURLBtn.layer.cornerRadius = 4;
    [self.view addSubview:_requestURLBtn];
    
    if (!self.hintLabel)
    {
        self.hintLabel = [[UILabel alloc]init];
        self.hintLabel.font = [UIFont systemFontOfSize:18.0];
        self.hintLabel.numberOfLines = 0;
        [self.hintLabel setFrame:CGRectMake(15, 200, kDEVICEWIDTH - 30, 18)];
        self.hintLabel.textAlignment = NSTextAlignmentCenter;
        [self.hintLabel setTextColor:[UIColor blackColor]];
        [self.view addSubview:self.hintLabel];
    }
}

- (void)connectClick:(id)sender
{
    [self.hintLabel setText:@"正在连接服务器....."];
    //[self requestURLData:@"telnet://towel.blinkenlights.nl" portNo:@"23"];
    //[self requestURLData:@"www.tf56.com" portNo:@"80"]; //www.baidu.com  80
    
    [self sendData];
}

#pragma mark -- 数据请求

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

//发送数据
- (void)sendData
{
    NSString *_httpRequestStr = @"GET / HTTP/1.1\r\nHost:www.tf56.com\r\nConnection: close\r\n\r\n";
    char *sendChar = (char *)[_httpRequestStr UTF8String];
    
    //UInt8 *buf[] = @"Hello, world";
    
    unsigned long bufLen = strlen(sendChar);


    CFStreamEventType streamStatus = CFWriteStreamGetStatus(*(_writeStream));
    
    if(streamStatus == kCFStreamEventHasBytesAvailable && bufLen > 0)
    {
        
        NSInteger sendSuccessCount = CFWriteStreamWrite(*(_writeStream), sendChar, bufLen);
        NSLog(@"------%ld",sendSuccessCount);
        
        [self.hintLabel setText:@"数据发送成功"];
        NSLog(@"send发送数据成功======》\n");
    }
    else
    {
       // [_writeStream setData:nil];
        [self.hintLabel setText:@"数据发送失败"];
        NSLog(@"send发送数据失败======》\n");
    }

}


- (void)connectServerWithURL:(NSURL *)url
{
    NSString * host = [url host];
    NSInteger  port = [[url port] integerValue];
    
    // Keep a reference to self to use for controller callbacks
    CFStreamClientContext ctx = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    // Get callbacks for stream data, stream end, and any errors
    CFOptionFlags registeredEvents = (kCFStreamEventHasBytesAvailable | kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred);
    
    // Create a read-only socket
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)host, port, &readStream, &writeStream);
    
    // Schedule the stream on the run loop to enable callbacks
    if (CFReadStreamSetClient(readStream, registeredEvents, socketCallback, &ctx))
    {
        CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
    else
    {
        NSLog(@"Failed to assign callback method");
        return;
    }
    
    if (CFWriteStreamSetClient(writeStream, registeredEvents, socketWriteCallback, &ctx))
    {
        CFWriteStreamScheduleWithRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
    else
    {
        NSLog(@"Failed to assign callback method");
        return;
    }
    
    _readStream = &readStream;
    _writeStream = &writeStream;
    
//    Boolean CFWriteStreamSetClient(CFWriteStreamRef stream, CFOptionFlags streamEvents, CFWriteStreamClientCallBack clientCB, CFStreamClientContext *clientContext);
    
    // Open the stream for reading
    if (CFReadStreamOpen(readStream) == NO)
    {
         NSLog(@"Failed to open read stream");
        return;
    }
    
    if (CFWriteStreamOpen(writeStream) == NO)
    {
        NSLog(@"Failed to open write stream");
        return;
    }
    
    CFErrorRef error = CFReadStreamCopyError(readStream);
    if (error != NULL)
    {
        if (CFErrorGetCode(error) != 0)
        {
            NSString * errorInfo = [NSString stringWithFormat:@"Failed to connect stream; error '%@' (code %ld)", (__bridge NSString*)CFErrorGetDomain(error), CFErrorGetCode(error)];
            
            NSLog(@"Failed to connect stream%@",errorInfo);
        }
        
        CFRelease(error);
        
        return;
    }

    NSLog(@"Successfully connected to %@", url);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.hintLabel setText:@"服务器连接成功!"];
    });
    
    CFRunLoopRun();
}


#pragma mark -
#pragma mark CFNetwork

- (void)didReceiveData:(NSData *)data
{
    [_recievedData appendData:data];
}

- (void)didFinishReceivingData
{
    NSString * resultsString = [[NSString alloc] initWithData:_recievedData encoding:NSUTF8StringEncoding];
    
    NSLog(@"socketCallback receive data %@",resultsString);
}

void socketWriteCallback(CFWriteStreamRef stream, CFStreamEventType event, void * myPtr)
{
    switch(event)
    {
        case kCFStreamEventHasBytesAvailable:
        {
            
            break;
        }
            
        case kCFStreamEventErrorOccurred:
        {
            
            
            break;
        }
            
        case kCFStreamEventEndEncountered:
            // Finnish receiveing data
            //[controller didFinishReceivingData];
            
            // Clean up
            //            CFReadStreamClose(stream);
            //            CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
            //            CFRunLoopStop(CFRunLoopGetCurrent());
            
            break;
            
        default:
            break;
    }
   
}

void socketCallback(CFReadStreamRef stream, CFStreamEventType event, void * myPtr)
{
    //NSLog(@" >> socketCallback in Thread %@", [NSThread currentThread]);
    
    CFNetworkViewController * controller = (__bridge CFNetworkViewController *)myPtr;
    
    switch(event)
    {
        case kCFStreamEventHasBytesAvailable:
        {
            NSMutableData *newdata = [[NSMutableData alloc]init];
            // Read bytes until there are no more
            while (CFReadStreamHasBytesAvailable(stream))
            {
                UInt8 buffer[bufferSize];
                long numBytesRead = CFReadStreamRead(stream, buffer, bufferSize);
                
                [newdata appendBytes:buffer length:numBytesRead];
                
                [controller didReceiveData:newdata];
                
                NSString * resultsString = [[NSString alloc] initWithData:newdata encoding:NSUTF8StringEncoding];
                
                NSLog(@"socketCallback receive data %@",resultsString);
            }
            
            break;
        }
            
        case kCFStreamEventErrorOccurred:
        {
            CFErrorRef error = CFReadStreamCopyError(stream);
            if (error != NULL)
            {
                if (CFErrorGetCode(error) != 0)
                {
                    NSString * errorInfo = [NSString stringWithFormat:@"Failed while reading stream; error '%@' (code %ld)", (__bridge NSString*)CFErrorGetDomain(error), CFErrorGetCode(error)];
                    
                    NSLog(@"Failed to connect stream%@",errorInfo);
                }
                
                CFRelease(error);
            }
            
            
            break;
        }
            
        case kCFStreamEventEndEncountered:
            // Finnish receiveing data
            [controller didFinishReceivingData];
            
            // Clean up
//            CFReadStreamClose(stream);
//            CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
//            CFRunLoopStop(CFRunLoopGetCurrent());
            
            break;
            
        default:
            break;
    }
}

@end
