//
//  NCConversationInfoView.m
//  NdnCon
//
//  Created by Peter Gusev on 9/23/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "NCConversationInfoView.h"
#import "NSString+NCAdditions.h"

@interface NCConversationInfoView()

@end

@implementation NCConversationInfoView

-(id)init
{
    self = [super init];
    
    if (self)
        [self initialize];
    
    return self;
}

-(id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self)
        [self initialize];
    
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
        [self initialize];
    
    return self;
}

-(void)initialize
{
    self.status = NCConversationInfoStatusOffline;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] set];

    NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.bounds];
    [path fill];
    
    CGFloat inset1 = 1., inset2 = 3;
    NSBezierPath *insetPath1 = [NSBezierPath bezierPathWithRect:NSInsetRect(self.bounds, inset1, inset1)];
    NSBezierPath *insetPath2 = [NSBezierPath bezierPathWithRect:NSInsetRect(self.bounds, inset2, inset2)];
    
    switch (self.status) {
        case NCConversationInfoStatusOnlineNotPublishing:
            [[NSColor colorWithRed:109./255. green:161./255. blue:239./255. alpha:1.] set];
            break;
        case NCConversationInfoStatusOnline:
            [[NSColor colorWithRed:109./255. green:239./255. blue:155./255. alpha:1.] set];
            break;
        default:
            [[NSColor colorWithWhite:0.8 alpha:1.] set];
            break;
    }

    [insetPath1 stroke];
    [insetPath2 fill];
}

@end
