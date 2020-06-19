//
//  Pictures.h
//  PictureList
//
//  Created by Simon Green on 08/12/2011.
//  Copyright (c) 2011 SiJack Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Pictures : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSData * smallPicture;
@property (nonatomic, retain) NSString * title;

@end
