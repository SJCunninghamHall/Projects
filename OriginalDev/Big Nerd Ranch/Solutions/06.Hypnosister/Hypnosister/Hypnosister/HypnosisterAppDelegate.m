#import "HypnosisterAppDelegate.h"
#import "HypnosisView.h"

@implementation HypnosisterAppDelegate

@synthesize window=_window;

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Make a CGRect that is the size of the window
    CGRect wholeWindow = [[self window] bounds];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:wholeWindow];
    [[self window] addSubview:scrollView];
    
    // Make your view twice as large as the window
    CGRect reallyBigRect;
    reallyBigRect.origin = CGPointZero;
    reallyBigRect.size.width = wholeWindow.size.width * 2.0;
    reallyBigRect.size.height = wholeWindow.size.height * 2.0;
    [scrollView setContentSize:reallyBigRect.size];
    
    // Center it in the scroll view
    CGPoint offset;
    offset.x = wholeWindow.size.width * 0.5;
    offset.y = wholeWindow.size.height * 0.5;
    [scrollView setContentOffset:offset];
    
    // Enable zooming
    [scrollView setMinimumZoomScale:0.5];
    [scrollView setMaximumZoomScale:5];
    [scrollView setDelegate:self];
    
    // Create the view
    view = [[HypnosisView alloc] initWithFrame:reallyBigRect];
    [view setBackgroundColor:[UIColor clearColor]];
    [scrollView addSubview:view];
    
    [scrollView release];    
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                    withAnimation:UIStatusBarAnimationFade];    
    [[self window] makeKeyAndVisible];
    return YES;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return view;
}

// A dealloc method that will never get called because 
// HypnosisterAppDelegate will exist for the life of the application
- (void)dealloc
{
    [view release];
    [_window release];
    [super dealloc];
}

@end
