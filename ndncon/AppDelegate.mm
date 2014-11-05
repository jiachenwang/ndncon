//
//  AppDelegate.m
//  NdnCon
//
//  Created by Peter Gusev on 9/8/14.
//  Copyright (c) 2014 REMAP. All rights reserved.
//

#import "AppDelegate.h"

#import "NCNdnRtcLibraryController.h"
#import "NCAdvancedPreferencesViewController.h"
#import "NCGeneralPreferencesViewController.h"
#import "NSObject+NCAdditions.h"
#import "NCErrorController.h"
#import "User.h"
#import "NCChatLibraryController.h"
#import "NCDiscoveryLibraryController.h"
#import "NCPreferencesController.h"

@interface AppDelegate()

@end

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

+(void)initialize
{
    [NCPreferencesController sharedInstanceWithDefaultsFile:@"settings"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NCPreferencesController sharedInstance] updateDefaults];
    [self.window setTitle:[NSString stringWithFormat:@"%@ v%@",
                           [NCPreferencesController sharedInstance].appName,
                           [NCPreferencesController sharedInstance].versionString]];
    
    if ([NCPreferencesController sharedInstance].isFirstLaunch)
    {
        NSLog(@"First launch indeed!");
        [NCPreferencesController sharedInstance].firstLaunch = NO;
        [self addTestUsers];
    }
    else
        NSLog(@"Not a first launch. We're friends already...");
    
    [[NCNdnRtcLibraryController sharedInstance] startSession];
    [NCChatLibraryController sharedInstance];
    [NCDiscoveryLibraryController sharedInstance];
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "ucla.edu.NdnCon" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"ucla.edu.NdnCon"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NdnCon" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"NdnCon.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    // enable automatic data model migration
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType
                                   configuration:nil URL:url
                                         options:options error:&error])
    {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [[NCChatLibraryController sharedInstance] leaveAllChatRooms];
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![self commitManagedContext])
        return NSTerminateCancel;
    
    return NSTerminateNow;
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

-(IBAction)showPreferences:(id)sender
{
    if (self.preferencesWindowController != nil)
        self.preferencesWindowController = nil;
    
    if (self.preferencesWindowController == nil)
    {
        NSViewController *generalViewController = [[NCGeneralPreferencesViewController alloc] init];
        NSViewController *advancedViewController = [[NCAdvancedPreferencesViewController alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, advancedViewController, nil];
        
        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        self.preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
    }
    
    [self.preferencesWindowController showWindow:nil];
}

-(NCPreferencesController *)preferences
{
    return [NCPreferencesController sharedInstance];
}

-(BOOL)commitManagedContext
{
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NO;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return YES;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NO;
        }
    }
    
    return YES;
}

//******************************************************************************
-(void)addTestUsers
{
    NSEntityDescription *userEntity = [[self.managedObjectModel entitiesByName] objectForKey:@"User"];
    User *remapUser = [[User alloc] initWithEntity:userEntity
                    insertIntoManagedObjectContext:self.managedObjectContext];
    remapUser.name = @"remap";
    remapUser.prefix = @"/ndn/edu/ucla/remap";
    
    User *remapUser2 = [[User alloc] initWithEntity:userEntity
                    insertIntoManagedObjectContext:self.managedObjectContext];
    remapUser2.name = @"remap2";
    remapUser2.prefix = @"/ndn/edu/ucla/remap";
}

@end

