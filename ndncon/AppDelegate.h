//
//  AppDelegate.h
//  NdnCon
//
//  Created by Peter Gusev on 9/8/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

#import "MASPreferencesWindowController.h"
#import "NCPreferencesController.h"

@interface AppDelegate : NSObject
<NSApplicationDelegate, SUUpdaterDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) MASPreferencesWindowController* preferencesWindowController;
@property (nonatomic, readonly) NCPreferencesController *preferences;

- (IBAction)saveAction:(id)sender;
- (BOOL)commitManagedContext;

@end
