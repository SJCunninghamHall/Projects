#import "ItemsViewController.h"
#import "PossessionStore.h"
#import "Possession.h"
#import "ItemDetailViewController.h"
#import "HomepwnerItemCell.h"

@implementation ItemsViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        // Create a new bar button item that will send
        // addNewPossession: to ItemsViewController
        UIBarButtonItem *bbi = [[UIBarButtonItem alloc] 
                                initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                target:self 
                                action:@selector(addNewPossession:)];
        
        // Set this bar button item as the right item in the navigationItem
        [[self navigationItem] setRightBarButtonItem:bbi];
        
        // The navigationItem retains its buttons, so bbi can be released 
        [bbi release];
        
        // Set the title of the navigation item 
        [[self navigationItem] setTitle:@"Homepwner"];
    
        [[self navigationItem] setLeftBarButtonItem:[self editButtonItem]];
    }
    return  self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    return [self init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self tableView] reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (io == UIInterfaceOrientationPortrait);
    }
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section 
{
    return [[[PossessionStore defaultStore] allPossessions] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // Get instance of a HomepwnerItemCell - either an unused one or a new one.
    // The method returns a UITableViewCell; we typecast it as a HomepwnerItemCell.
    HomepwnerItemCell *cell = (HomepwnerItemCell *)[tableView
                        dequeueReusableCellWithIdentifier:@"HomepwnerItemCell"];
    
    if (!cell) {
        cell = [[[HomepwnerItemCell alloc]
                 initWithStyle:UITableViewCellStyleDefault
                 reuseIdentifier:@"HomepwnerItemCell"] autorelease];
    }
    
    NSArray *possessions = [[PossessionStore defaultStore] allPossessions];
    Possession *p = [possessions objectAtIndex:[indexPath row]];
    
    // Instead of setting each label directly, we pass it a possession object
    // it knows how to configure its own subviews
    [cell setPossession:p];
    
    return cell;
}

- (void)tableView:(UITableView *)aTableView 
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ItemDetailViewController *detailViewController = 
        [[[ItemDetailViewController alloc] initForNewItem:NO] autorelease];    

    NSArray *possessions = [[PossessionStore defaultStore] allPossessions];
    
    // Give detail view controller a pointer to the possession object in row
    [detailViewController setPossession:
                 [possessions objectAtIndex:[indexPath row]]];
    
    // Push it onto the top of the navigation controller's stack
    [[self navigationController] pushViewController:detailViewController
                                           animated:YES];
}

- (void)tableView:(UITableView *)tableView 
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
     forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // If the table view is asking to commit a delete command...
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        PossessionStore *ps = [PossessionStore defaultStore];
        NSArray *possessions = [ps allPossessions];
        Possession *p = [possessions objectAtIndex:[indexPath row]];
        [ps removePossession:p];
        
        // We also remove that row from the table view with an animation
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:YES];
    }
}

- (void)tableView:(UITableView *)tableView 
    moveRowAtIndexPath:(NSIndexPath *)fromIndexPath 
           toIndexPath:(NSIndexPath *)toIndexPath 
{
    [[PossessionStore defaultStore] movePossessionAtIndex:[fromIndexPath row]
                                                  toIndex:[toIndexPath row]];
}

- (void)itemDetailViewControllerWillDismiss:(ItemDetailViewController *)vc
{
    [[self tableView] reloadData];
}

- (IBAction)addNewPossession:(id)sender
{
    Possession *newPossession = [[PossessionStore defaultStore] createPossession];
    ItemDetailViewController *detailViewController = 
        [[ItemDetailViewController alloc] initForNewItem:YES];
    
    [detailViewController setDelegate:self];
    [detailViewController setPossession:newPossession];
    
    UINavigationController *navController = [[UINavigationController alloc] 
                                             initWithRootViewController:detailViewController];
    
    [detailViewController release];
    
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [navController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    
    // navController is retained by self when presented
    [self presentModalViewController:navController animated:YES];
    
    [navController release];
}

@end
