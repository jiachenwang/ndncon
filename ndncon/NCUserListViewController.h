//
//  NCUserListViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCNdnRtcLibraryController.h"
#import "NCChatViewController.h"
#import "NCSessionInfoContainer.h"

extern NSString* const kSessionInfoKey;
extern NSString* const kHubPrefixKey;

@class User;

//******************************************************************************
@protocol NCUserListViewControllerDelegate;

@interface NCUserListViewController : NSViewController
<NSTableViewDelegate, NSTableViewDataSource,
NCChatViewControllerDelegate, NSUserNotificationCenterDelegate>

@property (nonatomic, weak) IBOutlet id<NCUserListViewControllerDelegate> delegate;

+(NCUserListViewController *)sharedInstance;
+(NCSessionStatus)sessionStatusForUser:(NSString*)user
                withPrefix:(NSString*)prefix;

-(void)clearSelection;
-(NSDictionary*)userInfoDictionaryForUser:(NSString*)userName
                               withPrefix:(NSString*)prefix;
-(void)updateCellBadgeNumber:(NSUInteger)number
             forCellWithUser:(User*)user;

@end

//******************************************************************************
@protocol NCUserListViewControllerDelegate <NSObject>

@optional
-(void)userListViewController:(NCUserListViewController*)userListViewController
                userWasChosen:(NSDictionary*)user;
-(void)userListViewControllerUserListUpdated:(NCUserListViewController*)userListViewController;

@end
