#import <Foundation/Foundation.h>

// Must import this file as it is where ListViewControllerDelegate is declared
#import "ListViewController.h"

@interface WebViewController : UIViewController
            <ListViewControllerDelegate, UISplitViewControllerDelegate>
{
    
}

@property (nonatomic, readonly) UIWebView *webView;

@end
