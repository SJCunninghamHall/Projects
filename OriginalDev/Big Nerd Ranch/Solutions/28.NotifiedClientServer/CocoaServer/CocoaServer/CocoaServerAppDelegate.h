#import <Cocoa/Cocoa.h>
#import "HTTPServer.h"

@interface CocoaServerAppDelegate : NSObject 
    <NSApplicationDelegate, NSNetServiceDelegate,
    NSTableViewDataSource, NSTableViewDelegate> 
{
    NSWindow *window;
    IBOutlet NSTableView *tableView;
    IBOutlet NSTextField *statusField;
    
    NSNetService *service;
    NSMutableArray *registeredUsers;
    
    HTTPServer *server;
}

@property (assign) IBOutlet NSWindow *window;
- (BOOL)handleRegister:(CFHTTPMessageRef)request;
@end
