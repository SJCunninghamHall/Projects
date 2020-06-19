#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface WhereamiAppDelegate : NSObject
    <UIApplicationDelegate, CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
