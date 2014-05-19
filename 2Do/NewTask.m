//
//  NewTask.m
//  2Do
//
//  Created by Robin Crorie on 15/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import "NewTask.h"
#import "AppDelegate.h"

typedef enum {
	PriorityNone,
	PriorityLow,
	PriorityMedium,
    PriorityHigh
} Priority;

@interface NewTask () <UITextFieldDelegate, UITextViewDelegate, UIActionSheetDelegate>
{
	IBOutlet UITextField * taskTitle;
	IBOutlet UITextView * taskDescription;
	IBOutlet UITextField * taskPriority;
	IBOutlet UIDatePicker * dueDate;
	
	NSString * descriptionText;
	UIActionSheet * selectPriority;
	Priority priorityLevel;
	BOOL wasPushed;
}

@end

@implementation NewTask
@synthesize task;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	if (task) {
		wasPushed = YES;
		taskTitle.text = task.taskTitle;
		taskDescription.text = task.taskDescription ? task.taskDescription : @"Task Notes";
		descriptionText = task.taskDescription ? task.taskDescription : @"Task Notes";
		taskDescription.textColor = task.taskDescription ? [UIColor darkGrayColor] : [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1];
		dueDate.date = task.dueDate;
		switch (task.taskPriority.intValue) {
			case 1:
				priorityLevel = PriorityLow;
				taskPriority.text = @"Low";
				taskPriority.textColor = [UIColor darkGrayColor];
				break;
				
			case 2:
				priorityLevel = PriorityMedium;
				taskPriority.text = @"Medium";
				taskPriority.textColor = [UIColor orangeColor];
				break;
				
			case 3:
				priorityLevel = PriorityHigh;
				taskPriority.text = @"High";
				taskPriority.textColor = [UIColor redColor];
				break;
		}
		self.navigationItem.title = @"Edit Task";
	}
	else {
		UIBarButtonItem * leftBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelNewTask:)];
		self.navigationItem.leftBarButtonItem = leftBarButton;
	}
	
	float height = [self heightForTextView:taskDescription containingString:taskDescription.text];
    CGRect textViewRect = CGRectMake(74, 4, 280, height);
    
    taskDescription.frame = textViewRect;
    
    taskDescription.contentSize = CGSizeMake(280, [self heightForTextView:taskDescription containingString:taskDescription.text]);
	taskDescription.contentInset = UIEdgeInsetsMake(5,-5,0,0);
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	if (textField == taskPriority) {
		selectPriority = [[UIActionSheet alloc]
					   initWithTitle:@"Select Priority Level"
					   delegate:self
					   cancelButtonTitle:@"Cancel"
					   destructiveButtonTitle:nil
					   otherButtonTitles:@"High", @"Medium", @"Low", @"None", nil];
		
		[selectPriority showInView:self.view];
		
		return NO;
	}
	else {
		return YES;
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@"Task Notes"]) {
		textView.text = @"";
		textView.textColor = [UIColor darkGrayColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
	if (textView == taskDescription) {
		descriptionText = textView.text;
		taskDescription.contentSize = CGSizeMake(280, [self heightForTextView:taskDescription containingString:textView.text]);
		[self.tableView beginUpdates];
		[self.tableView endUpdates];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	if (textView == taskDescription) {
        descriptionText = textView.text;
		
		if ([textView.text isEqualToString:@""]) {
			textView.text = @"Task Notes";
			textView.textColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1];
		}
		[textView resignFirstResponder];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
	
	if  ([buttonTitle isEqualToString:@"High"]) {
		priorityLevel = PriorityHigh;
		[taskPriority setTextColor:[UIColor redColor]];
	}
	if ([buttonTitle isEqualToString:@"Medium"]) {
		priorityLevel = PriorityMedium;
		[taskPriority setTextColor:[UIColor orangeColor]];
	}
	if ([buttonTitle isEqualToString:@"Low"]) {
		priorityLevel = PriorityLow;
		[taskPriority setTextColor:[UIColor darkGrayColor]];
	}
	if ([buttonTitle isEqualToString:@"None"]) {
		priorityLevel = PriorityNone;
	}
	
	if ([buttonTitle isEqualToString:@"None"] || [buttonTitle isEqualToString:@"Cancel"]) {
		taskPriority.text = nil;
	}
	else {
		taskPriority.text = buttonTitle;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 0 && indexPath.row == 1) {
		NSLog(@"Description content size = %f", taskDescription.contentSize.height);
        if (taskDescription.contentSize.height > 50) {
            float height = [self heightForTextView:taskDescription containingString:descriptionText];
            return height;
        }
        else {
            return self.tableView.rowHeight;
        }
        
    }
	else if (indexPath.section == 1 && indexPath.row == 0) {
		return 220;
	}
	else {
		return self.tableView.rowHeight;
	}
}

- (CGFloat)heightForTextView:(UITextView*)textView containingString:(NSString*)string
{
    CGFloat horizontalPadding = 0;
    CGFloat verticalPadding = 25;
    CGFloat widthOfTextView = textView.contentSize.width - horizontalPadding;
	
	
	UIFont *font = [UIFont systemFontOfSize:18];
	NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName: font}];
	CGRect rect = [attributedText boundingRectWithSize:(CGSize){widthOfTextView, CGFLOAT_MAX}
											   options:NSStringDrawingUsesLineFragmentOrigin
											   context:nil];
	CGFloat height = rect.size.height + verticalPadding;
    
	return height;
}

- (IBAction)saveTask:(id)sender {
	
	BOOL validationError = NO;
	int userId = [[[NSUserDefaults standardUserDefaults] valueForKey:@"UserId"] intValue];
	
	if (taskTitle.text.length == 0) {
		validationError = YES;
		taskTitle.superview.layer.masksToBounds=YES;
		taskTitle.superview.layer.borderColor=[[UIColor redColor]CGColor];
		taskTitle.superview.layer.borderWidth= 1.0f;
	}
	
	if (!validationError) {
		AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
		
		NSManagedObjectContext *context = [appDelegate managedObjectContext];
		
		if (!task) {
			task = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:context];
		}
		task.taskTitle = taskTitle.text;
		task.taskDescription = [taskDescription.text isEqualToString:@"Task Notes"] ? nil : taskDescription.text;
		task.taskPriority = [NSNumber numberWithInt:priorityLevel];
		task.userId = [NSNumber numberWithInt:userId];
		task.dueDate = dueDate.date;
		task.updateDate = [[NSDate alloc] init];
		
		NSError *error;
		[context save:&error];
		if (!error) {
			if (wasPushed)
				[self.navigationController popViewControllerAnimated:YES];
			else
				[self dismissViewControllerAnimated:YES completion:nil];
		}
		else {
			NSLog(@"Error: %@", error.localizedDescription);
		}
	}
}

- (void)cancelNewTask:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
