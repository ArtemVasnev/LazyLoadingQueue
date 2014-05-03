//
//  LoadingOperation.h
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import <Foundation/Foundation.h>

typedef void (^OperationBlock) (void);
@interface LoadingOperation : NSOperation

- (void)suspend;

- (instancetype)initImageFromURL:(NSURL *)url
                            name:(NSString *)name
                        progress:(void (^)(CGFloat progress))progress
                         success:(void (^)(UIImage *loadedImage))success
                         failure:(void (^)(NSError *error))failure;


@end
