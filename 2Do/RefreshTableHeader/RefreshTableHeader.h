//
//  RefreshTableHeader.h
//  2Do
//
//  Created by Robin Crorie on 18/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef enum{
	PullRefreshPulling = 0,
	PullRefreshNormal,
	PullRefreshLoading,
} PullRefreshState;

@protocol RefreshTableHeaderDelegate;
@interface RefreshTableHeader : UIView {
	
	__unsafe_unretained id _delegate;
	PullRefreshState _state;

	UILabel *_lastUpdatedLabel;
	UILabel *_statusLabel;
	CALayer *_syncImage;
	UIActivityIndicatorView *_activityView;
	

}

@property(nonatomic,assign) id <RefreshTableHeaderDelegate> delegate;

- (void)refreshLastUpdatedDate;
- (void)refreshScrollViewDidScroll:(UIScrollView *)scrollView;
- (void)refreshScrollViewDidEndDragging:(UIScrollView *)scrollView;
- (void)refreshScrollViewDataSourceDidFinishedLoading:(UIScrollView *)scrollView;

@end
@protocol RefreshTableHeaderDelegate
- (void)refreshTableHeaderDidTriggerRefresh:(RefreshTableHeader*)view;
- (BOOL)refreshTableHeaderDataSourceIsLoading:(RefreshTableHeader*)view;
@optional
- (NSDate*)refreshTableHeaderDataSourceLastUpdated:(RefreshTableHeader*)view;
@end
