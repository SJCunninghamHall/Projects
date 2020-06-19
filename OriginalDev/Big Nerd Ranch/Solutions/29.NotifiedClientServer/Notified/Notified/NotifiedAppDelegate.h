#import <UIKit/UIKit.h>

@interface NotifiedAppDelegate : NSObject 
    <UIApplicationDelegate,
        NSNetServiceBrowserDelegate, NSNetServiceDelegate> 
{
    NSData *pushToken;
    
    IBOutlet UILabel *statusLabel;
    IBOutlet UITextView *notificationView;

    NSNetService *desktopServer;
    NSNetServiceBrowser *browser;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
- (NSString *)serverHostName;
- (void)postInformationToServer;
@end
