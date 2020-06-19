//
//  RadioStation.h
//  RadioSimulation
//
//  Created by Team Cunningham on 20/02/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RadioStation : NSObject {
	
	NSString* name;
	double frequency;
	char band;

}

+ (double)minAMFrequency;
+ (double)maxAMFrequency;
+ (double)minFMFrequency;
+ (double)maxFMFrequency;

- (id)initWithName:(NSString*)name atFrequency:(double)freq;
- (NSString *)name;
- (void)setName:(NSString*)newName;
- (double)frequency;
- (void)setFrequency:(double)newFrequency;

@end
