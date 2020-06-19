//
//  main.m
//  FractionTest
//
//  Created by Steve Cunningham on 01/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Fraction.h"

int main (int argc, const char * argv[])
{

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    Fraction *aFraction = [[Fraction alloc] init];
    
    [aFraction setTo:100 over:300];
    
    NSLog(@"The value of myFraction is: ");
    [aFraction print];
    
    [aFraction setTo:1 over:3];
    [aFraction print];
    
    [aFraction release];

    [pool drain];
    return 0;
}

