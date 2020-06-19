#import <Foundation/Foundation.h>
#import "Possession.h"

int main (int argc, const char * argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Create a mutable array, store its address in items variable
    NSMutableArray *items = [[NSMutableArray alloc] init];

    for (int i = 0; i < 10; i++) {
        Possession *p = [Possession randomPossession];
        [items addObject:p];
    }

    for (Possession *item in items)
        NSLog(@"%@", item);

    // Release the array
    [items release];

    // Don't leave items pointing at freed memory!
    items = nil;

    [pool drain];
    return 0;
}
