#import <Cocoa/Cocoa.h>
#import "HTTPServer.h"

@interface CocoaServerAppDelegate : NSObject 
    <NSApplicationDelegate, NSNetServiceDelegate,
    NSTableViewDataSource, NSTableViewDelegate,
    NSStreamDelegate>

{
    NSWindow *window;
    IBOutlet NSTableView *tableView;
    IBOutlet NSTextField *statusField;
    
    IBOutlet NSTextField *messageField;
    NSNetService *service;
    NSMutableArray *registeredUsers;
    
    HTTPServer *server;
    NSOutputStream *writeStream;
    NSInputStream *readStream;
}
- (void)configureStreams;
- (NSArray *)certificateArray;
- (void)connectToNotificationServer;

- (NSData *)notificationDataForMessage:(NSString *)msgText token:(NSData *)token;
- (IBAction)pushMessage:(id)sender;

@property (assign) IBOutlet NSWindow *window;
- (BOOL)handleRegister:(CFHTTPMessageRef)request;
@end
