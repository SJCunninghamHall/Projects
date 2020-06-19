#import "Possession.h"

@implementation Possession
@dynamic serialNumber;
@dynamic valueInDollars;
@dynamic thumbnail;
@dynamic imageKey;
@dynamic dateCreated;
@dynamic possessionName;
@dynamic thumbnailData;
@dynamic orderingValue;
@dynamic assetType;


- (void)awakeFromFetch
{
    [super awakeFromFetch];
    
    UIImage *tn = [UIImage imageWithData:[self thumbnailData]];
    [self setPrimitiveValue:tn forKey:@"thumbnail"];
}

- (void)awakeFromInsert 
{
    [super awakeFromInsert];
    [self setDateCreated:[NSDate date]];
}

- (void)setThumbnailDataFromImage:(UIImage *)image
{
    CGSize origImageSize = [image size];
    
    CGRect newRect;
    newRect.origin = CGPointZero;
    newRect.size = [[self class] thumbnailSize];
    
    float ratio = MAX(newRect.size.width/origImageSize.width, 
                      newRect.size.height/origImageSize.height);
    
    // Create a bitmap image context
    UIGraphicsBeginImageContext(newRect.size);
    
    // Round the corners
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:newRect
                                                    cornerRadius:5.0];
    [path addClip];
    
    // Into what rectangle shall I composite the image?
    CGRect projectRect;
    projectRect.size.width = ratio * origImageSize.width;
    projectRect.size.height = ratio * origImageSize.height;
    projectRect.origin.x = (newRect.size.width - projectRect.size.width) / 2.0;
    projectRect.origin.y = (newRect.size.height - projectRect.size.height) / 2.0;
    
    // Draw the image on it
    [image drawInRect:projectRect];
    
    // Get the image from the image context, retain it as our thumbnail
    UIImage *small = UIGraphicsGetImageFromCurrentImageContext();
    [self setThumbnail:small];
    
    // Get the image as a PNG data
    NSData *data = UIImagePNGRepresentation(small);
    [self setThumbnailData:data];
    
    // Cleanup image contex resources, we're done
    UIGraphicsEndImageContext();
}

+ (CGSize)thumbnailSize
{  
    return CGSizeMake(40, 40);
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ (%@): Worth $%@, Recorded on %@",
            [self possessionName], 
            [self serialNumber], [self valueInDollars], [self dateCreated]];
}

@end
