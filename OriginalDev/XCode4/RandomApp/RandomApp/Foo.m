//
//  Foo.m
//  RandomApp
//
//  Created by Team Cunningham on 24/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Foo.h"


@implementation Foo

- (IBAction)generate:(id)sender
{
    // Generate a number between 1 and 100 inclusive
    
    int generated;
    
    generated = (random() % 100) + 1;
    
    NSLog(@"Generated = %d", generated);
    
    // Ask the text field to change what it is displaying
    
    [textField setIntValue:generated];
    
}

- (IBAction)seed:(id)sender
{
    // Seed the random number generator with the time
    
    srandom(time(NULL));
            
    [textField setStringValue:@"Generator seeded"];
    
}

- (void)awakeFromNib
{
    NSCalendarDate *now;
    now = [NSCalendarDate calendarDate];
    [textField setObjectValue:now];
}

@end
