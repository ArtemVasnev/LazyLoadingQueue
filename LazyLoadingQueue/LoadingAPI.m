//
//  LoadingAPI.m
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import "LoadingAPI.h"
#import "ImageLoader.h"
#import "ImageCache.h"
#import "LoadingOperation.h"

static LoadingAPI *loadingAPI;

@interface LoadingAPI () {
    ImageCache *_imageCache;
    
    NSOperationQueue *_loadingQueue;
    NSMutableDictionary *_activeOperations;
    NSMutableDictionary *_suspendedOperations;
    
    dispatch_queue_t _queue;
}

@end

@implementation LoadingAPI

- (void)loadImage:(NSString *)name
              url:(NSURL *)url
        fromCache:(BOOL)fromCache
         progress:(void (^)(CGFloat))progress
          success:(void (^)(UIImage *loadedImage))success
          failure:(void (^)(NSError *))failure {
    
    
    if (fromCache) {
        UIImage *cached = [_imageCache cachedImageForName:name];
        if (cached) {
            NSLog(@"Cached");
            dispatch_async(dispatch_get_main_queue(), ^{
                success(cached);
            });
            return;
        }
    }
    
    LoadingOperation *operation = [[LoadingOperation alloc] initImageFromURL:url
                                                                        name:name
                                                                    progress:progress
                                   success:^(UIImage *loadedImage) {
                                       [_imageCache storeImage:loadedImage name:name memory:YES local:NO];
                                       success(loadedImage);
                                   } failure:failure];
    
    __weak LoadingOperation *weakOperation = operation;
    [operation setCompletionBlock:^{
        NSLog(@"%@ completed", name);
        if ([_activeOperations.allKeys containsObject:name]) {
            if (weakOperation.isFinished) {
                [weakOperation cancel];
                [_activeOperations removeObjectForKey:name];
            }
        }
    }];
    
    [_activeOperations setObject:operation forKey:name];
    [_loadingQueue addOperation:operation];
}

- (void)stopAllDownloads {
    NSLog(@"Cancel all operations");
    
    [_activeOperations.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        LoadingOperation *operation = [_activeOperations objectForKey:key];
        [operation performSelectorOnMainThread:@selector(cancel) withObject:nil waitUntilDone:NO];
    }];
    
    [_suspendedOperations.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        LoadingOperation *operation = [_suspendedOperations objectForKey:key];
        [operation performSelectorOnMainThread:@selector(cancel) withObject:nil waitUntilDone:NO];
    }];
    
    [_activeOperations removeAllObjects];
    [_suspendedOperations removeAllObjects];
    
    [_loadingQueue cancelAllOperations];
}

- (void)pauseImageLoading:(NSString *)name {
    
    dispatch_sync(_queue, ^{
        if ([_activeOperations.allKeys containsObject:name]) {
            LoadingOperation *operation = (LoadingOperation *)[_activeOperations objectForKey:name];
            
            if (operation.isExecuting){
                NSLog(@"Suspending %@", name);
                [operation setQueuePriority:NSOperationQueuePriorityLow];
                [_suspendedOperations setObject:operation forKey:name];
                [_activeOperations removeObjectForKey:name];
                [operation performSelectorOnMainThread:@selector(suspend) withObject:nil waitUntilDone:NO];
            }
        }
    });
}

- (BOOL)resumeImageLoading:(NSString *)name {
    __block BOOL success = NO;
    dispatch_sync(_queue, ^{
        if ([_suspendedOperations.allKeys containsObject:name]) {
            LoadingOperation *operation = (LoadingOperation *)[_suspendedOperations objectForKey:name];
            if (!operation.isExecuting) {
                [operation setQueuePriority:NSOperationQueuePriorityHigh];
                [_activeOperations setObject:operation forKey:name];
                [_suspendedOperations removeObjectForKey:name];
                [operation performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
                success = YES;
            }
        }
    });
    
    //    NSLog(@"%@", (success) ? [NSString stringWithFormat:@"Resuming %@", name] : [NSString stringWithFormat:@"Load %@", name]);
    return success;
}



#pragma mark - Lifecycle

- (id)init {
    self = [super init];
    if (self) {
        _imageCache = [[ImageCache alloc] init];
        _loadingQueue = [[NSOperationQueue alloc] init];
        [_loadingQueue setMaxConcurrentOperationCount:4];
        _activeOperations = [@{} mutableCopy];
        _suspendedOperations = [@{} mutableCopy];
        _queue = dispatch_queue_create("com.kittens.queue", NULL);
        
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm createDirectoryAtPath:[NSString stringWithFormat:@"%@/Downloads", NSTemporaryDirectory()]
      withIntermediateDirectories:NO
                       attributes:nil error:nil];
    }
    return self;
}

#pragma mark Access
+ (instancetype)sharedLoadingAPI {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loadingAPI = [[LoadingAPI alloc] init];
    });
    return loadingAPI;
}

@end
