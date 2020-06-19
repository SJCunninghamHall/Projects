#import "PossessionStore.h"
#import "Possession.h"
#import "ImageStore.h"

static PossessionStore *defaultStore = nil;

@implementation PossessionStore

+ (PossessionStore *)defaultStore
{
    if (!defaultStore) {
        // Create the singleton
        defaultStore = [[super allocWithZone:NULL] init];
    }
    return defaultStore;
}

// Prevent creation of additional instances
+ (id)allocWithZone:(NSZone *)zone
{
    return [self defaultStore];
}

- (id)init
{
    // If we already have an instance of PossessionStore...
    if (defaultStore) {
        
        // Return the old one
        return defaultStore;
    }
    
    self = [super init];
    // Read in Homepwner.xcdatamodeld
    model = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    // NSLog(@"model = %@", model);
    
    NSPersistentStoreCoordinator *psc = 
    [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    // Where does the SQLite file go?    
    NSString *path = pathInDocumentDirectory(@"store.data");
    NSURL *storeURL = [NSURL fileURLWithPath:path]; 
    
    NSError *error = nil;
    
    if (![psc addPersistentStoreWithType:NSSQLiteStoreType 
                           configuration:nil
                                     URL:storeURL
                                 options:nil
                                   error:&error]) {
        [NSException raise:@"Open failed"
                    format:@"Reason: %@", [error localizedDescription]];
    }
    
    // Create the managed object context
    context = [[NSManagedObjectContext alloc] init];
    [context setPersistentStoreCoordinator:psc];
    [psc release];
    
    // The managed object context can manage undo, but we don't need it
    [context setUndoManager:nil];
    return self;
}

- (id)retain
{
    // Do nothing
    return self;
}

- (void)release
{
    // Do nothing
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;
}

- (BOOL)saveChanges
{
    NSError *err = nil;
    BOOL successful = [context save:&err];
    if (!successful) {
        NSLog(@"Error saving: %@", [err localizedDescription]);
    }
    return successful;
}

- (void)fetchPossessionsIfNecessary
{
    if (!allPossessions) {
        NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
        
        NSEntityDescription *e = [[model entitiesByName] objectForKey:@"Possession"];
        [request setEntity:e];
        
        NSSortDescriptor *sd = [NSSortDescriptor 
                                sortDescriptorWithKey:@"orderingValue"
                                ascending:YES];
        [request setSortDescriptors:[NSArray arrayWithObject:sd]];
        
        NSError *error;
        NSArray *result = [context executeFetchRequest:request error:&error];
        if (!result) {
            [NSException raise:@"Fetch failed"
                        format:@"Reason: %@", [error localizedDescription]];
        }
        
        allPossessions = [[NSMutableArray alloc] initWithArray:result];
    }
}

- (NSArray *)allPossessions
{
    // This ensures allPossessions is created
    [self fetchPossessionsIfNecessary];
    
    return allPossessions;
}

- (Possession *)createPossession
{
    // Ensure the array is initialized
    [self fetchPossessionsIfNecessary];
    
    double order;
    if ([allPossessions count] == 0) {
        order = 1.0;
    } else {
        order = [[[allPossessions lastObject] orderingValue] doubleValue] + 1.0;
    }
    NSLog(@"Adding after %d items, order = %.2f",[allPossessions count], order);
    
    Possession *p = [NSEntityDescription insertNewObjectForEntityForName:@"Possession"
                                                  inManagedObjectContext:context];
    
    [p setOrderingValue:[NSNumber numberWithDouble:order]];
    
    [allPossessions addObject:p];
    
    return p;
}

- (void)removePossession:(Possession *)p
{
    NSString *key = [p imageKey];
    [[ImageStore defaultImageStore] deleteImageForKey:key];
    [context deleteObject:p];
    [allPossessions removeObjectIdenticalTo:p];
}

- (void)movePossessionAtIndex:(int)from
                      toIndex:(int)to
{
    if (from == to) {
        return;
    }
    // Get pointer to object being moved
    Possession *p = [allPossessions objectAtIndex:from];
    
    // Retain it so it doesn't get dealloced while out of array
    [p retain];
    
    // Remove p from our array
    [allPossessions removeObjectAtIndex:from];
    
    // Re-insert p into array at new location
    [allPossessions insertObject:p atIndex:to];
    
    // Computing a new orderValue for the object that was moved
    double lowerBound = 0.0;
    
    // Is there an object before it in the array?
    if (to > 0) {
        lowerBound = [[[allPossessions objectAtIndex:to - 1] 
                       orderingValue] doubleValue];
    } else {
        lowerBound = [[[allPossessions objectAtIndex:1] 
                       orderingValue] doubleValue] - 2.0;
    }
    
    double upperBound = 0.0;
    
    // Is there an object after it in the array?
    if (to < [allPossessions count] - 1) {
        upperBound = [[[allPossessions objectAtIndex:to + 1] 
                       orderingValue] doubleValue];
    } else {
        upperBound = [[[allPossessions objectAtIndex:to - 1] 
                       orderingValue] doubleValue] + 2.0;
    }
    
    // The order value will be the midpoint between the lower and upper bounds
    NSNumber *newOrderValue = [NSNumber numberWithDouble:(lowerBound + upperBound)/2.0];
    
    NSLog(@"moving to order %@", newOrderValue);
    [p setOrderingValue:newOrderValue];
    
    // Release p (retain count = 1, only owner is now array)
    [p release];
    
}

- (NSArray *)allAssetTypes
{
    if (!allAssetTypes) {
        NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
        
        NSEntityDescription *e = [[model entitiesByName] objectForKey:@"AssetType"];
        
        [request setEntity:e];
        
        NSError *error;
        NSArray *result = [context executeFetchRequest:request error:&error];
        if (!result) {
            [NSException raise:@"Fetch failed"
                        format:@"Reason: %@", [error localizedDescription]];
        }
        allAssetTypes = [result mutableCopy];
    }
    
    // Is this the first time the program is being run?
    if ([allAssetTypes count] == 0) {
        NSManagedObject *type;
        
        type = [NSEntityDescription insertNewObjectForEntityForName:@"AssetType" 
                                             inManagedObjectContext:context];
        [type setValue:@"Furniture" forKey:@"label"];
        [allAssetTypes addObject:type];
        
        type = [NSEntityDescription insertNewObjectForEntityForName:@"AssetType"  
                                             inManagedObjectContext:context];
        [type setValue:@"Jewelry" forKey:@"label"];
        [allAssetTypes addObject:type];
        
        type = [NSEntityDescription insertNewObjectForEntityForName:@"AssetType" 
                                             inManagedObjectContext:context];
        [type setValue:@"Electronics" forKey:@"label"];
        [allAssetTypes addObject:type];
        
    }
    return allAssetTypes;
}

@end
