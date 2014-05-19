//
//  Login.m
//  2Do
//
//  Created by Robin Crorie on 16/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import "Login.h"
#import "AppDelegate.h"
#import "LoadingScreen/Loading.h"
#import "SoapTool/SoapTool.h"
#import "User.h"

@interface Login () <UITextFieldDelegate, UIScrollViewDelegate>
{
	UITextField * activeField;
	Loading * loading;
	NSManagedObjectContext *context;
	NSMutableArray * users;
	
	IBOutlet UIScrollView * scrollView;
	IBOutlet UITextField * emailAddress;
	IBOutlet UITextField * password;
	IBOutlet UIButton * registerButton;
}

@end

@implementation Login

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	loading = [Loading sharedInstance];
	
	[self styleTextFields:self.view];
	
	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"UserEmail"]) {
		emailAddress.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"UserEmail"];
	}
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
								   initWithTarget:self
								   action:@selector(dismissKeyboard)];
	
	[self.view addGestureRecognizer:tap];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
										  selector:@selector(keyboardDidShow:)
										  name: UIKeyboardWillShowNotification
										  object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
										  selector:@selector(keyboardDidHide:)
										  name: UIKeyboardWillHideNotification
										  object:nil];
}

- (void)styleTextFields:(UIView*)view {
	
    for(id currentView in [view subviews]){
        if([currentView isKindOfClass:[UITextField class]]) {
			UITextField * currentField = currentView;
            // Change value of CGRectMake to fit ur need
            [currentView setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)]];
            [currentView setLeftViewMode:UITextFieldViewModeAlways];
			currentField.layer.masksToBounds=YES;
			currentField.layer.borderColor=[[UIColor lightGrayColor] CGColor];
			currentField.layer.borderWidth= 1.0f;
			currentField.tintColor = [UIColor lightGrayColor];
			currentField.delegate = self;
        }
		
        if([currentView respondsToSelector:@selector(subviews)]){
            [self styleTextFields:currentView];
        }
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	activeField = textField;
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSInteger nextTag = textField.tag + 1;
	UIResponder * nextResponder = [textField.superview viewWithTag:nextTag];
	
	if (nextResponder) {
		[nextResponder becomeFirstResponder];
	} else {
		[textField resignFirstResponder];
	}
	
	if (textField.returnKeyType == 9) {
		[self checkLogin];
	}
	
	return YES;
}

- (void)keyboardDidShow:(NSNotification *)notif
{
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	CGSize keyboardSize = [[[notif userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
	if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight ) {
		CGSize origKeySize = keyboardSize;
		keyboardSize.height = origKeySize.width;
		keyboardSize.width = origKeySize.height;
	}
	
	UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0);
	scrollView.contentInset = contentInsets;
	scrollView.scrollIndicatorInsets = contentInsets;
	CGRect rect = scrollView.frame;
	rect.size.height -= keyboardSize.height;
	CGRect activeFieldRect = activeField.frame;
	activeFieldRect.origin.y += activeField.superview.frame.origin.y;
	CGPoint point = CGPointMake(activeField.frame.origin.x, activeFieldRect.origin.y - scrollView.contentOffset.y);
	if (!CGRectContainsPoint(rect, point)) {
		CGPoint point = CGPointMake(0, (activeField.frame.origin.y + activeField.superview.frame.origin.y) - keyboardSize.height);
		[scrollView setContentOffset:point animated:YES];
	}
}

- (void)keyboardDidHide:(NSNotification *)notif
{
	UIEdgeInsets zeroInsets = UIEdgeInsetsZero;
    [scrollView setContentInset:zeroInsets];
    scrollView.scrollIndicatorInsets = zeroInsets;
}

- (void)checkLogin
{
	[loading show:self.view.frame];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	
	context = [appDelegate managedObjectContext];
	
	NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
	
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"email = %@", emailAddress.text];
    [request setPredicate:pred];
	
	NSError * error = nil;
	users = [NSMutableArray arrayWithArray:[context executeFetchRequest:request error:&error]];
	
	if (users.count >= 1) {
		for (User * user in users) {
			if ([user.password isEqualToString:password.text]) {
				[defaults setValue:[NSString stringWithFormat:@"%@", user.userId] forKey:@"UserId"];
				[defaults setValue:user.email forKey:@"UserEmail"];
				[defaults synchronize];
				[self performSegueWithIdentifier:@"MainView" sender:self];
				[loading hide];
				NSLog(@"Found user locally and password matched");
				return;
			}
			else {
				UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Oops..." message:@"Email address or password is incorrect" delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles: nil];
				[alert show];
				[loading hide];
				NSLog(@"Found user locally and password did NOT match");
				return;
			}
		}
	}
	else {
		dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSError * error = nil;
			int userId = [SoapTool checkPassword:password.text email:emailAddress.text error:&error];
		
			dispatch_async( dispatch_get_main_queue(), ^{
				if (!error && userId) {
					User * newUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
					newUser.userId = [NSNumber numberWithInt:userId];
					newUser.email = emailAddress.text;
					newUser.password = password.text;
					NSError * error = nil;
					[context save:&error];
					
					[defaults setValue:[NSString stringWithFormat:@"%d", userId] forKey:@"UserId"];
					[defaults setValue:emailAddress.text forKey:@"UserEmail"];
					[defaults synchronize];
					
					[self performSegueWithIdentifier:@"MainView" sender:self];
				} else {
					NSLog(@"%ld", (long)error.code);
					NSLog(@"%@", error.localizedDescription);
					UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Oops..." message:@"Email address or password is incorrect" delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles: nil];
					[alert show];
				}
				[loading hide];
			});
		});
	}
}

- (void)dismissKeyboard {
	[activeField resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
- (BOOL)shouldAutorotate {
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return UIInterfaceOrientationMaskLandscape;
	} else {
		return UIInterfaceOrientationMaskPortrait;
	}
}

@end
