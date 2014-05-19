//
//  SoapTool.m
//  Own'd
//
//  Created by Robin Crorie on 14/01/2014.
//  Copyright (c) 2014 WebXr. All rights reserved.
//

#import "SoapTool.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "GDataXMLNode.h"
#import "TaskObject.h"

@implementation SoapTool
@synthesize xmlData;

- (id)init
{
	self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

+ (NSData*)sendSOAP:(NSString *)soapMessage soapURL:(NSString*)soapURL error:(NSError**)error
{
	NSURL *url = [NSURL URLWithString:soapURL];
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
	NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapMessage length]];
	
	[theRequest addValue: @"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[theRequest addValue: msgLength forHTTPHeaderField:@"Content-Length"];
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSError * connectionError;
	NSURLResponse * response;
	NSData * xmlData = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&connectionError];
	
	if (connectionError) {
		*error = connectionError;
		return nil;
	} else {
		return xmlData;
	}
}

+ (int)checkPassword:(NSString*)password email:(NSString*)email error:(NSError**)error
{
	@synchronized(self) {
		
		int userId;
		
		NSString *soapMessage = [NSString stringWithFormat:
								 @"<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ser=\"http://service.2Do.webxr.co.uk\">\n"
								 "<soapenv:Header/>\n"
								 "<soapenv:Body>\n"
								 "<ser:CheckPassword>\n"
								 "<Email>%@</Email>\n"
								 "<Password>%@</Password>\n"
								 "</ser:CheckPassword>\n"
								 "</soapenv:Body>\n"
								 "</soapenv:Envelope>\n", email, password
								 ];
		
		NSData * xmlData = [SoapTool sendSOAP:soapMessage soapURL:SoapURL_UserAccountManager error:&*error];
		
		if (!*error) {
			GDataXMLDocument * xmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&*error];
			
			GDataXMLElement * errorElement = [[xmlDoc.rootElement elementForName:@"S:Body"] elementForName:@"S:Fault"];
			if (errorElement) {
				NSLog(@"%@", [errorElement elementForName:@"faultstring"].stringValue);
				NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
				[errorDetail setValue:[errorElement elementForName:@"faultstring"].stringValue forKey:NSLocalizedDescriptionKey];
				*error = [[NSError alloc] initWithDomain:@"Faultstring" code:101 userInfo:errorDetail];
			}
			
			GDataXMLElement * result = [[xmlDoc nodeForXPath:@"//S:Body" error:&*error] elementForName:@"ns2:CheckPasswordResponse"];
			
			userId = [[result elementForName:@"UserId"].stringValue intValue];
		}
		
		return userId;
	}
}

+ (int)createUserAccount:(NSString*)email password:(NSString*)password error:(NSError**)error
{
	@synchronized(self) {
		
		int userId;
		
		NSString *soapMessage = [NSString stringWithFormat:
								 @"<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ser=\"http://service.2Do.webxr.co.uk\">\n"
								 "<soapenv:Header/>\n"
								 "<soapenv:Body>\n"
								 "<ser:CreateUserAccount>\n"
								 "<Email>%@</Email>\n"
								 "<Password>%@</Password>\n"
								 "</ser:CreateUserAccount>\n"
								 "</soapenv:Body>\n"
								 "</soapenv:Envelope>\n", email, password
								 ];
		
		NSData * xmlData = [SoapTool sendSOAP:soapMessage soapURL:SoapURL_UserAccountManager error:&*error];
		
		if (!*error) {
			GDataXMLDocument * xmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&*error];
			
			GDataXMLElement * errorElement = [[xmlDoc.rootElement elementForName:@"S:Body"] elementForName:@"S:Fault"];
			if (errorElement) {
				NSLog(@"%@", [errorElement elementForName:@"faultstring"].stringValue);
				NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
				[errorDetail setValue:[errorElement elementForName:@"faultstring"].stringValue forKey:NSLocalizedDescriptionKey];
				*error = [[NSError alloc] initWithDomain:@"Faultstring" code:101 userInfo:errorDetail];
			}
			
			GDataXMLElement * result = [[xmlDoc nodeForXPath:@"//S:Body" error:&*error] elementForName:@"ns2:CreateUserAccountResponse"];
			
			userId = [[result elementForName:@"UserId"].stringValue intValue];
		}
		
		return userId;
	}
}

