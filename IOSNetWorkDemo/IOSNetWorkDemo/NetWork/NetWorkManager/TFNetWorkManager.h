//
//  TFNetWorkManager.h
//  CommonDemo
//
//  Created by 孙伟伟 on 16/7/8.
//  Copyright © 2016年 孙伟伟. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^successBlock)(NSData *netData ,NSString *progressStr, BOOL isFinished);

typedef void (^failBlock)(NSError *error);


@interface TFNetWorkManager : NSObject

@property (nonatomic,copy) successBlock successBlock;

@property (nonatomic,copy) failBlock failBlock;

+ (TFNetWorkManager*)sharedInstances;

//网络请求
- (void)requestNetWork:(NSString*)urlStr
          successBlock:(successBlock)success
               failure:(failBlock)failure;

@end
