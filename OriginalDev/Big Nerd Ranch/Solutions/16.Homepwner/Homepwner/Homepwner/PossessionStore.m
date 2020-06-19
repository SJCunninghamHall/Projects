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

- (NSArray *)allPossessions
{
    // This ensures allPossessions is created
    [self fetchPossessionsIfNecessary];
    
    return allPossessions;
}

- (Possession *)createPossession
{
    // This ensures allPossessions is created
    [self fetchPossessionsIfNecessary];
    
    Possession *p = [Possession randomPossession];
    
    [allPossessions addObject:p];
    
    return p;
}

- (void)removePossession:(Possession *)p
{
    NSString *key = [p imageKey];
    [[ImageStore defaultImageStore] deleteImageForKey:key];
    
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
    
    // Retain it... (retain count of p = 2)
    [p retain];
    
    // Remove p from array, it is automatically sent release (retain count of p = 1)
    [allPossessions removeObjectAtIndex:from];
    
    // Insert p in array at new location, retained by array (retain count of p = 2)
    [allPossessions insertObject:p atIndex:to];
    
    // Release p (retain count = 1, only owner is now array)
    [p release];
}

- (NSString *)possessionArchivePath
{
    // The returned path will be Sandbox/Documents/possessions.data
    // Both the saving and loading methods will call this method to get the same path,
    // preventing a typo in the path name of either method
    
    return pathInDocumentDirectory(@"possessions.data");
}

- (BOOL)saveChanges
{
    // returns success or failure
    return [NSKeyedArchiver archiveRootObject:allPossessions 
                                       toFile:[self possessionArchivePath]];
}

- (void)fetchPossessionsIfNecessary
{
    // If we don't currently have an allPossessions array, try to read one from disk
    if (!allPossessions) {
        NSString *path = [self possessionArchivePath];
        allPossessions = [[NSKeyedUnarchiver unarchiveObjectWithFile:path] retain];
    }
    
    // If we tried to read one from disk but does not exist, then create a new one 
    if (!allPossessions) {
        allPossessions = [[NSMutableArray alloc] init];
    }
}

@end