+ (NSMutableArray*)getTasksForUserId:(int)userId error:(NSError**)error
{
	@synchronized(self) {
		
		NSMutableArray * tasks = [[NSMutableArray alloc] init];
		NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale * loc = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
		dateFormatter.locale = loc;
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
		
		NSString *soapMessage = [NSString stringWithFormat:
								 @"<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ser=\"http://service.2Do.webxr.co.uk\">\n"
								 "<soapenv:Header/>\n"
								 "<soapenv:Body>\n"
								 "<ser:SyncTasks>\n"
								 "<UserId>%d</UserId>\n"
								 "</ser:SyncTasks>\n"
								 "</soapenv:Body>\n"
								 "</soapenv:Envelope>\n", userId
								 ];
		
		NSData * xmlData = [SoapTool sendSOAP:soapMessage soapURL:SoapURL_TaskManager error:&*error];
		
		if (!*error) {
			GDataXMLDocument * xmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&*error];
			
			GDataXMLElement * errorElement = [[xmlDoc.rootElement elementForName:@"S:Body"] elementForName:@"S:Fault"];
			if (errorElement) {
				NSLog(@"%@", [errorElement elementForName:@"faultstring"].stringValue);
				NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
				[errorDetail setValue:[errorElement elementForName:@"faultstring"].stringValue forKey:NSLocalizedDescriptionKey];
				*error = [[NSError alloc] initWithDomain:@"Faultstring" code:101 userInfo:errorDetail];
			}
			
			GDataXMLElement * result = [[xmlDoc nodeForXPath:@"//S:Body" error:&*error] elementForName:@"ns2:SyncTasksResponse"];
			
			NSArray * taskResults = [result elementsForName:@"Task"];
			
			for (GDataXMLElement * taskElement in taskResults) {
				TaskObject * task = [[TaskObject alloc] init];
				
				task.taskId = [NSNumber numberWithInt:[[taskElement elementForName:@"taskId"].stringValue intValue]];
				task.taskTitle = [taskElement elementForName:@"title"].stringValue;
				task.taskDescription = [taskElement elementForName:@"description"].stringValue;
				task.taskPriority = [NSNumber numberWithInt:[[taskElement elementForName:@"priority"].stringValue intValue]];
				task.isComplete = [[taskElement elementForName:@"isComplete"].stringValue isEqualToString:@"1"] ? YES : NO;
				task.dueDate = [dateFormatter dateFromString:[taskElement elementForName:@"dueDate"].stringValue];
				task.updateDate = [dateFormatter dateFromString:[taskElement elementForName:@"updateDate"].stringValue];
				task.userId = [NSNumber numberWithInt:userId];
				
				[tasks addObject:task];
			}
		}
		
		return tasks;
	}
}

+ (BOOL)updateTask:(Task*)task error:(NSError**)error
{
	@synchronized(self) {
		
		BOOL isSuccessful;
		
		NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale * loc = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
		dateFormatter.locale = loc;
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
		
		NSString *soapMessage = [NSString stringWithFormat:
								 @"<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ser=\"http://service.2Do.webxr.co.uk\">\n"
								 "<soapenv:Header/>\n"
								 "<soapenv:Body>\n"
								 "<ser:UpdateTask>\n"
								 "<TaskId>%@</TaskId>\n"
								 "<Title>%@</Title>\n"
								 "<Description>%@</Description>\n"
								 "<Priority>%d</Priority>\n"
								 "<IsComplete>%hhd</IsComplete>\n"
								 "<DueDate>%@</DueDate>\n"
								 "<UpdatedDate>%@</UpdatedDate>\n"
								 "</ser:UpdateTask>\n"
								 "</soapenv:Body>\n"
								 "</soapenv:Envelope>\n", [task.taskId stringValue], task.taskTitle, task.taskDescription, [task.taskPriority intValue], task.isComplete, [dateFormatter stringFromDate:task.dueDate], [dateFormatter stringFromDate:task.updateDate]
								 ];
		
		NSData * xmlData = [SoapTool sendSOAP:soapMessage soapURL:SoapURL_TaskManager error:&*error];
		
		if (!*error) {
			GDataXMLDocument * xmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&*error];
			
			GDataXMLElement * errorElement = [[xmlDoc.rootElement elementForName:@"S:Body"] elementForName:@"S:Fault"];
			if (errorElement) {
				NSLog(@"%@", [errorElement elementForName:@"faultstring"].stringValue);
				NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
				[errorDetail setValue:[errorElement elementForName:@"faultstring"].stringValue forKey:NSLocalizedDescriptionKey];
				*error = [[NSError alloc] initWithDomain:@"Faultstring" code:101 userInfo:errorDetail];
			}
			
			GDataXMLElement * result = [[xmlDoc nodeForXPath:@"//S:Body" error:&*error] elementForName:@"ns2:UpdateTaskResponse"];
			
			isSuccessful = [[result elementForName:@"IsSuccessful"].stringValue isEqualToString:@"true"] ? YES : NO;
		}
		
		return isSuccessful;
	}
}

