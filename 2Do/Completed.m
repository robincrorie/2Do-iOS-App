//
//  Completed.m
//  2Do
//
//  Created by Robin Crorie on 14/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import "Completed.h"
#import "TaskCell.h"
#import "AppDelegate.h"
#import "Task.h"
#import "NewTask.h"
#import "Synchroniser/Synchroniser.h"
#import "RefreshTableHeader/RefreshTableHeader.h"

@interface Completed () <TaskCellDelegate, RefreshTableHeaderDelegate>
{
	RefreshTableHeader *_refreshHeader;
	BOOL _reloading;
	NSMutableArray * tasks;
	NSDateFormatter * dateFormatter;
	
	NSManagedObjectContext *context;
}

@end

@implementation Completed

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
	
	dateFormatter = [[NSDateFormatter alloc] init];
	NSLocale * loc = [[NSLocale alloc] initWithLocaleIdentifier:@"en_UK"];
	[dateFormatter setLocale:loc];
    
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	if (_refreshHeader == nil) {
		RefreshTableHeader *view = [[RefreshTableHeader alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		view.delegate = self;
		[self.tableView addSubview:view];
		_refreshHeader = view;
	}
	
	//  update the last update date
	[_refreshHeader refreshLastUpdatedDate];
	
	[self loadTasks];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self loadTasks];
}

- (void)loadTasks {
	tasks = [[NSMutableArray alloc] init];
	
	NSString * userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserId"];
	
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
    context = [appDelegate managedObjectContext];
	
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:context];
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
	
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isComplete = YES && (hasBeenDeleted = NO OR hasBeenDeleted = nil) && (userId = %@)", userId];
    [request setPredicate:pred];
	
    NSError *error;
    tasks = [NSMutableArray arrayWithArray:[[context executeFetchRequest:request error:&error] sortedArrayUsingComparator:^NSComparisonResult(Task * task1, Task * task2) {
		return [task1.dueDate compare:task2.dueDate];
	}]];
	
	[self.tableView reloadData];
}

- (void)markCompleted:(id)sender
{
	TaskCell *clickedCell = (TaskCell*)sender;
	UIButton *button = clickedCell.completedButton;
    NSIndexPath *indexPathCell = [self.tableView indexPathForCell:clickedCell];
	
	if ([button isSelected])
		[button setSelected:NO];
	else
		[button setSelected:YES];
	
	Task * task = tasks[indexPathCell.row];
	task.isComplete = [button isSelected];
	task.updateDate = [[NSDate alloc] init];
	
	NSError * error = nil;
	[context save:&error];
	if (!error) {
		[self performSelector:@selector(removeCellAtIndexPath:) withObject:indexPathCell afterDelay:0.3];
	}
	else
		NSLog(@"Error: %@", error.localizedDescription);
}

- (void)removeCellAtIndexPath:(NSIndexPath*)indexPath
{
	[tasks removeObjectAtIndex:indexPath.row];
	if (tasks.count >= 1)
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
	else
		[self.tableView reloadData];
}

