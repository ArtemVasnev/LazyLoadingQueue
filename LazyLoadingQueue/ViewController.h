//
//  ViewController.h
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UICollectionView *kittensCollectionView;
@property (weak, nonatomic) IBOutlet UISwitch *cacheSwitch;


- (IBAction)switchCacheMode:(id)sender;
- (IBAction)reloadKittens:(id)sender;

@end
