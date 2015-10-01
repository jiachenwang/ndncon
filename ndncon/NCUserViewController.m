//
//  NCUserViewController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCUserViewController.h"
#import "NCStreamEditorViewController.h"
#import "NCPreferencesController.h"
#import "NSScrollView+NCAdditions.h"
#import "NCUserStreamViewController.h"
#import "NSObject+NCAdditions.h"
#import "NCNdnRtcLibraryController.h"
#import "NCStreamViewerController.h"
#import "NCChatLibraryController.h"
#import "NSString+NCAdditions.h"

#define PUBLISH_CUSTOM_AUDIO_ONLY_IDX 1
#define PUBLISH_CUSTOM_VIDEO_ONLY_IDX 2

@interface NCUserViewController ()

@property (weak) IBOutlet NSScrollView *scrollView;
@property (nonatomic) NCStreamViewerController *streamEditorController;
@property (weak) IBOutlet NSButton *fetchAllButton;
@property (weak) IBOutlet NSButton *fetchAudioOnlyButton;
@property (nonatomic) BOOL isChatVisible;

@property (weak) IBOutlet NSButton *chatButton;
@property (weak) IBOutlet NSButton *publishingInfoButton;

@end

@implementation NCUserViewController

- (IBAction)fetchAll:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(userViewControllerFetchStreamsClicked:)])
        [self.delegate userViewControllerFetchStreamsClicked:self];
}

- (IBAction)showChat:(id)sender {
    self.publishingInfoButton.state = !self.chatButton.state;
    self.isChatVisible = !self.isChatVisible;
}

- (IBAction)showPublishingInfo:(id)sender
{
    self.chatButton.state = !self.publishingInfoButton.state;
    self.isChatVisible = !self.isChatVisible;
}

- (IBAction)fetchCustom:(id)sender {
    if ([[sender itemArray] indexOfObject:[sender selectedItem]] == PUBLISH_CUSTOM_AUDIO_ONLY_IDX)
    {
        NSMutableDictionary *customUserInfo = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
        customUserInfo[kSessionInfoKey] = [NCSessionInfoContainer audioOnlyContainerWithSessionInfo:[self.userInfo[kSessionInfoKey] sessionInfo]];
        
        [self.delegate userViewController:self
               fetchStreamsWithCustomInfo:customUserInfo];
    }
    
    if ([[sender itemArray] indexOfObject:[sender selectedItem]] == PUBLISH_CUSTOM_VIDEO_ONLY_IDX)
    {
        NSMutableDictionary *customUserInfo = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
        customUserInfo[kSessionInfoKey] = [NCSessionInfoContainer videoOnlyContainerWithSessionInfo:[self.userInfo[kSessionInfoKey] sessionInfo]];
        
        [self.delegate userViewController:self
               fetchStreamsWithCustomInfo:customUserInfo];
    }
    
}

-(id)init
{
    self = [super initWithNibName:@"NCUserView" bundle:nil];
    
    if (self)
    {
        self.streamEditorController = [[NCStreamViewerController alloc] init];
        self.chatViewController = [[NCChatViewController alloc] init];
        self.statusImage = [[NCNdnRtcLibraryController sharedInstance]
                            imageForSessionStatus:SessionStatusOffline];

        [self subscribeForNotificationsAndSelectors:
         NCRemoteSessionStatusUpdateNotification, @selector(onRemoteSessionStatusUpdate:),
         nil];
    }
    
    return self;
}

-(void)dealloc
{
    [self unsubscribeFromNotifications];
}

-(void)awakeFromNib
{
    [self.scrollView addStackView:self.streamEditorController.stackView
                  withOrientation:NSUserInterfaceLayoutOrientationVertical];
    [self.streamEditorController awakeFromNib];

    [self updateUiForUserInfo:self.userInfo];
    [self presentView:self.scrollView];
    
    if (self.userInfo && !self.chatViewController.chatRoomId)
    {
        // user prefix is not the same as session prefix!
        // example session prefix:
        //    /ndn/edu/ucla/remap/ndnrtc/user/alex
        // example user prefix:
        //    /ndn/edu/ucla/remap/alex
        NSString *userPrefix = [NSString stringWithFormat:@"%@/%@",
                                [self.userInfo[kSessionPrefixKey] getNdnRtcHubPrefix],
                                [self.userInfo[kSessionPrefixKey] getNdnRtcUserName]];
        [self joinChatRoomForUserPrefix:userPrefix];
    }
}

