//
//  ImageCache.h
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import <Foundation/Foundation.h>

@interface ImageCache : NSObject

- (UIImage *)cachedImageForName:(NSString *)imageName;
- (void)storeImage:(UIImage *)image name:(NSString *)name memory:(BOOL)memory local:(BOOL)local;

@end
