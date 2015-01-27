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

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif


@interface RemoteLogging ()
+(instancetype)sharedInstance;
@property (nonatomic,strong) NSManagedObjectContext *context;
@property BOOL needsSave;
@end


extern void RLLog(NSString *format,...){
    // Type to hold information about variable arguments.
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    NSLog(@"%@",body);
    [[RemoteLogging sharedInstance] logMessage:body];
}



@implementation RemoteLogging
CWL_SYNTHESIZE_SINGLETON_FOR_CLASS_WITH_ACCESSOR(RemoteLogging, sharedInstance);


+(void)takeOff:(NSString *)appKey{
    
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(appDidFinnishLaunching) name:UIApplicationDidFinishLaunchingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
    
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

-(void)logMessage:(NSString *)message{
    [self logMessage:message async:YES];
}
-(void)logMessage:(NSString *)message async:(BOOL)async{
    [self.context performBlock:^{
        RLLocalLog *log = [self.context createObjectWithName:@"RLLocalLog"];
        log.body = message;
        log.date = [NSDate date];
        if(async){
            [self setNeedsSave];
        }else{
            [self save:nil];
        }
    }];
}

-(void)setNeedsSave{
    if (!self.needsSave) {
        self.needsSave = YES;
        [self performSelector:@selector(saveIfNeeded) withObject:nil afterDelay:3];
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
    }];
    return saved;
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
