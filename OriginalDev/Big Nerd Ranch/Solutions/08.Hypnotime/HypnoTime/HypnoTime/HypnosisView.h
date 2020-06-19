#import <Foundation/Foundation.h>


@interface HypnosisView : UIView
{
    UIColor *stripeColor;
    float xShift, yShift;
}

@property (nonatomic, assign) float xShift;
@property (nonatomic, assign) float yShift;

@end