#import "WebViewController.h"


@implementation WebViewController

- (void)loadView 
{
    // Create an instance of UIWebView as large as the screen
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    UIWebView *wv = [[UIWebView alloc] initWithFrame:screenFrame];
    // Tell web view to scale web content to fit within bounds of webview 
    [wv setScalesPageToFit:YES];
    
    [self setView:wv];
    [wv release];
}

- (UIWebView *)webView
{
    return (UIWebView *)[self view];
}

@end
