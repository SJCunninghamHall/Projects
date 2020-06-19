//
//  PictureListDetail.h
//  PictureList
//
//  Created by Simon from Maybelost.com
//
//  If you use this code, it'd be awesome if you'd give a mention to my blog
//  site so that others may also get some use from the tutorials. It's not
//  mandatory of course, but it'll give you a warm fuzzy feeling inside.
//

#import <UIKit/UIKit.h>
#import "Pictures.h"

@interface PictureListDetail : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) Pictures *currentPicture;

@property (strong, nonatomic) IBOutlet UITextField *titleField;
@property (strong, nonatomic) IBOutlet UITextField *descriptionField;
@property (strong, nonatomic) IBOutlet UIImageView *imageField;

@property (strong, nonatomic) UIImagePickerController *imagePicker;

@end
