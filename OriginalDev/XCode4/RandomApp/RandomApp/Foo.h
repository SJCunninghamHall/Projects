//
//  Foo.h
//  RandomApp
//
//  Created by Team Cunningham on 24/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Foo : NSObject {
    IBOutlet NSTextField *textField;
    
}

- (IBAction)seed:(id)sender;
- (IBAction)generate:(id)sender;

@end
