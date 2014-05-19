//
//  Task.h
//  2Do
//
//  Created by Robin Crorie on 18/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Task : NSManagedObject

@property (nonatomic, retain) NSDate * dueDate;
@property (nonatomic) BOOL isComplete;
@property (nonatomic, retain) NSString * taskDescription;
@property (nonatomic, retain) NSNumber * taskPriority;
@property (nonatomic, retain) NSString * taskTitle;
@property (nonatomic, retain) NSDate * updateDate;
@property (nonatomic, retain) NSNumber * taskId;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic) BOOL hasBeenDeleted;

@end
