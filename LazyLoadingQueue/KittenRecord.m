//
//  KittenRecord.m
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import "KittenRecord.h"

@implementation KittenRecord

#pragma mark - Lifecycle

- (instancetype)initWithName:(NSString *)name url:(NSString *)url {
    self = [super init];
    if (self) {
        _name = [name copy];
        _picUrl = [NSURL URLWithString:url];
    }
    return self;
}

@end