+ (int)addTask:(Task*)task error:(NSError**)error
{
	@synchronized(self) {
		
		int taskId;
		
		NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale * loc = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
		dateFormatter.locale = loc;
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
		
		NSString *soapMessage = [NSString stringWithFormat:
								 @"<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ser=\"http://service.2Do.webxr.co.uk\">\n"
								 "<soapenv:Header/>\n"
								 "<soapenv:Body>\n"
								 "<ser:AddTask>\n"
								 "<UserId>%@</UserId>\n"
								 "<Title>%@</Title>\n"
								 "<Description>%@</Description>\n"
								 "<Priority>%d</Priority>\n"
								 "<IsComplete>%hhd</IsComplete>\n"
								 "<DueDate>%@</DueDate>\n"
								 "<UpdatedDate>%@</UpdatedDate>\n"
								 "</ser:AddTask>\n"
								 "</soapenv:Body>\n"
								 "</soapenv:Envelope>\n", task.userId, task.taskTitle, task.taskDescription, [task.taskPriority intValue], task.isComplete, [dateFormatter stringFromDate:task.dueDate], [dateFormatter stringFromDate:task.updateDate]
								 ];
		
		NSData * xmlData = [SoapTool sendSOAP:soapMessage soapURL:SoapURL_TaskManager error:&*error];
		
		if (!*error) {
			GDataXMLDocument * xmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&*error];
			
			GDataXMLElement * errorElement = [[xmlDoc.rootElement elementForName:@"S:Body"] elementForName:@"S:Fault"];
			if (errorElement) {
				NSLog(@"%@", [errorElement elementForName:@"faultstring"].stringValue);
				NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
				[errorDetail setValue:[errorElement elementForName:@"faultstring"].stringValue forKey:NSLocalizedDescriptionKey];
				*error = [[NSError alloc] initWithDomain:@"Faultstring" code:101 userInfo:errorDetail];
			}
			
			GDataXMLElement * result = [[xmlDoc nodeForXPath:@"//S:Body" error:&*error] elementForName:@"ns2:AddTaskResponse"];
			
			taskId = [[result elementForName:@"TaskId"].stringValue intValue];
		}
		
		return taskId;
	}
}

+ (BOOL)deleteTask:(Task*)task error:(NSError**)error
{
	@synchronized(self) {
		
		BOOL isDeleted;
		
		NSString *soapMessage = [NSString stringWithFormat:
								 @"<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ser=\"http://service.2Do.webxr.co.uk\">\n"
								 "<soapenv:Header/>\n"
								 "<soapenv:Body>\n"
								 "<ser:DeleteTask>\n"
								 "<TaskId>%d</TaskId>\n"
								 "</ser:DeleteTask>\n"
								 "</soapenv:Body>\n"
								 "</soapenv:Envelope>\n", [task.taskId intValue]
								 ];
		
		NSData * xmlData = [SoapTool sendSOAP:soapMessage soapURL:SoapURL_TaskManager error:&*error];
		
		if (!*error) {
			GDataXMLDocument * xmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&*error];
			
			GDataXMLElement * errorElement = [[xmlDoc.rootElement elementForName:@"S:Body"] elementForName:@"S:Fault"];
			if (errorElement) {
				NSLog(@"%@", [errorElement elementForName:@"faultstring"].stringValue);
				NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
				[errorDetail setValue:[errorElement elementForName:@"faultstring"].stringValue forKey:NSLocalizedDescriptionKey];
				*error = [[NSError alloc] initWithDomain:@"Faultstring" code:101 userInfo:errorDetail];
			}
			
			GDataXMLElement * result = [[xmlDoc nodeForXPath:@"//S:Body" error:&*error] elementForName:@"ns2:DeleteTaskResponse"];
			
			isDeleted = [[result elementForName:@"IsSuccessful"].stringValue isEqualToString:@"true"] ? YES : NO;
		}
		
		return isDeleted;
	}
}

@end
