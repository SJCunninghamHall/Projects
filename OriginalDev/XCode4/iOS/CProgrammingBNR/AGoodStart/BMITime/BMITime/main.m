//
//  main.m
//  BMITime
//
//  Created by Steve Cunningham on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Person.h"
#import "Employee.h"
#import "Asset.h"

int main (int argc, const char * argv[])
{

    @autoreleasepool
    {
        
        // Create an array of employee objects
        NSMutableArray *employees = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < 10; i++)
        {
        
            // Create an intance of Person
            
            Employee *person = [[Employee alloc] init];
            
            // Give the instance variables interesting values
            [person setWeightInKilos:90 + i];
            [person setHeightInMeters:1.8 - i/10.0];
            [person setEmployeeId:i];
            
            // Put the employee in the employees array
        
            [employees addObject:person];
            
        }
        
        NSMutableArray *allAssets = [[NSMutableArray alloc] init];
        
        // Create 10 assets
        for (int i = 0; i < 10; i++)
        {
            // Create an asset
            Asset *asset = [[Asset alloc] init];
            
            // Give it an interesting label
            NSString *currentLabel = [NSString stringWithFormat:@"Laptop %d", i];
            
            [asset setLabel:currentLabel];
            [asset setResaleValue:i * 17];
            
            // Get a random number between 0 and 9 inclusive
            
            NSUInteger randomIndex = random() % [employees count];
            
            // Find that employee
            Employee *randomEmployee = [employees objectAtIndex:randomIndex];
            
            // Assign the asset to the employee
            [randomEmployee addAssetsObject:asset];
            
            [allAssets addObject:asset];
            
        }
            
        NSLog(@"Employees: %@", employees);
        
        NSLog(@"Giving up ownership of one employee");
        
        [employees removeObjectAtIndex:5];
        
        NSLog(@"allAssets: %@", allAssets);
        
        NSLog(@"Giving up ownership of array");
        
        allAssets = nil;
        employees = nil;
        
    }
    sleep(100);
    return 0;
}

