//
//  remote-logging.h
//  remote-logging
//
//  Created by Jakub Knejzlik on 26/01/15.
//  Copyright (c) 2015 Jakub Knejzlik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RLLocalLog : NSManagedObject

@property (nonatomic, retain) id body;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * sent;

@end
