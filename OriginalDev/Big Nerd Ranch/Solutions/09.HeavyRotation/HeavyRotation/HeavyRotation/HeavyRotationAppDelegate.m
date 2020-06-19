#import "HeavyRotationAppDelegate.h"
#import "HeavyViewController.h"

@implementation HeavyRotationAppDelegate

@synthesize window=_window;

- (BOOL)application:(UIApplication *)application 
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Get the device object
    UIDevice *device = [UIDevice currentDevice];
    
    // Tell it to start monitoring the accelerometer for orientation
    [device beginGeneratingDeviceOrientationNotifications];
    
    // Get the notification center for the app
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // Add yourself as an observer
    [nc addObserver:self
           selector:@selector(orientationChanged:)
               name:UIDeviceOrientationDidChangeNotification
             object:device];
    
    HeavyViewController *hvc = [[[HeavyViewController alloc] init] autorelease];
    [[self window] setRootViewController:hvc];
    
    [[self window] makeKeyAndVisible];
    
    return YES;
}

- (void)orientationChanged:(NSNotification *)note
{
    // Log the constant that represents the current orientation
    NSLog(@"orientationChanged: %d", [[note object] orientation]);
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

@end
