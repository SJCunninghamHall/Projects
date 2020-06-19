//
//  Fraction.m
//  FractionTest
//
//  Created by Steve Cunningham on 01/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Fraction.h"

@implementation Fraction

@synthesize numerator, denominator;

-(void) print
{
    NSLog(@"%i/%i", numerator, denominator);
}


-(double) convertToNum
{
    if (denominator != 0)
        return (double) numerator / denominator;
    else
        return 1.0;
}

-(void) setTo:(int)n over:(int)d
{
    numerator = n;
    denominator = d;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

@end
