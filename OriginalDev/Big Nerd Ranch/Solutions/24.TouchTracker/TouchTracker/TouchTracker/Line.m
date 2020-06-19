#import "Line.h"

@implementation Line

@synthesize begin, end, color;

- (id)init
{
    self = [super init];
    
    if (self) {
        [self setColor:[UIColor blackColor]];
    }
    
    return self;
}

- (void)dealloc 
{
    [color release];
    [super dealloc];
}

@end
