#import <Foundation/Foundation.h>


@interface RSSItem : NSObject <NSXMLParserDelegate>
{
    NSString *title;
    NSString *link;
    NSMutableString *currentString;
    
    id parentParserDelegate;
}
@property (nonatomic, assign) id parentParserDelegate;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *link;

@end
