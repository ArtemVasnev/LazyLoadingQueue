//
//  LoadingOperation.m
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import "LoadingOperation.h"

typedef void (^ProgressBlock) (CGFloat);
typedef void (^SuccessBlock) (UIImage *loadedImage);
typedef void (^ErrorBlock) (NSError *);

@interface LoadingOperation () <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    ProgressBlock progressBlock;
    SuccessBlock successBlock;
    ErrorBlock errorBlock;
    
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
    _finished = NO;
    [self didChangeValueForKey:@"isFinished"];
    
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    NSLog(@"Start");
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:_url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                            timeoutInterval:0];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:_filePath]) {
        _responseData = [[NSMutableData alloc] initWithContentsOfFile:_filePath];
    } else {
        _responseData = [[NSMutableData alloc] init];
        
        if (![fm createFileAtPath:_filePath contents:nil attributes:nil])
        {
            NSLog(@"cannot create file");
        }
    }
    
    if (_responseData.length > 0) {
        NSString *requestRange = [NSString stringWithFormat:@"bytes=%lu-", _responseData.length];
        [request setValue:requestRange forHTTPHeaderField:@"Range"];
    }
    
    _connection = [[NSURLConnection alloc] initWithRequest:request
                                                  delegate:self
                                          startImmediately:NO];
    [_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_connection start];
    // so that our connection events get processed even if a scrollview blocks the main run loop
    CFRunLoopRun();
}

- (void)cancel {
    
    [_connection cancel];
    _connection = nil;
    
    _responseData = nil;
    
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self willChangeValueForKey:@"isFinished"];
    _finished = YES;
    [self didChangeValueForKey:@"isFinished"];
    
    NSLog(@"Cancel");
    [super cancel];
    
}

- (void)suspend {
    [_responseData writeToFile:_filePath
                    atomically:YES];
    [self cancel];
}

#pragma mark - NSURLConnection

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%@ Fail: %@", _name, [error localizedDescription]);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _expectedDataLenght = [response expectedContentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progress = (float)_responseData.length / (float) _expectedDataLenght;
        progressBlock(progress);
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    /*
     CFDataRef imgData = (__bridge CFDataRef)_responseData;
     CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData (imgData);
     CGImageRef image = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
     CGDataProviderRelease(imgDataProvider);
     */
    //    [_responseData writeToFile:_filePath atomically:YES];
    UIImage *image = [[UIImage alloc] initWithData:_responseData];
    _responseData = nil;
    
    [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        successBlock(image);
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        
        [self cancel];
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
        errorBlock = failure;
        
        _responseData = [[NSMutableData alloc] init];
        _name = [name copy];
        _url = url;
        _filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Downloads/%@", name]];
        
    }
    return self;
}




@end
