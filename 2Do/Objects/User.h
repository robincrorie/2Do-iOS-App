//
//  User.h
//  2Do
//
//  Created by Robin Crorie on 18/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * password;

@end
