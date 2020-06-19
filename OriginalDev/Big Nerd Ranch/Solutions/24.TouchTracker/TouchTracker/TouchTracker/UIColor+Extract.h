#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIColor (Extract)

- (void)extract_getRed:(float *)r green:(float *)g blue:(float *)b;
- (UIColor *)extract_invertedColor;

@end
