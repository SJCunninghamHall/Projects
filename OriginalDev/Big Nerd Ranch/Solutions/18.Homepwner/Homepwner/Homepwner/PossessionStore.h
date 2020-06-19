#import <CoreData/CoreData.h>

@class Possession;

@interface PossessionStore : NSObject
{
    NSMutableArray *allPossessions;
    NSMutableArray *allAssetTypes;
    NSManagedObjectContext *context;
    NSManagedObjectModel *model;
}

+ (PossessionStore *)defaultStore;
- (BOOL)saveChanges;

#pragma mark Possessions
- (NSArray *)allPossessions;
- (Possession *)createPossession;
- (void)removePossession:(Possession *)p;
- (void)movePossessionAtIndex:(int)from toIndex:(int)to;

#pragma mark Asset types
- (NSArray *)allAssetTypes;

@end
