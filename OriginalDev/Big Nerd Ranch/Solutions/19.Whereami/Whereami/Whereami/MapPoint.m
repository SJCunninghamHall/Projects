#import "MapPoint.h"

@implementation MapPoint

@synthesize coordinate, title;

- (id)initWithCoordinate:(CLLocationCoordinate2D)c title:(NSString *)t
{
    self = [super init];
    if (self) {
        coordinate = c;
        [self setTitle:t];
    }
    return self;
}

- (void)dealloc
{
    [title release];
    [super dealloc];
}

@end
