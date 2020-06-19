#import <UIKit/UIKit.h>

@interface NotifiedAppDelegate : NSObject 
    <UIApplicationDelegate,
        NSNetServiceBrowserDelegate, NSNetServiceDelegate> 
{
    IBOutlet UILabel *statusLabel;

    NSNetService *desktopServer;
    NSNetServiceBrowser *browser;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
- (NSString *)serverHostName;
- (void)postInformationToServer;
@end
