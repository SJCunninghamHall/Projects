#import <UIKit/UIKit.h>

@class Possession;

@interface ItemDetailViewController : UIViewController
    <UINavigationControllerDelegate, UIImagePickerControllerDelegate,
        UITextFieldDelegate>
{
    IBOutlet UITextField *nameField;
    IBOutlet UITextField *serialNumberField;
    IBOutlet UITextField *valueField;
    IBOutlet UILabel *dateLabel;
    IBOutlet UIImageView *imageView;
    
    Possession *possession;
}

@property (nonatomic, retain) Possession *possession;

- (IBAction)takePicture:(id)sender;
- (IBAction)backgroundTapped:(id)sender;

@end
