//
//  NCUserViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCUserListViewController.h"
#import "NCChatViewController.h"

@protocol NCUserViewControllerDelegate;

@interface NCUserViewController : NSViewController

@property (nonatomic, weak) id<NCUserViewControllerDelegate> delegate;

@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *prefix;

@property (nonatomic) NCSessionInfoContainer *sessionInfo;
@property (nonatomic) NSDictionary *userInfo;
@property (nonatomic) NSImage *statusImage;
@property (nonatomic) NCChatViewController *chatViewController;

@end


@protocol NCUserViewControllerDelegate <NSObject>

@optional
-(void)userViewControllerFetchStreamsClicked:(NCUserViewController*)userVc;
-(void)userViewController:(NCUserViewController *)userVc
fetchStreamsWithCustomInfo:(NSDictionary *)customUSerInfo;

@end