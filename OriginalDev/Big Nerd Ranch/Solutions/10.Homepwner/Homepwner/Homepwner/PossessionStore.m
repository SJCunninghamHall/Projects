#import "PossessionStore.h"
#import "Possession.h"

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
    if (self) {
        allPossessions = [[NSMutableArray alloc] init];
    }
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
    return allPossessions;
}

- (Possession *)createPossession
{
    Possession *p = [Possession randomPossession];
    
    [allPossessions addObject:p];
    
    return p;
}

@end
