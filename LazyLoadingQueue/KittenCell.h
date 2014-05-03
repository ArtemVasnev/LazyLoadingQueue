//
//  KittenCell.h
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import <UIKit/UIKit.h>

@interface KittenCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *pictureImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
