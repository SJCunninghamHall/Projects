//
//  Book.h
//  Bookstore
//
//  Created by Team Cunningham on 16/02/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Book : NSObject {
	
	NSString* author;
	NSString* publisher;
	NSString* genre;
	NSString* yearPublished;
	NSString* numberOfPages;
	NSString* edition;
	NSString* price;

}

@end
