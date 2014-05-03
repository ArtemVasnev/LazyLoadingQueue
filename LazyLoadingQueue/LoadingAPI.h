//
//  LoadingAPI.h
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import <Foundation/Foundation.h>

@interface LoadingAPI : NSObject

- (void)loadImage:(NSString *)name
              url:(NSURL *)url
          fromCache:(BOOL)fromCache
         progress:(void (^)(CGFloat progress))progress
          success:(void (^)(UIImage *loadedImage))success
          failure:(void (^)(NSError *error))failure;

- (void)stopAllDownloads;
- (void)pauseImageLoading:(NSString *)name;
- (BOOL)resumeImageLoading:(NSString *)name;

+ (instancetype)sharedLoadingAPI;
@end
