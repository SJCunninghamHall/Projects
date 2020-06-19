//
//  Sale.h
//  Bookstore
//
//  Created by Team Cunningham on 16/02/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Sale : NSObject {
	
	NSString* customer;
	NSString* book;
	NSString* date;
	NSString* time;
	NSString* amount;
	NSString* paymentType;

}

-(NSArray *) chargeCreditCard;
-(NSArray *) printInvoice;
-(NSArray *) checkout;

@end
