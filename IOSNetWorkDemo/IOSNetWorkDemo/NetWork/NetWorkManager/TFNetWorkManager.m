//
//  TFNetWorkManager.m
//  CommonDemo
//
//  Created by 孙伟伟 on 16/7/8.
//  Copyright © 2016年 孙伟伟. All rights reserved.
//

#import "TFNetWorkManager.h"
#import <ImageIO/ImageIO.h>

@interface TFNetWorkManager ()<NSURLSessionDataDelegate,NSURLSessionDelegate,NSURLSessionTaskDelegate>

/** Session会话 */
@property (nonatomic,strong)NSURLSession *session;

/** SessionDataTask任务 */
@property (nonatomic,strong)NSURLSessionDataTask *dataTask;

/*下载的数据*/
@property (nonatomic, strong) NSMutableData *recieveData;

/*文件总大小*/
@property (nonatomic, assign) NSInteger totalSize;

/*已下载文件大小*/
@property (nonatomic, assign) NSInteger currentSize;

/*文件是否已经下载完毕*/
@property (nonatomic, assign) BOOL isLoadFinished;

@end

@implementation TFNetWorkManager

+ (TFNetWorkManager*)sharedInstances
{
    static dispatch_once_t once;
    static TFNetWorkManager *_netWorkManager;
    dispatch_once(&once,^{
        _netWorkManager = [[TFNetWorkManager alloc]init];
    });
    
    return _netWorkManager;
}

- (instancetype)init
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    
    self.recieveData = [NSMutableData data];
    
    self.isLoadFinished = false;
 
    return self;
}

#pragma mark -- NSURLSessionUploadTask 任务

- (void)sendUploadTaskAsynRequestByBlock
{
    //    1.要上传的本地文件路径
    NSURL *URL = [NSURL URLWithString:@"http://example.com/upload"];
    
    //    1.要上传的数据
    NSData *data = nil;
    
    //    2.创建请求对象
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    //    3.NSURLSession初始化
    NSURLSession *session = [NSURLSession sharedSession];
    
    //    4.创建UploadTask类型的上传任务
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:
                                          ^(NSData *data, NSURLResponse *response, NSError *error) {
                                              // ...
                                          }];
    //    5.开始请求
    [uploadTask resume];
}

#pragma mark -- NSURLSessionDownloadTask 任务

- (void)sendDownloadTaskAsynRequestByBlock
{
    //    1.要下载的文件路径
    NSURL *URL = [NSURL URLWithString:@"http://example.com/file.zip"];
    
    //    2.创建请求对象
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    //    3.NSURLSession初始化
    NSURLSession *session = [NSURLSession sharedSession];
    
    /* Data task 和 upload task 会在任务完成时一次性返回
     但是 Download task 是将数据一点点地写入本地的临时文件。
     所以在 completionHandler 这个 block 里，我们需要把文件从一个临时地址移动到一个永久的地址保存起来*/
    
    //    4.创建DownloadTask类型的下传任务
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request
                                                            completionHandler:
                                              ^(NSURL *location, NSURLResponse *response, NSError *error)
                                              {
                                                  NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                                                  NSURL *documentsDirectoryURL = [NSURL fileURLWithPath:documentsPath];
                                                  NSURL *newFileLocation = [documentsDirectoryURL URLByAppendingPathComponent:[[response URL] lastPathComponent]];
                                                  [[NSFileManager defaultManager] copyItemAtURL:location toURL:newFileLocation error:nil];
                                              }];
    //    5.开始请求
    [downloadTask resume];
}

#pragma mark -- NSURLSessionDataTask 任务
//Block类型的DataTask任务

- (void)sendDataTaskAsynRequestByBlock
{
    //    1.设置请求路径
    NSURL *URL = [NSURL URLWithString:@"http://example.com"];
    
    //    2.创建请求对象
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    //     3.NSURLSession初始化
    NSURLSession *session = [NSURLSession sharedSession];
    
    //     4.创建DataTask类型的请求任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      // ...
                                  }];
    //    5.开始请求
    [task resume];
}

