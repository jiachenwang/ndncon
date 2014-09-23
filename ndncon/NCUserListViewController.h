//
//  NCUserListViewController.h
//  NdnCon
//
//  Created by Peter Gusev on 9/17/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const kNCSessionInfoKey;
extern NSString* const kNCHubPrefixKey;

@interface NCSessionInfoContainer : NSObject

+(NCSessionInfoContainer*)containerWithSessionInfo:(void*)sessionInfo;
-(id)initWithSessionInfo:(void*)sessionInfo;
-(void*)sessionInfo;

@end

@interface NCUserListViewController : NSObject

@end