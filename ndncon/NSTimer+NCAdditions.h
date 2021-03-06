//
//  NSTimer+PTNAdditions.h
//  PTNAdditions
//
//  Created by Peter Gusev on 1/29/13.
//  Copyright 2013-2015 Regents of the University of California
//

#import <Foundation/Foundation.h>

typedef void (^NCTimerBlock)(NSTimer*);

@interface NSTimer (NCAdditions)

+(NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo fireBlock:(NCTimerBlock)block;
+(NSTimer*)timerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo fireBlock:(NCTimerBlock)block;

@end
