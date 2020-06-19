//
//  Asset.h
//  BMITime
//
//  Created by Steve Cunningham on 17/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Employee;

@interface Asset : NSObject
{
    NSString *label;
    unsigned int resaleValue;
    __weak Employee *holder;
}

@property (strong) NSString *label;
@property (weak) Employee *holder;
@property unsigned int resaleValue;

@end
