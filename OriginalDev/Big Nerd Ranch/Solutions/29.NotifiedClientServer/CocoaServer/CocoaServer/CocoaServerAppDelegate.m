#import <Security/Security.h>
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
    
    [self connectToNotificationServer];
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

- (NSData *)notificationDataForMessage:(NSString *)msgText token:(NSData *)token 
{    
    
    // To signify the enhanced format, we use 1 as the first byte 
    uint8_t command = 1;
    
    // This is the identifier for this specific notification 
    static uint32_t identifier = 5000;
    
    // The notification will expire in one day 
    uint32_t expiry = htonl(time(NULL) + 86400);
    
    // Find the binary lengths of the data we will send 
    uint16_t tokenLength = htons([token length]);
    
    // Must escape text before inserting in JSON
    NSMutableString *escapedText = [[msgText mutableCopy] autorelease];
    
    /* Replace \ with \\ */
    [escapedText replaceOccurrencesOfString:@"\\"
                                 withString:@"\\\\"
                                    options:0
                                      range:NSMakeRange(0, [escapedText length])];
    
    // Replace " with \"
    [escapedText replaceOccurrencesOfString:@"\"" 
                                 withString:@"\\\"" 
                                    options:0 
                                      range:NSMakeRange(0, [escapedText length])];
    
    // Construct the JSON payload to deliver to the device
    NSString *payload = [NSString stringWithFormat:
             @"{\"aps\":{\"alert\":\"%@\",\"sound\":\"Sound12.aif\",\"badge\":1}}", 
             escapedText];
    
    // We'll have to encode this into a binary buffer, so NSString won't fly 
    const char *payloadBuffer = [payload UTF8String];
    
    // Note: sending length to an NSString will give us the number 
    // of characters, not the number of bytes, but strlen 
    // gives us the number of bytes. (Some characters 
    // take up more than one byte in Unicode)
    uint16_t payloadLength = htons(strlen(payloadBuffer));
    
    // Create a binary data container to pack all of the data 
    NSMutableData *data = [NSMutableData data];
    
    // Add each component in the right order to the data container
    [data appendBytes:&command length:sizeof(uint8_t)];
    
    [data appendBytes:&identifier length:sizeof(uint32_t)];
    
    [data appendBytes:&expiry length:sizeof(uint32_t)];
    
    [data appendBytes:&tokenLength length:sizeof(uint16_t)];
    [data appendBytes:[token bytes] length:[token length]];
    
    [data appendBytes:&payloadLength length:sizeof(uint16_t)];
    [data appendBytes:payloadBuffer length:strlen(payloadBuffer)];
    
    // Increment the identifier for the next notification 
    identifier++;
    
    return data;
}

- (IBAction)pushMessage:(id)sender
{    
    // If you haven't selected a row, there is no one to send 
    // the message to 
    NSInteger row = [tableView selectedRow];
    if (row == -1)
        return;
    
    // Pull the message out of the text view and the token 
    // of the device we are going to talk to 
    NSString *msgText = [messageField stringValue];
    NSData *token = [[registeredUsers objectAtIndex:row] objectForKey:@"token"];
    
    NSData *data = [self notificationDataForMessage:msgText token:token];
    
    // Send this data out to Apple's server
    [writeStream write:[data bytes] maxLength:[data length]];
}

- (void)connectToNotificationServer
{
    // Connect to push notification server, we get back two stream objects
    // that will allow us to write to and read from that server
    CFStreamCreatePairWithSocketToHost(NULL,
                                       (CFStringRef)@"gateway.sandbox.push.apple.com",
                                       2195,
                                       (CFReadStreamRef *)(&readStream),
                                       (CFWriteStreamRef *)(&writeStream));
    // Open up the streams
    [readStream open];
    [writeStream open];
    
    // Make sure that opening didn't fail
    if ([readStream streamStatus] != NSStreamStatusError 
        && [writeStream streamStatus] != NSStreamStatusError) {
        [self configureStreams];
    }
    else {
        NSLog(@"Failed to connect to Apple.");
    }
}

