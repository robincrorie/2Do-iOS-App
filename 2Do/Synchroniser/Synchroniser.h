//
//  Synchroniser.h
//  2Do
//
//  Created by Robin Crorie on 18/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Synchroniser : NSObject

+ (BOOL)syncTasks:(NSError**)error;

@end
