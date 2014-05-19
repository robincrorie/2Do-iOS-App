//
//  Synchroniser.m
//  2Do
//
//  Created by Robin Crorie on 18/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import "Synchroniser.h"
#import "AppDelegate.h"
#import "Task.h"
#import "TaskObject.h"
#import "SoapTool.h"

@implementation Synchroniser

+ (BOOL)syncTasks:(NSError**)error
{
	BOOL syncSuccessful = NO;
	
	int userId = [[[NSUserDefaults standardUserDefaults] valueForKey:@"UserId"] intValue];
	
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"userId = %d", userId];
    [request setPredicate:pred];
    
	NSMutableArray * localTasks = [NSMutableArray arrayWithArray:[context executeFetchRequest:request error:&*error]];
	
	NSMutableArray * localTaskIds = [[NSMutableArray alloc] init];
	NSMutableArray * remoteTaskIds = [[NSMutableArray alloc] init];
	
	// Check all local tasks are on the server
	for (Task * localTask in localTasks) {
		if (localTask.hasBeenDeleted) {
			NSError * deleteTaskError = nil;
			[SoapTool deleteTask:localTask error:&deleteTaskError];
			if (!deleteTaskError) {
				[context deleteObject:localTask];
				[context save:&*error];
			}
		}
		else if ([localTask.taskId intValue] == 0) {
			int addedTaskId = [SoapTool addTask:localTask error:&*error];
			localTask.taskId = [NSNumber numberWithInt:addedTaskId];
			[context save:&*error];
		}
		
		[localTaskIds addObject:[NSString stringWithFormat:@"%d", [localTask.taskId intValue]]];
	}
	
	NSMutableArray * remoteTasks = [SoapTool getTasksForUserId:userId error:&*error];
	
	for (TaskObject * remoteTask in remoteTasks) {
		for (Task * localTask in localTasks) {
			if ([localTask.taskId intValue] == [remoteTask.taskId intValue]) {
				CGFloat timeDifference = [localTask.updateDate timeIntervalSinceDate:remoteTask.updateDate];
				if (timeDifference > 0) {
					// Update remote task with local
					[SoapTool updateTask:localTask error:&*error];
				}
				else if (timeDifference < 0) {
					// Update local task with remote
					localTask.taskTitle = remoteTask.taskTitle;
					localTask.userId = remoteTask.userId;
					localTask.taskDescription = remoteTask.taskDescription;
					localTask.taskPriority = remoteTask.taskPriority;
					localTask.dueDate = remoteTask.dueDate;
					localTask.updateDate = remoteTask.updateDate;
					localTask.isComplete = remoteTask.isComplete;
					[context save:&*error];
				}
			}
		}
		
		NSString * remoteTaskId =[NSString stringWithFormat:@"%d", [remoteTask.taskId intValue]];
		if (![localTaskIds containsObject:remoteTaskId]) {
			// Add remote task to local
			Task * newTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:context];
			newTask.taskId = remoteTask.taskId;
			newTask.userId = remoteTask.userId;
			newTask.taskTitle = remoteTask.taskTitle;
			newTask.taskDescription = remoteTask.taskDescription;
			newTask.taskPriority = remoteTask.taskPriority;
			newTask.dueDate = remoteTask.dueDate;
			newTask.updateDate = remoteTask.updateDate;
			newTask.isComplete = remoteTask.isComplete;
			
			[context save:&*error];
		}
		
		[remoteTaskIds addObject:[NSString stringWithFormat:@"%d", [remoteTask.taskId intValue]]];
	}
	
	// Remove any local tasks that have been removed from the server
	for (Task * localTask in localTasks) {
		NSString * localTaskId =[NSString stringWithFormat:@"%d", [localTask.taskId intValue]];
		if (![remoteTaskIds containsObject:localTaskId]) {
			[context deleteObject:localTask];
			[context save:&*error];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:[[NSDate alloc] init] forKey:@"LastSyncDate"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	syncSuccessful = YES;
	
	return syncSuccessful;
}

@end
