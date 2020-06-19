#import <Foundation/Foundation.h>

@interface Possession : NSObject <NSCoding>
{
    NSString *possessionName;
    NSString *serialNumber;
    int valueInDollars;
    NSDate *dateCreated;
    NSString *imageKey;
    
    UIImage *thumbnail;
    NSData *thumbnailData;
}

+ (CGSize)thumbnailSize;

@property (readonly) UIImage *thumbnail;

- (void)setThumbnailDataFromImage:(UIImage *)image;

+ (id)randomPossession;

- (id)initWithPossessionName:(NSString *)name
              valueInDollars:(int)value
                serialNumber:(NSString *)sNumber;

- (id)initWithPossessionName:(NSString *)name;

@property (nonatomic, copy) NSString *possessionName;
@property (nonatomic, copy) NSString *serialNumber;
@property (nonatomic) int valueInDollars;
@property (nonatomic, readonly) NSDate *dateCreated;
@property (nonatomic, copy) NSString *imageKey;

@end
