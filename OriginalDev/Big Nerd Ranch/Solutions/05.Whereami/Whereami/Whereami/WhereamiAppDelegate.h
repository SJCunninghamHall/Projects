#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface WhereamiAppDelegate : NSObject
    <UIApplicationDelegate, CLLocationManagerDelegate, MKMapViewDelegate,
    UITextFieldDelegate>
{
    CLLocationManager *locationManager;
    
    IBOutlet MKMapView *worldView;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    IBOutlet UITextField *locationTitleField;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

- (void)findLocation;
- (void)foundLocation:(CLLocation *)loc;

@end
