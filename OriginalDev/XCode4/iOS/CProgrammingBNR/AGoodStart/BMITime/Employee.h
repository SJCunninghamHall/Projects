//
//  Employee.h
//  BMITime
//
//  Created by Steve Cunningham on 17/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Person.h"
@class Asset;

@interface Employee : Person
{
    int employeeID;
    NSMutableArray *assets;
}

@property int employeeId;

- (void)addAssetsObject:(Asset *)a;
- (unsigned int)valueOfAssets;

@end
