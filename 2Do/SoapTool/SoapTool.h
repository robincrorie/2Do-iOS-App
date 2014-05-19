//
//  SoapTool.h
//  Own'd
//
//  Created by Robin Crorie on 14/01/2014.
//  Copyright (c) 2014 WebXr. All rights reserved.
//

#import "AppDelegate.h"
#import "Task.h"

@interface SoapTool : NSObject  <NSURLConnectionDelegate>

@property (nonatomic, strong) NSMutableData * xmlData;

+ (int)checkPassword:(NSString*)password email:(NSString*)email error:(NSError**)error;

+ (int)createUserAccount:(NSString*)email password:(NSString*)password error:(NSError**)error;

+ (NSMutableArray*)getTasksForUserId:(int)userId error:(NSError**)error;

+ (BOOL)updateTask:(Task*)task error:(NSError**)error;

+ (int)addTask:(Task*)task error:(NSError**)error;

+ (BOOL)deleteTask:(Task*)task error:(NSError**)error;

@end
