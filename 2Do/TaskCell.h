//
//  TaskCell.h
//  2Do
//
//  Created by Robin Crorie on 15/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TaskCellDelegate <NSObject>
@required
- (void)markCompleted:(id)sender;
@end

@interface TaskCell : UITableViewCell
{
	id <TaskCellDelegate> _delegate;
}

@property (nonatomic, strong) IBOutlet UIView * taskPriority;
@property (nonatomic, strong) IBOutlet UILabel * taskTitle;
@property (nonatomic, strong) IBOutlet UILabel * taskDescription;
@property (nonatomic, strong) IBOutlet UILabel * taskDueDate;
@property (nonatomic, strong) IBOutlet UIButton * completedButton;
@property (nonatomic,strong) id delegate;

@end