- (void)syncData
{
	// Update current core data with that from the web service
	dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError * error = nil;
		[Synchroniser syncTasks:&error];
		dispatch_async( dispatch_get_main_queue(), ^{
			if (!error) {
				[self loadTasks];
			}
			else {
				NSLog(@"Error: %@", error.localizedDescription);
				UIAlertView * syncAlert = [[UIAlertView alloc] initWithTitle:@"Sync Error" message:@"Unable to syncronise with the server. Please check your internet connection." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
				[syncAlert show];
			}
			[self endRefreshing];
		});
	});
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	if (tasks.count >= 1)
		return tasks.count;
	else
		return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tasks.count >= 1) {
		
		TaskCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Task" forIndexPath:indexPath];
		
		Task * task = tasks[indexPath.row];
		
		cell.taskTitle.text = task.taskTitle;
		cell.taskDescription.text = task.taskDescription;
		
		NSCalendar *cal = [NSCalendar currentCalendar];
		NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
		NSDate *today = [cal dateFromComponents:components];
		components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:task.dueDate];
		NSDate *otherDate = [cal dateFromComponents:components];
		
		if([today compare:otherDate] == NSOrderedSame) {
			[dateFormatter setDateFormat:@"'Today -' HH:mm"];
		}
		else {
			[dateFormatter setDateFormat:@"dd MMM yyyy - HH:mm"];
		}
		
		cell.taskDueDate.text = [dateFormatter stringFromDate:task.dueDate];
		if ([task.dueDate timeIntervalSinceNow] < 0) {
			cell.taskDueDate.textColor = [UIColor redColor];
			cell.taskDueDate.font = [UIFont boldSystemFontOfSize:13];
		}
		else {
			cell.taskDueDate.textColor = [UIColor lightGrayColor];
			cell.taskDueDate.font = [UIFont systemFontOfSize:13];
		}
		
		cell.delegate = self;
		
		if (task.isComplete)
			[cell.completedButton setSelected:YES];
		else
			[cell.completedButton setSelected:NO];
		
		UIColor * bgColor;
		switch (task.taskPriority.intValue) {
			case 3:		bgColor = [UIColor redColor];		break;
			case 2:		bgColor = [UIColor orangeColor];	break;
			case 1:		bgColor = [UIColor lightGrayColor];	break;
			case 0:		bgColor = [UIColor clearColor];		break;
		}
		
		cell.taskPriority.backgroundColor = bgColor;
		
		return cell;
	} else {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Empty" forIndexPath:indexPath];
		
		return cell;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tasks.count >= 1) {
		CGFloat cellHeight = 70;
		
		Task * task = tasks[indexPath.row];
		
		if (task.taskDescription) {
			cellHeight += [self heightForLabelWithString:task.taskDescription];
		}
		
		return cellHeight;
	}
	else {
		return tableView.rowHeight;
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Task * task = [tasks objectAtIndex:indexPath.row];
        task.hasBeenDeleted = YES;
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Can't Delete! %@ %@", error, [error localizedDescription]);
            return;
        }
        
        [tasks removeObjectAtIndex:indexPath.row];
		if (tasks.count >= 1)
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
		else
			[self.tableView reloadData];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NewTask * controller = (NewTask*)[self.storyboard instantiateViewControllerWithIdentifier:@"EditTask"];
	controller.task = tasks[indexPath.row];
	
	[self.navigationController pushViewController:controller animated:YES];
}

- (CGFloat)heightForLabelWithString:(NSString*)string
{
	CGFloat horizontalPadding = 82;
    CGFloat widthOfTextView = self.tableView.frame.size.width - horizontalPadding;
	
	UIFont *font = [UIFont systemFontOfSize:14];
	NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName: font}];
	CGRect rect = [attributedText boundingRectWithSize:(CGSize){widthOfTextView, CGFLOAT_MAX}
											   options:NSStringDrawingUsesLineFragmentOrigin
											   context:nil];
	CGFloat height = rect.size.height;
    
	return height;
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	_reloading = YES;
	[self syncData];
}

- (void)endRefreshing{
	_reloading = NO;
	[_refreshHeader refreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}


#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	[_refreshHeader refreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	[_refreshHeader refreshScrollViewDidEndDragging:scrollView];
}


#pragma mark -
#pragma mark RefreshTableHeaderDelegate Methods

- (void)refreshTableHeaderDidTriggerRefresh:(RefreshTableHeader*)view{
	[self reloadTableViewDataSource];
}

- (BOOL)refreshTableHeaderDataSourceIsLoading:(RefreshTableHeader*)view{
	return _reloading;
}

- (NSDate*)refreshTableHeaderDataSourceLastUpdated:(RefreshTableHeader*)view{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"LastSyncDate"];
}

@end
