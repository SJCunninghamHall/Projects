#import "HypnoTimeAppDelegate.h"
#import "HypnosisViewController.h"
#import "CurrentTimeViewController.h"

@implementation HypnoTimeAppDelegate


@synthesize window=_window;

- (BOOL)application:(UIApplication *)application 
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Create the tabBarController
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    // Create two view controllers
    UIViewController *vc1 = [[HypnosisViewController alloc] init];
    UIViewController *vc2 = [[CurrentTimeViewController alloc] init];
    
    // Make an array containing the two view controllers
    NSArray *viewControllers = [NSArray arrayWithObjects:vc1, vc2, nil];
    
    // The viewControllers array retains vc1 and vc2, we can release
    // our ownership of them in this method
    [vc1 release];
    [vc2 release];
    
    // Attach them to the tab bar controller
    [tabBarController setViewControllers:viewControllers];
    
    // Put the tabBarController's view on the window
    [[self window] setRootViewController:tabBarController];
    
    // The window retains tabBarController, we can release our reference
    [tabBarController release];
    
    // Show the window
    [[self window] makeKeyAndVisible];
    
    return YES;
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

@end
