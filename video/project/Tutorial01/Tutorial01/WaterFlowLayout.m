//
//  WaterFlowLayout.m
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "WaterFlowLayout.h"

@interface WaterFlowLayout ()
@property (nonatomic, strong) NSMutableDictionary *maxYDic;

@property (nonatomic, strong) NSMutableArray *attrsArray;

@end


@implementation WaterFlowLayout
- (NSMutableArray *)attrsArray {
    if (!_attrsArray) {
        _attrsArray = [NSMutableArray array];
    }
    return _attrsArray;
}

- (NSMutableDictionary *)maxYDic {
    if (!_maxYDic) {
        _maxYDic = [NSMutableDictionary dictionary];
    }
    return _maxYDic;
}

- (instancetype)init {
    if (self = [super init]) {
        self.columnCount = 3;
        self.rowMargin = 10.0;
        self.columnMargin = 10.0;
        self.sectionInset = UIEdgeInsetsMake(0, 10, 10, 10);
    }
    return self;
}


- (void)prepareLayout {
    [super prepareLayout];
    
    for (int i = 0; i < self.columnCount; i++) {
        NSString *column = [NSString stringWithFormat:@"%d",i];
        self.maxYDic[column] = @(self.sectionInset.top);
    }
    
    [self.attrsArray removeAllObjects];
    
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    for (int i = 0; i < count; i++) {
        UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        [self.attrsArray addObject:attrs];
    }
}


- (CGSize)collectionViewContentSize {
    __block NSString *maxColumn = @"0";
    [self.maxYDic enumerateKeysAndObjectsUsingBlock:^(NSString* column, NSNumber *maxY, BOOL * _Nonnull stop) {
        if ([maxY floatValue] > [self.maxYDic[maxColumn] floatValue]) {
            maxColumn = column;
        }
    }];
    return CGSizeMake(0, [self.maxYDic[maxColumn]floatValue] + self.sectionInset.bottom);
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    __block NSString *minColumn = @"0";
    [self.maxYDic enumerateKeysAndObjectsUsingBlock:^(NSString *column, NSNumber *maxY, BOOL * _Nonnull stop) {
        if ([maxY floatValue] < [self.maxYDic[minColumn] floatValue] ) {
            minColumn = column;
        }
    }];
    
    CGFloat width = (self.collectionView.frame.size.width - self.columnMargin * (self.columnCount - 1) -self.sectionInset.left - self.sectionInset.right) / self.columnCount;
    
    CGFloat height = [self.delegate waterFlowLayout:self heightForWidth:width andIndexPath:indexPath];
    
    CGFloat x = self.sectionInset.left + (width + self.columnMargin) * [minColumn floatValue];
    CGFloat y = [self.maxYDic[minColumn] floatValue] + self.rowMargin;
    
    self.maxYDic[minColumn] = @(y + height);
    
    UICollectionViewLayoutAttributes *attrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attrs.frame = CGRectMake(x, y, width, height);
    
    return attrs;
}


-(NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    return self.attrsArray;
}

@end
