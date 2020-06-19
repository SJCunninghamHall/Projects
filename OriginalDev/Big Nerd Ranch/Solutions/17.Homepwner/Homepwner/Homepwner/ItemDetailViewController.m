#import "ItemDetailViewController.h"
#import "Possession.h"
#import "ImageStore.h"
#import "PossessionStore.h"
#import "AssetTypePicker.h"

@implementation ItemDetailViewController

@synthesize possession;
@synthesize delegate;

- (id)initForNewItem:(BOOL)isNew
{
    self = [super initWithNibName:@"ItemDetailViewController" bundle:nil];
    
    if (self) {
        if (isNew) {
            UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] 
                                         initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                         target:self 
                                         action:@selector(save:)];
            [[self navigationItem] setRightBarButtonItem:doneItem];
            [doneItem release];
            
            
            UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] 
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                           target:self 
                                           action:@selector(cancel:)];
            [[self navigationItem] setLeftBarButtonItem:cancelItem];
            [cancelItem release];
        }
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle
{
    @throw [NSException exceptionWithName:@"Wrong initializer"
                                   reason:@"Use initForNewItem:"
                                 userInfo:nil];
    return nil;
}

- (IBAction)save:(id)sender
{
    // This message gets forwarded to the parentViewController
    [self dismissModalViewControllerAnimated:YES];

    if([delegate respondsToSelector:@selector(itemDetailViewControllerWillDismiss:)])
        [delegate itemDetailViewControllerWillDismiss:self];
}

- (IBAction)cancel:(id)sender
{
    // If the user cancelled, then remove the Possession from the store
    [[PossessionStore defaultStore] removePossession:possession];
    
    // This message gets forwarded to the parentViewController
    [self dismissModalViewControllerAnimated:YES];
    
    if([delegate respondsToSelector:@selector(itemDetailViewControllerWillDismiss:)])
        [delegate itemDetailViewControllerWillDismiss:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIColor *clr = nil;  
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        clr = [UIColor colorWithRed:0.875 green:0.88 blue:0.91 alpha:1];
    } else {
        clr = [UIColor groupTableViewBackgroundColor];
    }
    [[self view] setBackgroundColor:clr];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [nameField release];
    nameField = nil;
    
    [serialNumberField release];
    serialNumberField = nil;
    
    [valueField release];
    valueField = nil;
    
    [dateLabel release];
    dateLabel = nil;
    
    [imageView release];
    imageView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [nameField setText:[possession possessionName]];
    [serialNumberField setText:[possession serialNumber]];
    if ([possession valueInDollars]) {
        // Notice that the format string changed
        [valueField setText:[NSString stringWithFormat:@"%@",
                             [possession valueInDollars]]];        
    } else {
        [valueField setText:@"0"];
    }
    
    // Create a NSDateFormatter that will turn a date into a simple date string
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]
                                      autorelease];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];

    // Use filtered NSDate object to set dateLabel contents
    [dateLabel setText:
     [dateFormatter stringFromDate:[possession dateCreated]]];
    
    // Change the navigation item to display name of possession
    [[self navigationItem] setTitle:[possession possessionName]];
    
    NSString *imageKey = [possession imageKey];
    
    if (imageKey) {
        // Get image for image key from image store
        UIImage *imageToDisplay =
        [[ImageStore defaultImageStore] imageForKey:imageKey];
        
        // Use that image to put on the screen in imageView
        [imageView setImage:imageToDisplay];
    } else {
        // Clear the imageView
        [imageView setImage:nil];
    }
    
    NSString *typeLabel = [[possession assetType] valueForKey:@"label"];
    if(!typeLabel)
        typeLabel = @"None";
    
    [assetTypeButton setTitle:[NSString stringWithFormat:@"Type: %@", typeLabel]
                     forState:UIControlStateNormal];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // End any incomplete editing
    [[self view] endEditing:YES];
    
    // "Save" changes to possession
    [possession setPossessionName:[nameField text]];
    [possession setSerialNumber:[serialNumberField text]];
    NSNumber *valueNum = [NSNumber numberWithInt:[[valueField text] intValue]];
    [possession setValueInDollars:valueNum];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (io == UIInterfaceOrientationPortrait);
    }
}

- (IBAction)takePicture:(id)sender
{
    UIImagePickerController *imagePicker =
    [[UIImagePickerController alloc] init];
    
    // If our device has a camera, we want to take a picture, otherwise, we
    // just pick from photo library
    if ([UIImagePickerController
         isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) 
    {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    } else {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    [imagePicker setDelegate:self];
    
    // Place image picker on the screen
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // Create a new popover controller that will display the imagePicker
        imagePickerPopover = [[UIPopoverController alloc] 
                              initWithContentViewController:imagePicker];
        
        [imagePickerPopover setDelegate:self];
        
        // Display the popover controller, sender 
        // is the camera bar button item
        [imagePickerPopover presentPopoverFromBarButtonItem:sender
                                   permittedArrowDirections:UIPopoverArrowDirectionAny
                                                   animated:YES];
    } else {
        [self presentModalViewController:imagePicker animated:YES];
    }
    
    // The image picker will be retained by ItemDetailViewController
    // until it has been dismissed
    [imagePicker release];
}

- (IBAction)backgroundTapped:(id)sender
{
    [[self view] endEditing:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *oldKey = [possession imageKey];
    
    // Did the possession already have an image?
    if (oldKey) {
        
        // Delete the old image
        [[ImageStore defaultImageStore] deleteImageForKey:oldKey];
    }
    
    // Get picked image from info dictionary
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    // Create a CFUUID object - it knows how to create unique identifier strings
    CFUUIDRef newUniqueID = CFUUIDCreate(kCFAllocatorDefault);
    
    // Create a string from unique identifier
    CFStringRef newUniqueIDString =
    CFUUIDCreateString(kCFAllocatorDefault, newUniqueID);
    
    // Use that unique ID to set our possessions imageKey
    [possession setImageKey:(NSString *)newUniqueIDString];
    
    // We used "Create" in the functions to make objects, we need to release them
    CFRelease(newUniqueIDString);
    CFRelease(newUniqueID);
    
    // Store image in the ImageStore with this key
    [[ImageStore defaultImageStore] setImage:image 
                                      forKey:[possession imageKey]];
    
    // Put that image onto the screen in our image view
    [imageView setImage:image];
    
    [possession setThumbnailDataFromImage:image];
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];        
    } else {    
        [imagePickerPopover dismissPopoverAnimated:YES];
        [imagePickerPopover autorelease];
        imagePickerPopover = nil;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [imagePickerPopover autorelease];
    imagePickerPopover = nil;
}
- (IBAction)showAssetTypePicker:(id)sender
{
    [[self view] endEditing:YES];
    
    AssetTypePicker *assetTypePicker = [[[AssetTypePicker alloc] init] autorelease];
    [assetTypePicker setPossession:possession];
    
    [[self navigationController] pushViewController:assetTypePicker
                                           animated:YES];
}

- (void)dealloc
{
    [possession release];
    
    [nameField release];
    [serialNumberField release];
    [valueField release];
    [dateLabel release];
    
    [imageView release];
    
    [super dealloc];
}

@end
