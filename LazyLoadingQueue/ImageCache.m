//
//  ImageCache.m
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import "ImageCache.h"

@interface ImageCache () {
    NSCache *_memoryCache;
}

@end

@implementation ImageCache

#pragma mark - Public

- (UIImage *)cachedImageForName:(NSString *)imageName {
    return [_memoryCache objectForKey:imageName];
}

- (void)storeImage:(UIImage *)image name:(NSString *)name memory:(BOOL)memory local:(BOOL)local {
    

    if (memory) {
//        NSLog(@"%@ stored", name);
        [_memoryCache setObject:image forKey:name];
    }
    
    if (local) {
        
    }
}

#pragma mark - Lifecycle

- (id)init {
    self = [super init];
    if (self) {
        _memoryCache = [[NSCache alloc] init];
    }
    return self;
}

@end
