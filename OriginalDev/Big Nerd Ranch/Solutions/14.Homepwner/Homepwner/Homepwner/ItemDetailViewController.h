#import <UIKit/UIKit.h>

@class Possession;

@class ItemDetailViewController;

@protocol ItemDetailViewControllerDelegate <NSObject>

@optional
- (void)itemDetailViewControllerWillDismiss:(ItemDetailViewController *)vc;

@end

@interface ItemDetailViewController : UIViewController 
    <UINavigationControllerDelegate, UIImagePickerControllerDelegate, 
    UITextFieldDelegate, UIPopoverControllerDelegate>
{
    IBOutlet UITextField *nameField;
    IBOutlet UITextField *serialNumberField;
    IBOutlet UITextField *valueField;
    IBOutlet UILabel *dateLabel;
    IBOutlet UIImageView *imageView;
    
    Possession *possession;
    
    UIPopoverController *imagePickerPopover;
}

- (id)initForNewItem:(BOOL)isNew;

@property (nonatomic, assign)
                        id <ItemDetailViewControllerDelegate> delegate;

@property (nonatomic, retain) Possession *possession;

- (IBAction)takePicture:(id)sender;
- (IBAction)backgroundTapped:(id)sender;

@end
