//
//  NCStreamViewerController.m
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCStreamBrowserController.h"
#import "NCStreamViewController.h"

NSString* const kLocalUserName = @"local";
NSString* const kUserNameKey = @"user";
NSString* const kStreamPrefixKey = @"streamPrefix";
NSString* const kPreviewControllerKey = @"previewController";

@interface NCStreamBrowserController ()

@property (nonatomic) NSMutableDictionary *userPreviewControllers;

@end

@implementation NCStreamBrowserController

-(void)initialize
{
    [super initialize];
    self.userPreviewControllers = [[NSMutableDictionary alloc] init];
}

-(NCStreamPreviewController*)addStreamWithConfiguration:(NSDictionary *)configuration
                                  andStreamPreviewClass:(Class)streamPreviewClass
                                         forStreamPrefix:(NSString*)streamPrefix
{
    NCStreamPreviewController *streamPreviewController = [[streamPreviewClass alloc] init];
    streamPreviewController.streamName = [configuration valueForKeyPath:kNameKey];
    
    NCStackEditorEntryViewController *vc = [self addViewEntry:streamPreviewController.view withStyle:StackEditorEntryStyleModern];
    [vc setHeaderSmall:YES];
    vc.caption = [configuration valueForKey:kNameKey];
    
    [self.userPreviewControllers setObject:@{kUserNameKey:kLocalUserName,
                                             kPreviewControllerKey:streamPreviewController}
                                    forKey:streamPrefix];
    return streamPreviewController;
}

// NCStackEditorEntryDelegate
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController *)vc
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamBrowserController:streamWasClosed:forUser:forPrefix:)])
    {
        NCStreamPreviewController *streamPreviewController = nil;
        NSString *userName = nil;
        NSString *streamPrefix = nil;
        
        for (NSString *key in self.userPreviewControllers.allKeys)
        {
            NSDictionary *info = [self.userPreviewControllers objectForKey:key];
            
            if ([(NSViewController*)[info objectForKey:kPreviewControllerKey] view] == vc.contentView)
            {
                streamPreviewController = [info objectForKey:kPreviewControllerKey];
                userName =  [info objectForKey:kUserNameKey];
                streamPrefix = key;
                break;
            }
        }
        
        [self.delegate streamBrowserController:self
                               streamWasClosed:streamPreviewController
                                       forUser:userName
                                     forPrefix:streamPrefix];
    }
    
    [super stackEditorEntryViewControllerDidClosed:vc];
}

@end