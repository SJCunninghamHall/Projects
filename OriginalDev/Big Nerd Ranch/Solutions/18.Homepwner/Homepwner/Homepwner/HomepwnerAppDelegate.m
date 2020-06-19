#import "HomepwnerAppDelegate.h"
#import "ItemsViewController.h"
#import "PossessionStore.h"

@implementation HomepwnerAppDelegate


@synthesize window=_window;

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ItemsViewController *itemsViewController = [[ItemsViewController alloc] init];
    
    // Create an instance of a UINavigationController
    // its stack contains only itemsViewController
    UINavigationController *navController = [[UINavigationController alloc]
                                             initWithRootViewController:itemsViewController];
    
    // You can now release the itemsViewController here,
    // UINavigationController will retain it
    [itemsViewController release];
    
    // Place navigation controller's view in the window hierarchy
    [[self window] setRootViewController:navController];
    
    [navController release];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[PossessionStore defaultStore] saveChanges];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[PossessionStore defaultStore] saveChanges];
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

@end
