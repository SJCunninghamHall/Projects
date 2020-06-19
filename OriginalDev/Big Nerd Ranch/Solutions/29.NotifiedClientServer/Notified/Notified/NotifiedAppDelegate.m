#import "NotifiedAppDelegate.h"
#import <netinet/in.h>
#import <arpa/inet.h>
@implementation NotifiedAppDelegate


@synthesize window=_window;

- (void)application:(UIApplication *)application 
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // We'll keep this token and then attempt to send it to the server 
    pushToken = [deviceToken retain];
    
    // Shortly, we'll change the implementation of this method to send the device 
    // token along with the device name to the server
    [self postInformationToServer];
}

- (void)application:(UIApplication *)application 
didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // If we get a notification while the app is running, we'll just get the alert 
    // and display it to the user
    [notificationView setText:[[userInfo objectForKey:@"aps"] 
                               objectForKey:@"alert"]];
}

- (void)application:(UIApplication *)application 
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [statusLabel setText:@"Failed to register with Apple"];
    NSLog(@"%@", error);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // When the user opens the application, clear the badge since we've seen the 
    // notification
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // If the user chooses to launch the application in response to a notification, 
    // get the notification information to use in the app 
    NSDictionary *remoteDict =
        [launchOptions 
         objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteDict)
        [self application:application didReceiveRemoteNotification:remoteDict];

    // Register (every time the app launches) for notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
                                            UIRemoteNotificationTypeAlert 
                                          | UIRemoteNotificationTypeBadge
                                          | UIRemoteNotificationTypeSound];

    browser = [[NSNetServiceBrowser alloc] init]; 
    [browser setDelegate:self]; 
    [browser searchForServicesOfType:@"_http._tcp." inDomain:@""];
    
    [[self window] makeKeyAndVisible];
    return YES;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser
           didFindService:(NSNetService *)aNetService
               moreComing:(BOOL)moreServicesComing
{
    // Looking for an HTTP service, but only one with the name CocoaHTTPServer
    if (!desktopServer && [[aNetService name] isEqualToString:@"CocoaHTTPServer"]) {
        [aNetService retain];
        [aNetService resolveWithTimeout:30];
        [aNetService setDelegate:self];
        [statusLabel setText:@"Resolving CocoaHTTPServer..."];
    } else {
        NSLog(@"ignoring %@", aNetService);
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    [statusLabel setText:@"Resolved service..."];
    desktopServer = sender;
    [self postInformationToServer];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    // Couldn't figure out the address...
    [statusLabel setText:@"Could not resolve service."];
    NSLog(@"%@", errorDict);
    
    // Release the service object
    [desktopServer release];
    desktopServer = nil;
}

- (NSString *)serverHostName
{
    NSArray *addresses = [desktopServer addresses];
    
    NSData *firstAddress = [addresses objectAtIndex:0];
    
    // The binary data in the NSData object is a sockaddr_in - which
    // represents a network host
    const struct sockaddr_in *addy = [firstAddress bytes];
    
    // Convert 4-byte IP address in network byte order to a C string
    // of the format: xxx.xxx.xxx.xxx
    char *ipAddress = inet_ntoa(addy->sin_addr);
    
    // Convert the 2-byte port number from network to host byte order
    UInt16 port = ntohs(addy->sin_port);
    
    return [NSString stringWithFormat:@"%s:%u", ipAddress, port];
}

- (void)postInformationToServer
{
    // We make sure we have both before we make the connection
    if (desktopServer && pushToken) {

        [statusLabel setText:@"Sending data to server..."];
        
        // Now, we are adding the token to the dictionary that will be the 
        // body of the request
        NSDictionary *d = 
            [NSDictionary dictionaryWithObjectsAndKeys:pushToken, @"token", 
                                 [[UIDevice currentDevice] name], @"name", nil];
    
        // Create XML representation of this dictionary
        NSData *data = [NSPropertyListSerialization
                                       dataWithPropertyList:d
                                                     format:NSPropertyListXMLFormat_v1_0
                                                    options:0
                                                      error:nil];
    
        // Make a connection to the provider to post the information to it - the URL 
        // is the address and port of the resolved service
        NSString *urlString = [NSString stringWithFormat:@"http://%@/register",
                               [self serverHostName]];
        
        // The request will use this URL, be a POST, and have the dictionary as its data
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:urlString]];
        [req setHTTPMethod:@"POST"];
        [req setHTTPBody:data];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req 
                                                                      delegate:self];
        [connection start];
        
        // This curly brace ends the if statement - it wasn't here before
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [statusLabel setText:@"Data sent to server."];
    [connection release];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [statusLabel setText:@"Connection to server failed."];
    NSLog(@"%@", error);
    
    [connection release];
}

- (void)dealloc
{
    [[self window] release];
    [statusLabel release];
    [notificationView release];
    [super dealloc];
}

@end
