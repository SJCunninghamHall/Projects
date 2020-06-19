#import <Foundation/Foundation.h>
#import "ItemDetailViewController.h"

@interface ItemsViewController : UITableViewController
    <ItemDetailViewControllerDelegate>
{

}

- (IBAction)addNewPossession:(id)sender;

@end
