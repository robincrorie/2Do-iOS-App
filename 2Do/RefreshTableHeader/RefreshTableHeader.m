//
//  RefreshTableHeader.m
//  2Do
//
//  Created by Robin Crorie on 18/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import "RefreshTableHeader.h"


#define TEXT_COLOR	 [UIColor darkGrayColor]
#define FLIP_ANIMATION_DURATION 0.18f


@interface RefreshTableHeader (Private)
- (void)setState:(PullRefreshState)aState;
@end

@implementation RefreshTableHeader

@synthesize delegate=_delegate;


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor whiteColor];

		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 30.0f, self.frame.size.width, 20.0f)];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		label.font = [UIFont systemFontOfSize:12.0f];
		label.textColor = TEXT_COLOR;
		label.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		label.shadowOffset = CGSizeMake(0.0f, 1.0f);
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = NSTextAlignmentCenter;
		[self addSubview:label];
		_lastUpdatedLabel=label;
		
		label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 48.0f, self.frame.size.width, 20.0f)];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		label.font = [UIFont boldSystemFontOfSize:13.0f];
		label.textColor = TEXT_COLOR;
		label.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		label.shadowOffset = CGSizeMake(0.0f, 1.0f);
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = NSTextAlignmentCenter;
		[self addSubview:label];
		_statusLabel=label;
		
		CALayer *layer = [CALayer layer];
		layer.frame = CGRectMake(20.0f, frame.size.height - 45.0f, 30.0f, 30.0f);
		layer.contentsGravity = kCAGravityResizeAspect;
		layer.contents = (id)[UIImage imageNamed:@"SyncIcon"].CGImage;
		
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
			layer.contentsScale = [[UIScreen mainScreen] scale];
		}
#endif
		
		[[self layer] addSublayer:layer];
		_syncImage=layer;
		
		UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		view.frame = CGRectMake(25.0f, frame.size.height - 38.0f, 20.0f, 20.0f);
		[self addSubview:view];
		_activityView = view;
		
		
		[self setState:PullRefreshNormal];
		
    }
	
    return self;
	
}


#pragma mark -
#pragma mark Setters

- (void)refreshLastUpdatedDate {
	
	if ([_delegate respondsToSelector:@selector(refreshTableHeaderDataSourceLastUpdated:)]) {
		
		NSDate *date = [_delegate refreshTableHeaderDataSourceLastUpdated:self];
		
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setAMSymbol:@"am"];
		[formatter setPMSymbol:@"pm"];
		[formatter setDateFormat:@"dd MMM yyyy hh:mm a"];
		if (date) {
			_lastUpdatedLabel.text = [NSString stringWithFormat:@"Last Sync: %@", [formatter stringFromDate:date]];
		}
		else {
			_lastUpdatedLabel.text = @"Not Synchronised";
		}
	} else {
		_lastUpdatedLabel.text = @"Not Synchronised";
	}
}

- (void)setState:(PullRefreshState)aState{
	
	switch (aState) {
		case PullRefreshPulling:
			_statusLabel.text = @"Release to sync...";
			break;
		case PullRefreshNormal:
			
			if (_state == PullRefreshPulling) {
				[CATransaction begin];
				[CATransaction setAnimationDuration:FLIP_ANIMATION_DURATION];
				_syncImage.transform = CATransform3DIdentity;
				[CATransaction commit];
			}
			
			_statusLabel.text = @"Pull down to sync...";
			[_activityView stopAnimating];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions]; 
			_syncImage.hidden = NO;
			_syncImage.transform = CATransform3DIdentity;
			[CATransaction commit];
			
			[self refreshLastUpdatedDate];
			
			break;
		case PullRefreshLoading:
			
			_statusLabel.text = @"Synchronising...";
			[CATransaction begin];
			
			CABasicAnimation *anim1 = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
			anim1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
			anim1.fromValue = [NSNumber numberWithFloat:0];
			anim1.toValue = [NSNumber numberWithFloat:((360*M_PI)/180)];
			anim1.repeatCount = HUGE_VALF;
			anim1.duration = 0.6;
			
			[_syncImage addAnimation:anim1 forKey:@"transform"];
			
			[CATransaction commit];
			
			break;
		
	}
	
	_state = aState;
}


#pragma mark -
#pragma mark ScrollView Methods

- (void)refreshScrollViewDidScroll:(UIScrollView *)scrollView {
	
	if (_state == PullRefreshLoading) {
		
		CGFloat offset = MAX(scrollView.contentOffset.y * -1, 0);
		offset = MIN(offset, 60);
		scrollView.contentInset = UIEdgeInsetsMake(offset, 0.0f, 0.0f, 0.0f);
		
	} else if (scrollView.isDragging) {
		
		BOOL _loading = NO;
		if ([_delegate respondsToSelector:@selector(refreshTableHeaderDataSourceIsLoading:)]) {
			_loading = [_delegate refreshTableHeaderDataSourceIsLoading:self];
		}
		
		if (_state == PullRefreshPulling && scrollView.contentOffset.y > -65.0f && scrollView.contentOffset.y < 0.0f && !_loading) {
			[self setState:PullRefreshNormal];
		} else if (_state == PullRefreshNormal && scrollView.contentOffset.y < -65.0f && !_loading) {
			
			[self setState:PullRefreshPulling];
		}
		
		if (scrollView.contentInset.top != 0) {
			scrollView.contentInset = UIEdgeInsetsZero;
		}
		
	}
	
	if (_state != PullRefreshLoading) {
		[CATransaction begin];
		[CATransaction setAnimationDuration:0];
		_syncImage.transform = CATransform3DMakeRotation(scrollView.contentOffset.y / 20, 0.0f, 0.0f, 1.0f);
		[CATransaction commit];
	}
	
}

- (void)refreshScrollViewDidEndDragging:(UIScrollView *)scrollView {
	
	BOOL _loading = NO;
	if ([_delegate respondsToSelector:@selector(refreshTableHeaderDataSourceIsLoading:)]) {
		_loading = [_delegate refreshTableHeaderDataSourceIsLoading:self];
	}
	
	if (scrollView.contentOffset.y <= - 65.0f && !_loading) {
		
		if ([_delegate respondsToSelector:@selector(refreshTableHeaderDidTriggerRefresh:)]) {
			[_delegate refreshTableHeaderDidTriggerRefresh:self];
		}
		
		[self setState:PullRefreshLoading];
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2];
		scrollView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f, 0.0f);
		[UIView commitAnimations];
		
	}
	
}

- (void)refreshScrollViewDataSourceDidFinishedLoading:(UIScrollView *)scrollView {
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.3];
	[scrollView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
	[UIView commitAnimations];
	
	[self setState:PullRefreshNormal];
}

@end
