//
//  AppDelegate.m
//  partay
//
//  Created by Per on 1/4/15.
//  Copyright (c) 2015 Per. All rights reserved.
//

#import "AppDelegate.h"
#import "MapViewController.h"

#import <ParseCrashReporting/ParseCrashReporting.h>
#import <CoreData/CoreData.h>
#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <GoogleMaps/GoogleMaps.h>
#import "Constants.h"
#import <Reachability.h>
#import "ReachabilityManager.h"

@interface AppDelegate ()

@property (nonatomic, strong) UIStoryboard *storyboard;
@property (nonatomic, assign) NSInteger notificationCount;

@end

@implementation AppDelegate

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self managedObjectContext];
    
    [ReachabilityManager sharedManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetBadgeCount:) name:TurnipResetBadgeCountNotification object:nil];
        
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    self.storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // Google Maps Api Key
    [GMSServices provideAPIKey:@"AIzaSyA4QJU6IPnOSOdPoc0CA1No1Ng0GukJn-8"];
    
    // [Optional] Power your app with Local Datastore. For more info, go to
    // https://parse.com/docs/ios_guide#localdatastore/iOS
    //[Parse enableLocalDatastore];
    
    [ParseCrashReporting enable];
    
    // Initialize Parse.
    [Parse setApplicationId:@"CJ2nRu0kVksgPXZjE38Cyhksns2PFckOwq6c9c64"
                  clientKey:@"UWt8D4lmGKO6Yr2axtpq68aJitE4Iy4ceH7A10GW"];
    
    // [Optional] Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFFacebookUtils initializeFacebook];
    
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
    }
    
    
    if(application.applicationState != UIApplicationStateBackground) {
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.549 green:0 blue:0.102 alpha:1]];
    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [UIColor whiteColor], NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [UIFont fontWithName:@"LemonMilk" size:20.0], NSFontAttributeName, nil]];
    
    Reachability *reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    if ([reachability isReachable]) {
        
        if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            // Present wall straight-away
            [self presentMapViewControllerAnimated:NO];
        } else {
            // Go to the welcome screen and have them log in or create an account.
            [self presentLoginViewController];
        }
        
    } else {
        [self presentLoginViewController];
    }

    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    // Logs 'install' and 'app activate' App Events.
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[PFFacebookUtils session] close];
}

#pragma mark push notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackground];
}


-(void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Push registration error: %@", error);
}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    if (application.applicationState == UIApplicationStateActive) {
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    
    UITabBarController *tabController = (UITabBarController *) self.window.rootViewController;
    
    // Create empty photo object
    //    NSString *userId = [userInfo objectForKey:@"fromUser"];
    NSString *type = [userInfo objectForKey:@"type"];
    
    if ([type isEqualToString:@"eventRequest"]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:TurnipPartyRequestPushNotification
         object:self];
        
        self.notificationCount += 1;
        
        [[tabController.viewControllers objectAtIndex: TurnipTabNotification] tabBarItem].badgeValue = [NSString stringWithFormat:@"%ld", (long) self.notificationCount];
    }
    
    if([type isEqualToString:@"eventAccepted"]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName: TurnipAcceptedRequestNotification
         object:self];
        
        self.notificationCount += 1;
        
        [[tabController.viewControllers objectAtIndex:TurnipTabNotification] tabBarItem].badgeValue = [NSString stringWithFormat:@"%ld", (long) self.notificationCount];
    }
}

- (BOOL) pushNotificationOnOrOff
{
    if ([UIApplication instancesRespondToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        return ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]);
    } else {
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        return (types & UIRemoteNotificationTypeAlert);
    }
}

#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings: (UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    //handle the actions
    if ([identifier isEqualToString:@"declineAction"]){
        NSLog(@"decline");
    }
    else if ([identifier isEqualToString:@"answerAction"]){
        NSLog(@"accept");
    }
}
#endif

#pragma mark save to coreData

- (void) saveTicketInfo: (PFObject *) object {
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObject *dataRecord = [NSEntityDescription
                                   insertNewObjectForEntityForName:@"TicketInfo"
                                   inManagedObjectContext: context];
    
    [dataRecord setValue: [object objectForKey: @"title"] forKey:@"title"];
    [dataRecord setValue: [object objectId] forKey:@"objectId"];
    [dataRecord setValue: [object objectForKey: @"address"] forKey:@"address"];
    [dataRecord setValue: [object objectForKey: @"date"] forKey:@"date"];
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Error:%@", error);
    }
    NSLog(@"Data saved");
}

#pragma mark - Notification delegates

- (void) resetBadgeCount:(NSNotification *)note {
    
    self.notificationCount = 0;
}

#pragma mark facebook url open

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

#pragma mark -
#pragma mark LoginViewController

- (void)presentLoginViewController {
    // Go to the welcome screen and have them log in or create an account.
    UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"loginView"];
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];
}

#pragma mark -
#pragma mark MapViewController

- (void)presentMapViewControllerAnimated:(BOOL)animated {
    
    FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            
            UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"tabBar"];
            self.window.rootViewController = viewController;
            [self.window makeKeyAndVisible];
            
        } else if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
                    isEqualToString: @"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            NSLog(@"The facebook session was invalidated");
        } else {
            NSLog(@"Some other error: %@", error);
        }
    }];
}

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext {
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TurnipDataModel" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"TurnipDataModel.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {

        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end