- (BOOL)handleRegister:(CFHTTPMessageRef)request
{
    // Get the data from the service request
    NSData *body = [(NSData *)CFHTTPMessageCopyBody(request) autorelease];
    
    // We know that it is a dictionary (if itÕs not, this method will return nil)
    NSDictionary *bodyDict = [NSPropertyListSerialization
                                    propertyListFromData:body 
                                        mutabilityOption:NSPropertyListImmutable 
                                                  format:nil
                                        errorDescription:nil];
    
    // Grab the "token" and "name" objects from this dictionary
    // and make sure they are there
    NSData *token = [bodyDict objectForKey:@"token"];
    NSString *name = [bodyDict objectForKey:@"name"];
    if (token && name) {
        
        // Make sure we haven't already recorded this device token
        BOOL unique = YES;
        for (NSDictionary *d in registeredUsers) {
            if ([[d objectForKey:@"token"] isEqual:token])
                unique = NO;
        }
        
        if (unique) {
            // If we haven't recorded this token, then it's a new one and
            // we'll keep it - refresh the table
            [registeredUsers addObject:bodyDict];
            [tableView reloadData];
        }
        return YES;
    }
    return NO;
}

- (NSArray *)certificateArray
{
    // Get the path of the certificate in the bundle
    NSString *certPath = 
    [[NSBundle mainBundle] pathForResource:@"aps_developer_identity" 
                                    ofType:@"cer"];
    
    // Pull the data from the filesystem and create a SecCertificate object
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    SecCertificateRef cert = SecCertificateCreateWithData(NULL, (CFDataRef)certData);
    
    // Create the identity (private key) which requires
    // that the certificate lives in the keychain
    SecIdentityRef identity;
    OSStatus err = SecIdentityCreateWithCertificate(NULL, cert, &identity);
    if (err) {
        NSLog(@"Failed to create certificate identity: %d", err);
        return nil;
    }
    
    // Put the key and certificate into an array
    return [NSArray arrayWithObjects:(id)identity, (id)cert, nil];
}

- (void)configureStreams
{
    NSArray *certArray = [self certificateArray];
    if (!certArray)
        return;
    
    // Give the streams their SSL settings so they can encrypt/decrypt
    // data to/from the server 
    NSDictionary *sslSettings = 
    [NSDictionary dictionaryWithObjectsAndKeys:[self certificateArray],
     (id)kCFStreamSSLCertificates,
     (id)kCFStreamSocketSecurityLevelNegotiatedSSL,
     (id)kCFStreamSSLLevel, nil];
    
    [writeStream setProperty:sslSettings
                      forKey:(id)kCFStreamPropertySSLSettings];
    
    [readStream setProperty:sslSettings 
                     forKey:(id)kCFStreamPropertySSLSettings];
    
    // Give streams a delegate so we can monitor them
    [readStream setDelegate:self];
    [writeStream setDelegate:self];
    
    // Schedule the streams into the run loop so that they can do their work 
    [writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] 
                           forMode:NSDefaultRunLoopMode];
    [readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] 
                          forMode:NSDefaultRunLoopMode];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode)
    {
        case NSStreamEventHasBytesAvailable:
        {
            if (aStream == readStream)
            {
                // If data came back from the server, we have an error
                // Let's fetch it out
                NSUInteger lengthRead = 0;
                do 
                {
                    // Error packet is always 6 bytes
                    uint8_t *buffer = malloc(6);
                    lengthRead = [readStream read:buffer maxLength:6];
                    
                    // First byte is command (always 8)
                    uint8_t command = buffer[0];
                    
                    // Second byte is the status code
                    uint8_t status = buffer[1];
                    
                    // This will be the notification identifier
                    uint32_t *ident = (uint32_t *)(buffer + 2);
                    
                    NSLog(@"ERROR WITH NOTIFICATION: %d %d %d", 
                          (int)command, (int)status, *ident);
                    
                    free(buffer);
                } while(lengthRead > 0);
            }
        } break;
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"%@ is open", aStream);
        } break;
        case NSStreamEventHasSpaceAvailable:
        {
            NSLog(@"%@ can accept bytes", aStream);
        } break;
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"%@ error: %@", aStream, [aStream streamError]);
        } break;
        case NSStreamEventEndEncountered:
        {
            NSLog(@"%@ ended - probably closed by server", aStream);
        } break;
    }
}

- (id)tableView:(NSTableView *)aTableView 
    objectValueForTableColumn:(NSTableColumn *)aTableColumn 
                          row:(NSInteger)rowIndex
{
    NSDictionary *entry = [registeredUsers objectAtIndex:rowIndex];
    return [NSString stringWithFormat:@"%@ (%@)", 
            [entry objectForKey:@"name"], 
            [entry objectForKey:@"token"]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [registeredUsers count];
}
@end
