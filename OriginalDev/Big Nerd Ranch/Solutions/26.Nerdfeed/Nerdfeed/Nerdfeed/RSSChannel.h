#import <Foundation/Foundation.h>


@interface RSSChannel : NSObject <NSXMLParserDelegate>
{
    NSString *title;
    NSString *shortDescription;
    NSMutableArray *items;
    NSMutableString *currentString;
    
    id parentParserDelegate;
}
@property (nonatomic, assign) id parentParserDelegate;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *shortDescription;
@property (nonatomic, readonly) NSMutableArray *items;

@end
