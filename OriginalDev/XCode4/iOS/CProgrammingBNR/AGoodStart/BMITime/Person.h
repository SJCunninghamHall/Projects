//
//  Person.h
//  BMITime
//
//  Created by Steve Cunningham on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject
{
    //It has two instance variables
    float heightInMeters;
    int weightInKilos;
}
@property float heightInMeters;
@property int weightInKilos;

// This method will calculate the Body Mass Index
- (float)bodyMassIndex;

@end
