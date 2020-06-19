#import <Foundation/Foundation.h>
#import "HelloWorld.h"
#import "GreetingsProfessorFalken.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    // insert code here...

	HelloWorld* myObject = [[HelloWorld alloc] init];
	
	[myObject printGreeting];
	[myObject release];
	
	GreetingsProfessorFalken* mySecondObject = [[GreetingsProfessorFalken alloc] init];
	
	[mySecondObject printGreetingsProfessorFalken];
	
	[mySecondObject printWouldntYouPreferAGoodGameOfChess];
	
	[mySecondObject release];
	
    [pool drain];
    return 0;
}
