//
//  LoadingOperation.m
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import "LoadingOperation.h"
#import "UIImage+Decompression.h"

typedef void (^ProgressBlock) (CGFloat);
typedef void (^SuccessBlock) (UIImage *loadedImage);
typedef void (^FailureBlock) (NSError *);

@interface LoadingOperation () <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    ProgressBlock progressBlock;
    SuccessBlock successBlock;
    FailureBlock failureBlock;
    
    NSUInteger _expectedDataLenght;
    NSMutableData *_responseData;
    
    NSURL *_url;
    NSURLConnection *_connection;
    NSString *_filePath;
    NSString *_name;
    
    BOOL _executing;
    BOOL _finished;
    
}

@end

@implementation LoadingOperation

#pragma mark - Overrides

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return _executing;
}

- (BOOL)isFinished {
    return _finished;
}

#pragma mark - Control

- (void)start {
    
    if ([self isExecuting])
        return;
    
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    _finished = NO;
    _executing = YES;
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)cancel {
    
    [_connection cancel];
    _connection = nil;
    
    _responseData = nil;
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _executing = NO;
    _finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    
    [super cancel];
}

- (void)suspend {
    [_responseData writeToFile:_filePath
                    atomically:YES];
    [self cancel];
}

- (void)main {
    @autoreleasepool {
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:_url
                                                                    cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                                timeoutInterval:0];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:_filePath])
            _responseData = [[NSMutableData alloc] initWithContentsOfFile:_filePath];
        
        if (!_responseData)
            _responseData = [[NSMutableData alloc] init];
        
        if (_responseData.length > 0) {
            NSString *requestRange = [NSString stringWithFormat:@"bytes=%lu-", _responseData.length];
            [request setValue:requestRange forHTTPHeaderField:@"Range"];
        }
        
        _connection = [[NSURLConnection alloc] initWithRequest:request
                                                      delegate:self
                                              startImmediately:NO];
        [_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [_connection start];
        CFRunLoopRun();
    }
}

#pragma mark - NSURLConnection

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _expectedDataLenght = [response expectedContentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
    CGFloat progress = (float)_responseData.length / (float) _expectedDataLenght;
    dispatch_async(dispatch_get_main_queue(), ^{
        progressBlock(progress);
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    UIImage *image = [[UIImage alloc] initWithData:_responseData];
    _responseData = nil;
    UIImage *decompressedImage = [image decomplessedImage];
    
    [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (decompressedImage) {
            successBlock(decompressedImage);
        } else {
            failureBlock(nil);
        }
        
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
    });
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%@ Fail: %@", _name, [error localizedDescription]);
    dispatch_async(dispatch_get_main_queue(), ^{
        failureBlock(error);
    });
}


#pragma mark - Lifecycle

- (instancetype)initImageFromURL:(NSURL *)url
                            name:(NSString *)name
                        progress:(void (^)(CGFloat progress))progress
                         success:(void (^)(UIImage *))success
                         failure:(void (^)(NSError *))failure {
    
    self = [super init];
    if (self) {
        
        progressBlock = progress;
        successBlock = success;
        failureBlock = failure;
        
        _responseData = [[NSMutableData alloc] init];
        _name = [name copy];
        _url = url;
        _filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Downloads/%@", name]];
    }
    return self;
}

@end
