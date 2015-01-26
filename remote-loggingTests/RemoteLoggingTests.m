//
//  RemoteLoggingTests.m
//  remote-logging
//
//  Created by Jakub Knejzlik on 26/01/15.
//  Copyright (c) 2015 Jakub Knejzlik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "RemoteLogging.h"

@interface RemoteLoggingTests : XCTestCase

@end

@implementation RemoteLoggingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    RLLog(@"test %@",@25);
}

@end
