//
//  Register.m
//  2Do
//
//  Created by Robin Crorie on 16/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import "Register.h"
#import "LoadingScreen/Loading.h"
#import "SoapTool.h"
#import "User.h"

@interface Register () <UIScrollViewDelegate, UITextFieldDelegate>
{
	UITextField * activeField;
	Loading * loading;
	
	IBOutlet UIScrollView * scrollView;
	IBOutlet UITextField * emailAddress;
	IBOutlet UITextField * password;
	IBOutlet UITextField * passwordConfirm;
}

@end

@implementation Register

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
	
	[self styleTextFields:self.view];
	
	loading = [Loading alloc];
    
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
	textField.layer.borderColor=[[UIColor clearColor]CGColor];
	activeField = textField;
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

- (void)dismissKeyboard {
	[activeField resignFirstResponder];
}

- (IBAction)registerUser:(id)sender
{
	[loading show];
	
	BOOL validationError = NO;
	if (emailAddress.text.length == 0) {
		validationError = YES;
		emailAddress.layer.masksToBounds=YES;
		emailAddress.layer.borderColor=[[UIColor redColor]CGColor];
		emailAddress.layer.borderWidth= 1.0f;
	}
	if (password.text.length == 0) {
		validationError = YES;
		password.layer.masksToBounds=YES;
		password.layer.borderColor=[[UIColor redColor]CGColor];
		password.layer.borderWidth= 1.0f;
	}
	if (passwordConfirm.text.length == 0) {
		validationError = YES;
		passwordConfirm.layer.masksToBounds=YES;
		passwordConfirm.layer.borderColor=[[UIColor redColor]CGColor];
		passwordConfirm.layer.borderWidth= 1.0f;
	}
	
	if (validationError) {
		[loading hide];
		UIAlertView * validationAlert = [[UIAlertView alloc] initWithTitle:@"Oops.." message:@"You must complete all the fields" delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
		[validationAlert show];
	}
	else {
		if ([password.text isEqualToString:passwordConfirm.text]) {
			dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				NSError * error = nil;
				int userId = [SoapTool createUserAccount:emailAddress.text password:password.text error:&error];
				
				dispatch_async( dispatch_get_main_queue(), ^{
					if (!error && userId) {
						
						AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
						NSManagedObjectContext *context = [appDelegate managedObjectContext];
						
						User * newUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
						newUser.userId = [NSNumber numberWithInt:userId];
						newUser.email = emailAddress.text;
						newUser.password = password.text;
						NSError * error = nil;
						[context save:&error];
						
						NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
						[defaults setValue:[NSString stringWithFormat:@"%d", userId] forKey:@"UserId"];
						[defaults setValue:emailAddress.text forKey:@"UserEmail"];
						[defaults synchronize];
						
						[self performSegueWithIdentifier:@"MainView" sender:self];
					} else {
						UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Oops..." message:@"Email address or password is incorrect" delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles: nil];
						[alert show];
					}
					[loading hide];
				});
			});
		}
		else {
			[loading hide];
			UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Oops..." message:@"Your passwords do not match!" delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
			[alert show];
		}
	}
}
	
- (IBAction)cancelButton:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
