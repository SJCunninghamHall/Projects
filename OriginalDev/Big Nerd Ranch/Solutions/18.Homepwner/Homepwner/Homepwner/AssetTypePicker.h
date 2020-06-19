#import <UIKit/UIKit.h>
@class Possession;

@interface AssetTypePicker : UITableViewController {
    Possession *possession;
}
@property (nonatomic, retain) Possession *possession;

@end
