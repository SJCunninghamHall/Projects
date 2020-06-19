#import <Foundation/Foundation.h>

@class RSSChannel;
@class WebViewController;

@interface ListViewController : UITableViewController <NSXMLParserDelegate>
{
    NSURLConnection *connection;
    NSMutableData *xmlData;
    
    RSSChannel *channel;
    
    WebViewController *webViewController;
}

@property (nonatomic, retain) WebViewController *webViewController;
- (void)fetchEntries;

@end
