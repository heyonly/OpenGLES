//
//  PresentVideoView.m
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "PresentVideoView.h"
#import "WaterFlowLayout.h"

@interface  PresentVideoView ()<UICollectionViewDataSource,UICollectionViewDelegate,WaterFlowLayoutDelgate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) WaterFlowLayout *layout;
@end

@implementation PresentVideoView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.layout = [[WaterFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:self.layout];
        
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _layout.delegate = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"reuseCell"];
        
        [self addSubview:_collectionView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame delegate:(id)delegate{
    if (self = [super initWithFrame:frame]) {
        self.layout = [[WaterFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:self.layout];
        
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _layout.delegate = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"reuseCell"];
        self.delegate = delegate;
        [self addSubview:_collectionView];
    }
    return self;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 20;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"reuseCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1.0];
    
    return cell;
}
- (CGFloat)waterFlowLayout:(nonnull WaterFlowLayout *)WaterFlowLayout heightForWidth:(CGFloat)width andIndexPath:(nonnull NSIndexPath *)indexPath {
    
    return 100/[[self rateForWidthDividedHeight][indexPath.row]floatValue];
}

- (NSArray *)rateForWidthDividedHeight {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"1" ofType:@".plist"];
    NSArray *images = [NSArray arrayWithContentsOfFile:path];
    __block NSMutableArray *rates = [NSMutableArray array];
    [images enumerateObjectsUsingBlock:^(NSDictionary *imageDic, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat w = [imageDic[@"w"] floatValue];
        CGFloat h = [imageDic[@"h"] floatValue];
        [rates addObject:@(w/h)];
    }];
    return rates;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"selected ..");
    [self.delegate collectionView:collectionView cellDidSelected:indexPath];
}



@end
