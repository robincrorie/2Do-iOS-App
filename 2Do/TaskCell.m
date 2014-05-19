//
//  TaskCell.m
//  2Do
//
//  Created by Robin Crorie on 15/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import "TaskCell.h"

@implementation TaskCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)markCompletedButton:(id)sender
{
	[self.delegate markCompleted:self];
}

@end
