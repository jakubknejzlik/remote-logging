//
//  remote_logging.h
//  remote-logging
//
//  Created by Jakub Knejzlik on 26/01/15.
//  Copyright (c) 2015 Jakub Knejzlik. All rights reserved.
//

#import <Foundation/Foundation.h>


void RLLog(NSString *format,...);
void RLSyncLog(NSString *format,...);


@interface RemoteLogging : NSObject
@property (nonatomic,copy) NSURL *persistentStoreURL;

+(void)takeOff:(NSString *)appKey;

+(void)logMessage:(NSString *)message;
+(void)logMessage:(NSString *)message sync:(BOOL)sync;

+(void)sendLogs;
+(void)sendLogsWithCompletionHandler:(void(^)(NSError *error))completionHandler;

@end
