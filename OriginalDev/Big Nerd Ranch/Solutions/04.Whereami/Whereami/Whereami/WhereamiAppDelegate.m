#import "WhereamiAppDelegate.h"

@implementation WhereamiAppDelegate

@synthesize window=_window;

- (BOOL)application:(UIApplication *)application 
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Create location manager object
    locationManager = [[CLLocationManager alloc] init];
    
    [locationManager setDelegate:self];
    
    // We want all results from the location manager
    [locationManager setDistanceFilter:kCLDistanceFilterNone];
    
    // And we want it to be as accurate as possible
    // regardless of how much time/power it takes
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    
    // Tell our manager to start looking for its location immediately
    [locationManager startUpdatingLocation];
    
    // This line may say self.window, don't worry about that
    [[self window] makeKeyAndVisible];
    return YES;
}

- (void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"%@", newLocation);
}

- (void)locationManager:(CLLocationManager *)manager 
       didFailWithError:(NSError *)error
{
    NSLog(@"Could not find location: %@", error);
}

- (void)dealloc
{
    if ([locationManager delegate] == self)
        [locationManager setDelegate:nil];
    
    [locationManager release];
    [_window release];
    [super dealloc];
}

@end
