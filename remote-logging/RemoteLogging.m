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

void RLLog(NSString *format,...){
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

-(NSManagedObjectContext *)context{
    GNContextSettings *settings = [[GNContextSettings alloc] init];
    settings.persistentStoreType = NSInMemoryStoreType;
    settings.managedObjectModelPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"RLModel" ofType:@"momd"];
    return [[GNContextManager sharedInstance] managedObjectContextWithSettings:settings];
}

-(void)logMessage:(NSString *)message{
    RLLocalLog *log = [[self context] createObjectWithName:@"RLLocalLog"];
    log.body = message;
    log.date = [NSDate date];
    [[self context] save:nil];
}

@end
