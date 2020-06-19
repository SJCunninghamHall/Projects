#import <UIKit/UIKit.h>

// This is a forward declaration
@class HypnosisView;

@interface HypnosisterAppDelegate : NSObject
    <UIApplicationDelegate, UIScrollViewDelegate> {
    
    HypnosisView *view;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