-(void)setUserInfo:(NSDictionary *)userInfo
{
    _userInfo = userInfo;
    self.streamEditorController.userName = [userInfo valueForKey:kSessionUsernameKey];
    self.streamEditorController.userPrefix = [userInfo valueForKey:kHubPrefixKey];
    [self updateUiForUserInfo:userInfo];
    
    if (!self.chatViewController.chatRoomId)
    
    {
        NSString *userPrefix = [NSString stringWithFormat:@"%@/%@",
                                self.userInfo[kHubPrefixKey],
                                self.userInfo[kSessionUsernameKey]];
        [self joinChatRoomForUserPrefix:userPrefix];
    }
}

-(void)setSessionInfo:(NCSessionInfoContainer *)sessionInfo
{
    if (![_sessionInfo isEqual:sessionInfo] &&
        !(sessionInfo == _sessionInfo))
    {
        _sessionInfo = sessionInfo;
        [self updateStreams];
    }
}

// private
-(void)updateUiForUserInfo:(NSDictionary*)userInfo
{
    NCSessionStatus status = [[userInfo valueForKey:kSessionStatusKey] integerValue];
    [self.fetchAllButton setEnabled:(status == SessionStatusOnlinePublishing)];
    
    NCSessionInfoContainer *sessionInfo = [userInfo valueForKey:kSessionInfoKey];
    [self.fetchAudioOnlyButton setEnabled:(status == SessionStatusOnlinePublishing) && sessionInfo.audioStreamsConfigurations.count > 0];
    
    self.statusImage = [[NCNdnRtcLibraryController sharedInstance]
                        imageForSessionStatus:status];
    self.isChatVisible = NO;
    self.chatViewController.isActive = (status != SessionStatusOffline);
    self.chatViewController.chatInfoTextField.stringValue = [NSString stringWithFormat:@"Chat with %@:", userInfo[kSessionUsernameKey]];
}

-(void)joinChatRoomForUserPrefix:(NSString*)userPrefix
{
//    self.chatViewController.chatRoomId = [[NCChatLibraryController sharedInstance] startChatWithUser:userPrefix];
}

-(void)setIsChatVisible:(BOOL)isChatVisible
{
    if (_isChatVisible != isChatVisible)
    {
        _isChatVisible = isChatVisible;
        if (_isChatVisible)
        {
            [self.scrollView removeFromSuperview];
            [self presentView: self.chatViewController.view];
        }
        else
        {
            [self.chatViewController.view removeFromSuperview];
            [self presentView: self.scrollView];
        }
    }
}

-(void)presentView:(NSView*)view
{
    [self.view addSubview:view];
    
    NSButton *button = self.chatButton;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(view)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(view)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[button]-4-[view]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(button, view)]];
}

-(void)updateStreams
{
    [self.streamEditorController setAudioStreams:[NSMutableArray arrayWithArray: [self.sessionInfo audioStreamsConfigurations]]
                                 andVideoStreams:[NSMutableArray arrayWithArray:[self.sessionInfo videoStreamsConfigurations]]];
}

-(void)onRemoteSessionStatusUpdate:(NSNotification*)notification
{
    if ([[self.userInfo objectForKey:kSessionPrefixKey]
         isEqualTo:[notification.userInfo objectForKey:kSessionPrefixKey]])
    {
        self.userInfo = notification.userInfo;
        self.sessionInfo = [self.userInfo valueForKey:kSessionInfoKey];
    }
}

@end

@interface NCSessionStatusTransformer : NSValueTransformer
@end

@implementation NCSessionStatusTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

-(id)transformedValue:(id)value
{
    NCSessionStatus status = [value intValue];
    
    switch (status) {
        case SessionStatusOnlineNotPublishing:
            return @"online, not publishing";
        case SessionStatusOnlinePublishing:
            return @"publishing";
        default:
            return @"offline";
    }
}

@end