//
//  AppDelegate.h
//  PictureList
//
//  Created by Simon from Maybelost.com
//
//  If you use this code, it'd be awesome if you'd give a mention to my blog
//  site so that others may also get some use from the tutorials. It's not
//  mandatory of course, but it'll give you a warm fuzzy feeling inside.
//



#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
