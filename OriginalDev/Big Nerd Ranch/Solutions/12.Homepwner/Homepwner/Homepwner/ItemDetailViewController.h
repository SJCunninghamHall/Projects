#import <UIKit/UIKit.h>

@class Possession;

@interface ItemDetailViewController : UIViewController
{
    IBOutlet UITextField *nameField;
    IBOutlet UITextField *serialNumberField;
    IBOutlet UITextField *valueField;
    IBOutlet UILabel *dateLabel;
    
    Possession *possession;
}

@property (nonatomic, retain) Possession *possession;

@end
