#import "CurrentTimeViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation CurrentTimeViewController

- (id)init
{
    // Call the superclass's designated initializer
    self = [super initWithNibName:@"CurrentTimeViewController"
                           bundle:nil];
    if (self) {
        // Get the tab bar item
        UITabBarItem *tbi = [self tabBarItem];
        
        // Give it a label
        [tbi setTitle:@"Time"];

        UIImage *i = [UIImage imageNamed:@"Time.png"];
        [tbi setImage:i];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle
{
    // Disregard parameters - implementation detail
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"Loaded the view for CurrentTimeViewController");
    
    [[self view] setBackgroundColor:[UIColor yellowColor]];
}

- (void)viewDidUnload
{
    NSLog(@"CurrentTimeViewController's view was unloaded due to memory warning");
    [super viewDidUnload];
    [timeLabel release];
    timeLabel = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"CurrentTimeViewController will appear");
    [super viewWillAppear:animated];
    [self showCurrentTime:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"CurrentTimeViewController will DISappear");
    [super viewWillDisappear:animated];
}

- (IBAction)showCurrentTime:(id)sender
{
    NSDate *now = [NSDate date];
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
    }
    [timeLabel setText:[formatter stringFromDate:now]];
    
    /*
    // Create a basic animation
    CABasicAnimation *spin =
    [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    
    // fromValue is implied
    [spin setToValue:[NSNumber numberWithFloat:M_PI * 2.0]];
    [spin setDuration:1.0];
    [spin setDelegate:self];
    
    // Set the timing function
    CAMediaTimingFunction *tf =  [CAMediaTimingFunction
                        functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [spin setTimingFunction:tf];
    
    // Kick off the animation by adding it to the layer
    [[timeLabel layer] addAnimation:spin
                             forKey:@"spinAnimation"];
     */
    
    // Create a key frame animation
    CAKeyframeAnimation *bounce =
    [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    // Create the values it will pass through
    CATransform3D forward = CATransform3DMakeScale(1.3, 1.3, 1);
    CATransform3D back = CATransform3DMakeScale(0.7, 0.7, 1);
    CATransform3D forward2 = CATransform3DMakeScale(1.2, 1.2, 1);
    CATransform3D back2 = CATransform3DMakeScale(0.9, 0.9, 1);
    [bounce setValues:[NSArray arrayWithObjects:
                       [NSValue valueWithCATransform3D:CATransform3DIdentity],
                       [NSValue valueWithCATransform3D:forward],
                       [NSValue valueWithCATransform3D:back],
                       [NSValue valueWithCATransform3D:forward2],
                       [NSValue valueWithCATransform3D:back2],
                       [NSValue valueWithCATransform3D:CATransform3DIdentity],
                       nil]];
    // Set the duration
    [bounce setDuration:0.6];
    
    // Animate the layer
    [[timeLabel layer] addAnimation:bounce
                             forKey:@"bounceAnimation"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSLog(@"%@ finished: %d", anim, flag);
}

- (void)dealloc
{
    [timeLabel release];
    [super dealloc];
}

@end
