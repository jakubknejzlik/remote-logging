//
//  remote_logging.m
//  remote-logging
//
//  Created by Jakub Knejzlik on 26/01/15.
//  Copyright (c) 2015 Jakub Knejzlik. All rights reserved.
//

#import "RemoteLogging.h"

#import "RLLocalLog.h"

#import <CWLSynthesizeSingleton.h>
#import <GNContextManager.h>
#import <AFNetworking.h>
#import <ISO8601.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif


@interface RemoteLogging ()
@property (nonatomic,strong) NSString *appKey;
+(instancetype)sharedInstance;

@property BOOL needsSave;
@property (nonatomic,strong) NSManagedObjectContext *context;
@property (nonatomic,strong) NSManagedObjectContext *readContext;
@property (nonatomic,strong) AFHTTPRequestOperationManager *httpManager;

@property (nonatomic,strong) NSTimer *sendLogTimer;
@property (nonatomic) RemoteLoggingLogLevel logLevel;

@end


extern void RLLog(NSString *format,...){
    // Type to hold information about variable arguments.
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    NSLog(@"%@",body);
    [RemoteLogging logMessage:body sync:NO];
}
extern void RLSyncLog(NSString *format,...){
    // Type to hold information about variable arguments.
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    NSLog(@"%@",body);
    [RemoteLogging logMessage:body sync:YES];
}



@implementation RemoteLogging
CWL_SYNTHESIZE_SINGLETON_FOR_CLASS_WITH_ACCESSOR(RemoteLogging, sharedInstance);


+(void)takeOff:(NSString *)appKey{
    [[self sharedInstance] setAppKey:appKey];
    
    [[self sharedInstance] setSendLogTimer:[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(sendLogs) userInfo:nil repeats:YES]];
    
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(appDidFinnishLaunching) name:UIApplicationDidFinishLaunchingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
    
}
+(void)setLogLevel:(RemoteLoggingLogLevel)level{
    [[self sharedInstance] setLogLevel:level];
}

-(NSURL *)persistentStoreURL{
    if (!_persistentStoreURL) {
        return [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"RLModelStore.sqlite"]];
    }
    return _persistentStoreURL;
}

-(NSManagedObjectContext *)context{
    if(!_context){
        GNContextSettings *settings = [GNContextSettings privateQueueDefaultSettings];
        settings.managedObjectModelPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"RLModel" ofType:@"momd"];
        settings.persistentStoreUrl = [self persistentStoreURL];
        _context = [[GNContextManager sharedInstance] managedObjectContextWithSettings:settings];
    }
    return _context;
}
-(NSManagedObjectContext *)readContext{
    if(!_readContext){
        GNContextSettings *settings = [GNContextSettings privateQueueDefaultSettings];
        settings.managedObjectModelPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"RLModel" ofType:@"momd"];
        settings.persistentStoreUrl = [self persistentStoreURL];
        _readContext = [[GNContextManager sharedInstance] managedObjectContextWithSettings:settings];
    }
    return _readContext;
}

-(AFHTTPRequestOperationManager *)httpManager{
    if (!_httpManager) {
        _httpManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://remlog.api.thefuntasty.com/v1"]];
        _httpManager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    return _httpManager;
}

+(void)logMessage:(NSString *)message{
    [self logMessage:message sync:NO];
}
+(void)logMessage:(NSString *)message sync:(BOOL)sync{
    [[self sharedInstance] logMessage:message sync:sync];
}
-(void)logMessage:(NSString *)message{
    [self logMessage:message sync:NO];
}
-(void)logMessage:(NSString *)message sync:(BOOL)sync{
    if(sync){
        [self.context performBlockAndWait:^{
            RLLocalLog *log = [self.context createObjectWithName:@"RLLocalLog"];
            log.body = message;
            log.date = [NSDate date];
            [self save:nil];
        }];
    }else{
        [self.context performBlock:^{
            RLLocalLog *log = [self.context createObjectWithName:@"RLLocalLog"];
            log.body = message;
            log.date = [NSDate date];
            [self setNeedsSave];
        }];
    }
}

-(void)setNeedsSave{
    if (!self.needsSave) {
        self.needsSave = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self saveIfNeeded];
        });
    }
}
-(void)saveIfNeeded{
    if (self.needsSave) {
        [self save:nil];
        self.needsSave = NO;
    }
}
-(BOOL)save:(NSError **)error{
    __block BOOL saved = NO;
    [self.context performBlockAndWait:^{
        saved = [self.context save:error];
        [self.context reset];
    }];
    return saved;
}

+(void)sendLogs{
    [self sendLogsWithCompletionHandler:^(NSError *error) {
        if([[self sharedInstance] logLevel] == RemoteLoggingLogLevelAll){
            NSLog(@"logs sent remaining: %i",(int)[[[self sharedInstance] context] numberOfObjectsWithName:@"RLLocalLog" predicate:[NSPredicate predicateWithFormat:@"SELF.sent = NO"]]);
        }
    }];
}
+(void)sendLogsWithCompletionHandler:(void (^)(NSError *))completionHandler{
    [[self sharedInstance] sendLogsWithCompletionHandler:completionHandler];
}
-(void)sendLogsWithCompletionHandler:(void (^)(NSError *error))completionHandler{
    if(!self.appKey)return completionHandler([NSError errorWithDomain:@"RemoteLogging missing appKey" code:-1000 userInfo:nil]);
    NSArray *logs = [self.readContext objectsWithName:@"RLLocalLog" predicate:[NSPredicate predicateWithFormat:@"SELF.sent = NO"] sortDescriptors:nil limit:500];
    
    if([logs count] == 0){
        if(self.logLevel == RemoteLoggingLogLevelAll)NSLog(@"no logs to send");
        return completionHandler(nil);
    }
    
    NSMutableArray *logsData = [NSMutableArray array];
    for (RLLocalLog *log in logs) {
        [logsData addObject:@{@"identifier":[[log.objectID URIRepresentation] absoluteString],@"body":log.body,@"date":[log.date ISO8601String]}];
    }
    
    NSDictionary *data = @{@"app_id":self.appKey,@"data":logsData,@"device":[self deviceIdentifier]};
    [self.httpManager POST:@"logs" parameters:data success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.readContext performBlockAndWait:^{
            for (RLLocalLog *log in logs) {
                log.sent = @YES;
            }
            [self.readContext save:nil];
            [self.readContext reset];
        }];
        completionHandler(nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completionHandler(error);
    }];
}

-(NSString *)deviceIdentifier{
#if TARGET_OS_IPHONE
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif
    
    return @"unknown";
}

#pragma mark - iOS App Events
-(void)appDidFinnishLaunching{
    [self logMessage:@"app did finnish launching"];
}
-(void)appWillEnterForeground{
    [self logMessage:@"app will enter foreground"];
}
-(void)appDidBecomeActive{
    [self logMessage:@"app did become active"];
}
-(void)appWillResignActive{
    [self logMessage:@"app will resign active"];
}
-(void)appDidEnterBackground{
    [self logMessage:@"app did enter background"];
}

@end
