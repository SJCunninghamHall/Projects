#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface HypnosisView : UIView
{
    CALayer *boxLayer;
    UIColor *stripeColor;
    float xShift, yShift;
}

@property (nonatomic, assign) float xShift;
@property (nonatomic, assign) float yShift;

@end