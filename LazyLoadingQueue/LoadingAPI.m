//
//  LoadingAPI.m
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import "LoadingAPI.h"
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


//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    NSArray *arr = [change objectForKey:NSKeyValueChangeNewKey];
//    NSLog(@"%li", [arr count]);
//}

#pragma mark - Public

- (void)loadImage:(NSString *)name
              url:(NSURL *)url
        fromCache:(BOOL)fromCache
         progress:(void (^)(CGFloat))progress
          success:(void (^)(UIImage *loadedImage))success
          failure:(void (^)(NSError *))failure {
    
    
    // Main queue. TODO Check cache in background. Dependency?
    if (fromCache) {
        UIImage *cached = [_imageCache cachedImageForName:name];
        if (cached) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(cached);
            });
            return;
        }
    }
    
    LoadingOperation *operation =
    [[LoadingOperation alloc] initImageFromURL:url name:name progress:progress  success:^(UIImage *loadedImage) {
        [_imageCache storeImage:loadedImage name:name memory:YES local:NO];
        success(loadedImage);
    } failure:failure];
    
    __weak LoadingOperation *weakOperation = operation;
    [operation setCompletionBlock:^{
        if ([_activeOperations.allKeys containsObject:name]) {
            if (weakOperation.isFinished) {
//                NSLog(@"%@ completed", name);
                [_activeOperations removeObjectForKey:name];
            }
        }
    }];
    
    dispatch_sync(_queue, ^{
        [_activeOperations setObject:operation forKey:name];
        [_loadingQueue addOperation:operation];
    });
}

- (void)stopAllDownloads {
    [_loadingQueue setSuspended:YES];
    NSLog(@"Cancel all operations");
    
    [_activeOperations removeAllObjects];
    [_suspendedOperations removeAllObjects];
    
    [_loadingQueue cancelAllOperations];
    [_loadingQueue setSuspended:NO];
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
    
    NSLog(@"%@", (success) ? [NSString stringWithFormat:@"Resuming %@", name] : [NSString stringWithFormat:@"Loading %@", name]);
    return success;
}



#pragma mark - Lifecycle

- (id)init {
    self = [super init];
    if (self) {
        _imageCache = [[ImageCache alloc] init];
        _loadingQueue = [[NSOperationQueue alloc] init];
        [_loadingQueue setMaxConcurrentOperationCount:2];
        _activeOperations = [@{} mutableCopy];
        _suspendedOperations = [@{} mutableCopy];
        _queue = dispatch_queue_create("com.kittens.queue", NULL);
        
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm createDirectoryAtPath:[NSString stringWithFormat:@"%@/Downloads", NSTemporaryDirectory()]
      withIntermediateDirectories:NO
                       attributes:nil error:nil];
        
        //        [_loadingQueue addObserver:self
        //                        forKeyPath:@"operations"
        //                           options:NSKeyValueObservingOptionNew
        //                           context:nil];
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
