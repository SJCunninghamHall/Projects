//
//  Customer.h
//  Bookstore
//
//  Created by Team Cunningham on 16/02/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Customer : NSObject {
	
	NSString* firstName;
	NSString* lastName;
	NSString* addressLine1;
	NSString* addressLine2;
	NSString* city;
	NSString* state;
	NSString* zip;
	NSString* phoneNumber;
	NSString* emailAddress;
	NSString* favouriteGenre;

}

-(NSArray *) listPurchaseHistory;

@end
