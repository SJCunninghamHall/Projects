//
//  Possession.h
//  RandomPossessions
//
//  Created by Steve Cunningham on 10/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Possession : NSObject
{
    NSString *possessionName;
    NSString *serialNumber;
    int valueInDollars;
    NSDate *dateCreated;
}

+ (id)randomPossession;

// Work on designated initializer
- (id)initWithPossessionName:(NSString *)name
              valueInDollars:(int)value
                serialNumber:(NSString *)sNumber;

// Getter possessionName
- (NSString *)possessionName;
// Setter possessionName
- (void)setPossessionName:(NSString *)newPossessionName;

// Getter serialNumber
- (NSString *)serialNumber;
// Setter serialNumber
- (void)setSerialNumber:(NSString *)newSerialNumber;

// Getter valueInDollars
- (int)valueInDollars;
// Setter valueInDollars
- (void)setValueInDollars:(int)newValueInDollars;

// Getter dateCreated
- (NSDate *)dateCreated;

@end
