#import "CocoaServerAppDelegate.h"

@implementation CocoaServerAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    server = [[HTTPServer alloc] init];
    [server setDelegate:self];
    
    NSError *err = nil;
    [server start:&err];
    
    if (err) {
        NSLog(@"Server failed to start: %@", err);
        return;
    }
    
    registeredUsers = [[NSMutableArray alloc] init];
    
    // Create a service object that will advertise the server's existence
    // on the local network
    service = [[NSNetService alloc] initWithDomain:@""
                                              type:@"_http._tcp."
                                              name:@"CocoaHTTPServer"
                                              port:[server port]];
    [service setDelegate:self];
    [service publish];
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    // When the service succeeds in publishing...
    [statusField setStringValue:@"Server is advertising"];
}

- (void)netServiceDidStop:(NSNetService *)sender
{
    // If the service stops for some reason...
    [statusField setStringValue:@"Server is not advertising"];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    // If the service fails to publish, either immediately or in the future...
    [statusField setStringValue:@"Server is not advertising"];
}

- (void)HTTPConnection:(HTTPConnection *)conn
     didReceiveRequest:(HTTPServerRequest *)mess
{
    BOOL requestWasOkay = NO;
    
    // The HTTPServerRequest contains the message object
    // that holds the request from the client
    CFHTTPMessageRef request = [mess request];
    
    // Get the HTTP method of that request
    NSString *method = [(NSString *)CFHTTPMessageCopyRequestMethod(request)
                        autorelease];
    
    // We only care about POST requests
    if ([method isEqualToString:@"POST"]) {
        //Get the Request-URI
        NSURL *requestURL = [(NSURL *)CFHTTPMessageCopyRequestURL(request)
                             autorelease];
        
        // We only care about "register" service requests - the requestURL 
        // will have a slash in front of it
        if ([[requestURL absoluteString] isEqualToString:@"/register"]) {
            
            // This method is not yet implemented, but it will return YES 
            // if the data in the request was appropriate 
            requestWasOkay = [self handleRegister:request];
        }
    }
    
    CFHTTPMessageRef response = NULL;
    if (requestWasOkay) {
        // If the client gave us what we wanted, then tell them they did
        // a good job by returning status code 200 - this is the response 
        // an NSURLConnection receives
        response = CFHTTPMessageCreateResponse(NULL, 
                                               200, 
                                               NULL, 
                                               kCFHTTPVersion1_1);
    } else {
        // If the client gave us bad data, then tell them they did
        // with a bad request status code
        response = CFHTTPMessageCreateResponse(NULL, 
                                               400, 
                                               NULL, 
                                               kCFHTTPVersion1_1);    
    }
    
    // Must set the content-length of a response
    CFHTTPMessageSetHeaderFieldValue(response, 
                                     (CFStringRef)@"Content-Length", 
                                     (CFStringRef)@"0");
    
    // By setting the response of the HTTPServerRequest, 
    // it automatically dispatches it to the requesting client
    // and we can release it 
    [mess setResponse:response];
    
    CFRelease(response);
}

- (BOOL)handleRegister:(CFHTTPMessageRef)request
{
    // Get the data from the service request
    NSData *body = [(NSData *)CFHTTPMessageCopyBody(request) autorelease];
    
    // We know that it is a dictionary (if it’s not, this method will return nil)
    NSDictionary *bodyDict = [NSPropertyListSerialization
                              propertyListFromData:body 
                              mutabilityOption:NSPropertyListImmutable 
                              format:nil
                              errorDescription:nil];
    
    // Get the "name" object from this dictionary
    // and make sure the object exists 
    NSString *name = [bodyDict objectForKey:@"name"];
    if (name) {
        // Take the whole dictionary and add it to the registeredUsers,
        // update the table that will eventually show the users
        [registeredUsers addObject:bodyDict];
        [tableView reloadData];
        return YES;
    }
    return NO;
}

- (id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn 
            row:(NSInteger)rowIndex
{
    NSDictionary *entry = [registeredUsers objectAtIndex:rowIndex];
    return [NSString stringWithFormat:@"%@", [entry objectForKey:@"name"]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [registeredUsers count];
}
@end
