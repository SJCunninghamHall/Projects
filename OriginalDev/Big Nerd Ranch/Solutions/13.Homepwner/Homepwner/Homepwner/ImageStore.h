#import <Foundation/Foundation.h>


@interface ImageStore : NSObject
{
    NSMutableDictionary *dictionary;
}

+ (ImageStore *)defaultImageStore;

- (void)setImage:(UIImage *)i forKey:(NSString *)s;
- (UIImage *)imageForKey:(NSString *)s;
- (void)deleteImageForKey:(NSString *)s;

@end