//delegate类型的DataTask
- (void)requestNetWork:(NSString*)urlStr
          successBlock:(successBlock)success
               failure:(failBlock)failure
{
    self.successBlock = success;
    self.failBlock = failure;
    
    /*1.NSURLRequestUseProtocolCachePolicy NSURLRequest         默认的cache policy，使用Protocol协议定义。
    2.NSURLRequestReloadIgnoringCacheData                       忽略缓存直接从原始地址下载。
    3.NSURLRequestReturnCacheDataDontLoad                       只使用cache数据，如果不存在cache，请求失败；用于没有建立网络连接离线模式
    4.NSURLRequestReturnCacheDataElseLoad                       只有在cache中不存在data时才从原始地址下载。
    5.NSURLRequestReloadIgnoringLocalAndRemoteCacheData         忽略本地和远程的缓存数据，直接从原始地址下载，与NSURLRequestReloadIgnoringCacheData类似。
    6.NSURLRequestReloadRevalidatingCacheData                   验证本地数据与远程数据是否相同，如果不同则下载远程数据，否则使用本地数据*/
    
    
    /*1. defaultSessionConfiguration      默认的,标准的configuration
     2.  ephemeralSessionConfiguration    返回一个预设配置，这个配置中不会对缓存，Cookie 和证书进行持久性的存储。这对于实现像秘密浏览这种功能来说是很理想的。
     3.  backgroundSessionConfiguration:(NSString *)identifier  的独特之处在于，它会创建一个后台 session。
         后台session不同于常规的普通的session，它甚至可以在应用程序挂起，退出或者崩溃的情况下运行上传和下载任务。
         初始化时指定的标识符，被用于向任何可能在进程外恢复后台传输的守护进程（daemon）提供上下文。
     */
    
    //    1.设置请求路径
    NSURL *url = [NSURL URLWithString:urlStr];
    
    //    2.创建请求对象
    NSURLRequest *requestUrl=[NSURLRequest requestWithURL:url];

    //    3.设置NSURLSession的配置
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    //    4.NSURLSession初始化  //Delegate模式接收数据
    self.session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    
    //    5.设置NSURLSession的请求对象
    self.dataTask = [self.session dataTaskWithRequest:requestUrl];
    
    //    6.开始请求
    [self.dataTask resume];
}

#pragma mark NSURLSessionDataDelegate

// 1.接收到服务器的响应
- (void)URLSession:(NSURLSession *)session
dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
    
    self.totalSize = response.expectedContentLength;
    
    NSLog(@"expected Length: %ld", (long)self.totalSize);
    
    NSLog(@"MIME TYPE %@", response.MIMEType);
}

// 2.接收到服务器的数据（可能调用多次）
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    // 处理每次接收的数据
    [self.recieveData appendData:data];
    
    self.currentSize += data.length;
    
    NSLog(@"进度－－－%.2f%%", 100.0*self.currentSize/self.totalSize);
    
    NSString *_progressStr = [NSString stringWithFormat:@"%.2f%%",100.0*self.currentSize/self.totalSize];
    
    self.isLoadFinished = false;
    if (self.totalSize == self.recieveData.length)
    {
        self.isLoadFinished = true;
    }
    
    // 请求完成,成功或者失败的处理
    if (data)
    {
        if (self.successBlock !=nil)
        {
            self.successBlock(data ,_progressStr, self.isLoadFinished);
        }
    }
}

// 3.当请求完成时调用，成功或者失败（如果失败，error有值）
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if (error)
    {
        if (self.failBlock != nil)
        {
            self.failBlock(error);
        }
    }
    
    if (self.recieveData)
    {
        self.recieveData = nil;
    }
    
    self.currentSize = 0;
    
    self.totalSize = 0;
    
    // 关闭会话
    [self.session invalidateAndCancel];
    
    NSLog(@"Connection Loading Finished!!!");
}

@end
