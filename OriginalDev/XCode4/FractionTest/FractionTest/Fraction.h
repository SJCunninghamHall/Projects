//
//  Fraction.h
//  FractionTest
//
//  Created by Steve Cunningham on 01/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Fraction : NSObject
{
    int numerator;
    int denominator;
}

@property int numerator, denominator;

-(void)     print;
-(void)     setTo: (int) n over: (int) d;
-(double)   convertToNum;

@end
