//
//  UIImage+Decoder.m
//  LazyLoadingQueue
//
//  Created by Artem on 5/3/14.
//
//

#import "UIImage+Decompression.h"

@implementation UIImage (Decompression)

- (UIImage *)decomplessedImage {
    
    CGImageRef imageRef = self.CGImage;
    // System only supports RGB, set explicitly and prevent context error
    // if the downloaded image is not the supported format
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 CGImageGetWidth(imageRef),
                                                 CGImageGetHeight(imageRef),
                                                 8,
                                                 // width * 4 will be enough because are in ARGB format, don't read from the image
                                                 CGImageGetWidth(imageRef) * 4,
                                                 colorSpace,
                                                 // kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
                                                 // makes system don't need to do extra conversion when displayed.
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colorSpace);
    
    if ( ! context) {
        return nil;
    }
    
    
    CGRect rect = (CGRect){CGPointZero, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)};
    CGContextDrawImage(context, rect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *decompressedImage = [[UIImage alloc] initWithCGImage:decompressedImageRef];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}
@end
