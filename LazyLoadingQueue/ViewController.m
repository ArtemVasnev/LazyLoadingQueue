//
//  ViewController.m
//  LazyLoadingQueue
//
//  Created by Artem on 5/2/14.
//
//

#import "ViewController.h"
#import "KittenRecord.h"
#import "LoadingAPI.h"
#import "KittenCell.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate> {
    NSArray *_kittens;
    BOOL _fromCache;
}
- (NSArray *)kittens;
@end

@implementation ViewController

#pragma mark - Private

- (NSArray *)kittens {
    
    
    KittenRecord *record;
    NSMutableArray *kittens = [@[] mutableCopy];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Kittens" ofType:@"plist"];
    NSDictionary *kittensDict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    for (NSString *key in [kittensDict allKeys]) {
        record = [[KittenRecord alloc] initWithName:key
                                                url:[kittensDict objectForKey:key]];
        [kittens addObject:record];
    }
    
    return kittens;
}

#pragma mark - UICollectionView Data Source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_kittens count];
//    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    KittenCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell"
                                                                 forIndexPath:indexPath ];
    
    KittenRecord *record = [_kittens objectAtIndex:[indexPath row]];
    cell.titleLabel.text = [record name];
    cell.pictureImageView.image = record.kittenPic;
    cell.progressView.progress = [record loadingProgress];
    
    if (![record kittenPic]) {
        if (![[LoadingAPI sharedLoadingAPI] resumeImageLoading:record.name]) {
            cell.progressView.progress = 0.0f;

            [[LoadingAPI sharedLoadingAPI] loadImage:record.name url:record.picUrl fromCache:_fromCache progress:^(CGFloat progress) {
                record.loadingProgress = progress;
                KittenCell *actualCell = (KittenCell *)[collectionView cellForItemAtIndexPath:indexPath];
                actualCell.progressView.hidden = NO;
                actualCell.progressView.progress = progress;
            } success:^(UIImage *loadedImage) {
                
                if (indexPath == nil)
                    return;
                
                record.kittenPic = loadedImage;
                record.loadingProgress = 1.0f;
                KittenCell *actualCell = (KittenCell *)[collectionView cellForItemAtIndexPath:indexPath];
                actualCell.progressView.progress = 1.0;
                actualCell.pictureImageView.image = loadedImage;
            } failure:^(NSError *error) {
                if (indexPath == nil)
                    return;
                
                UIImage *image = [UIImage imageNamed:@"no_photo"];
                record.kittenPic = image;
                record.name = @"Loading error";
                KittenCell *actualCell = (KittenCell *)[collectionView cellForItemAtIndexPath:indexPath];
                actualCell.pictureImageView.image = image;
            }];
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    KittenRecord *record = [_kittens objectAtIndex:[indexPath row]];
    [[LoadingAPI sharedLoadingAPI] pauseImageLoading:record.name];
}


#pragma mark - Lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _fromCache = self.cacheSwitch.isOn;
    self.title = (_fromCache) ? @"From Cache" : @"From Web";
    _kittens = [self kittens];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    for (KittenRecord *rec in _kittens) {
        rec.kittenPic = nil;
    }
}

- (IBAction)switchCacheMode:(id)sender {
    _fromCache = [self.cacheSwitch isOn];
    self.title = (_fromCache) ? @"From Cache" : @"From Web";
}

- (IBAction)reloadKittens:(id)sender {
    [[LoadingAPI sharedLoadingAPI] stopAllDownloads];
    
    _kittens = nil;
    [self.kittensCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _kittens = [self kittens];
        [self.kittensCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    });
}
@end
