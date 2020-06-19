#import <UIKit/UIKit.h>


@interface TouchDrawView : UIView
{
	NSMutableDictionary *linesInProcess;
	NSMutableArray *completeLines;
}

- (void)clearAll;
- (void)endTouches:(NSSet *)touches;

@end
