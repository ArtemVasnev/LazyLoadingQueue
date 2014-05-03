//
//  KittenRecord.h
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import <Foundation/Foundation.h>

@interface KittenRecord : NSObject
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) UIImage *kittenPic;
@property (copy, nonatomic) NSURL *picUrl;
@property (assign) CGFloat loadingProgress;

- (instancetype)initWithName:(NSString *)name url:(NSString *)url;
@end
