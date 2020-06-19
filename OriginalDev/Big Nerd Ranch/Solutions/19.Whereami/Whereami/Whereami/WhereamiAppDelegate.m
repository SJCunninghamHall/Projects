#import "WhereamiAppDelegate.h"
#import "MapPoint.h"

NSString * const WhereamiMapTypePrefKey = @"WhereamiMapTypePrefKey";

@implementation WhereamiAppDelegate

@synthesize window=_window;

+ (void)initialize
{
    NSDictionary *defaults = [NSDictionary 
                            dictionaryWithObject:[NSNumber numberWithInt:1]
                                          forKey:WhereamiMapTypePrefKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (BOOL)application:(UIApplication *)application 
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSInteger mapTypeValue = [[NSUserDefaults standardUserDefaults] 
                                integerForKey:WhereamiMapTypePrefKey];
    
    // Update the UI
    [mapTypeControl setSelectedSegmentIndex:mapTypeValue];
    
    // Update the map
    [self changeMapType:mapTypeControl];
    
    // Create location manager object
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    
    [locationManager setDistanceFilter:kCLDistanceFilterNone];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    
    [worldView setShowsUserLocation:YES];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (IBAction)changeMapType:(id)sender
{
    [[NSUserDefaults standardUserDefaults] 
                    setInteger:[sender selectedSegmentIndex]
                        forKey:WhereamiMapTypePrefKey];
    
    switch([sender selectedSegmentIndex])
    {
        case 0:
        {
            [worldView setMapType:MKMapTypeStandard];
        } break;
        case 1:
        {
            [worldView setMapType:MKMapTypeSatellite];
        } break;
        case 2:
        {
            [worldView setMapType:MKMapTypeHybrid];
        } break;
    }
}

- (void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"%@", newLocation);
    
    // How many seconds ago was this new location created?
    NSTimeInterval t = [[newLocation timestamp] timeIntervalSinceNow];
    
    // CLLocationManagers will return the last found location of the
    // device first, you don't want that data in this case.
    // If this location was made more than 3 minutes ago, ignore it.
    if (t < -180) {
        // This is cached data, you don't want it, keep looking
        return;
    }
    [self foundLocation:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager 
       didFailWithError:(NSError *)error
{
    NSLog(@"Could not find location: %@", error);
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)u
{
    CLLocationCoordinate2D loc = [u coordinate];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 250, 250);
    [worldView setRegion:region animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf
{
    [self findLocation];

    [tf resignFirstResponder];
    return YES;
}

- (void)findLocation
{
    [locationManager startUpdatingLocation];
    [activityIndicator startAnimating];
    [locationTitleField setHidden:YES];
}

- (void)foundLocation:(CLLocation *)loc
{
    CLLocationCoordinate2D coord = [loc coordinate];
    
    // Create an instance of MapPoint with the current data
    MapPoint *mp = [[MapPoint alloc] initWithCoordinate:coord
                                                  title:[locationTitleField text]];
    // Add it to the map view
    [worldView addAnnotation:mp];
    
    // MKMapView retains its annotations, we can release
    [mp release];
    
    // Zoom the region to this location
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord, 250, 250);
    [worldView setRegion:region animated:YES];
    
    [locationTitleField setText:@""];
    [activityIndicator stopAnimating];
    [locationTitleField setHidden:NO];
    [locationManager stopUpdatingLocation];
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
