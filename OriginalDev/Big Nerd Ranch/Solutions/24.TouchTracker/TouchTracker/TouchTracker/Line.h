#import <Foundation/Foundation.h>

@interface Line : NSObject
{
	CGPoint begin;
	CGPoint end;
    
    UIColor *color;
}
@property (nonatomic) CGPoint begin;
@property (nonatomic) CGPoint end;

@property (nonatomic, retain) UIColor *color;

@end
