#import <Foundation/Foundation.h>
#import "ListViewController.h"

@class RSSChannel;

@interface ChannelViewController : UITableViewController
                <ListViewControllerDelegate, UISplitViewControllerDelegate>
{
    RSSChannel *channel;
}

@end
