//
//  NCStackEditorViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/11/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import <Cocoa/Cocoa.h>

@protocol NCStackEditorEntryDelegate;

typedef enum : NSUInteger {
    StackEditorEntryStyleClassic,
    StackEditorEntryStyleModern
} NCStackEditorEntryStyle;

@interface NCStackEditorEntryViewController : NSViewController

@property (nonatomic, weak) id<NCStackEditorEntryDelegate> delegate;
@property (nonatomic) NSString *caption;
@property (weak) IBOutlet NSViewController *contentViewController;
@property (weak, readonly) IBOutlet NSTextField *captionLabel;
@property (nonatomic, readonly) NCStackEditorEntryStyle style;

@property (nonatomic) BOOL isHighlighted;

-(id)initWithStyle:(NCStackEditorEntryStyle)style;
-(void)setHeaderSmall:(BOOL)isHeaderSmall;

@end

@protocol NCStackEditorEntryDelegate <NSObject>

@optional
-(void)stackEditorEntryViewControllerDidClosed:(NCStackEditorEntryViewController*)vc;
-(void)stackEditorEntryViewControllerUpdatedFrame:(NCStackEditorEntryViewController*)vc;

@end
