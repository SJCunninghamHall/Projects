#import "QuizAppDelegate.h"


@implementation QuizAppDelegate

@synthesize window=_window;

- (id)init
{
    // Call the init method implemented by the superclass
    self = [super init];
    if (self) {
        // Create two new arrays and make the pointers point to them
        questions = [[NSMutableArray alloc] init];
        answers = [[NSMutableArray alloc] init];
        
        //Add questions and answers to the array
        [questions addObject:@"What is 7 + 7??"];
        [answers addObject:@"14"];
        
        [questions addObject:@"What is the capital of Vermont?"];
        [answers addObject:@"Ya got me there.."];
        
        [questions addObject:@"From what is cognac made?"];
        [answers addObject:@"Grapes"];
    }
    // Return the address of the new object
    return self;
}

- (IBAction)showQuestion:(id)sender
{
    // Step to the next question
    currentQuestionIndex++;
    
    // Am I past the last question?
    if (currentQuestionIndex == [questions count]) {
        // Go back to the first question
        currentQuestionIndex = 0;
    }
    
    // Gets the string at the index in the questions array
    NSString *question = [questions objectAtIndex:currentQuestionIndex];
    
    // Log the string to the console
    NSLog(@"displaying question: %@", question);
    
    // Display the string in the question field
    [questionField setText:question];
    
    // Clear the answer field
    [answerField setText:@"???"];
}

- (IBAction)showAnswer:(id)sender
{
    // What is the answer to the current question?
    NSString *answer = [answers objectAtIndex:currentQuestionIndex];
    
    // Display it in the answer field
    [answerField setText:answer];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[self window] makeKeyAndVisible];
    return YES;
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

@end
