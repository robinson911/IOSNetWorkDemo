//
//  NSStream+StreamsToHost.h
//  KSNetworkDemo
//
//  Created by kesalin on 15/4/13.
//  Copyright (c) 2013 kesalin@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSStream(StreamsToHost)

+ (void)getStreamsToHostNamed:(NSString *)hostName
                         port:(NSInteger)port
                  inputStream:(NSInputStream **)inputStreamPtr
                 outputStream:(NSOutputStream **)outputStreamPtr;
@end
