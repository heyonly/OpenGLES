//
//  WaterFlowLayout.h
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WaterFlowLayout;
@protocol WaterFlowLayoutDelgate <NSObject>

-(CGFloat)waterFlowLayout:(WaterFlowLayout *) WaterFlowLayout heightForWidth:(CGFloat)width andIndexPath:(NSIndexPath *)indexPath;

@end

@interface WaterFlowLayout : UICollectionViewLayout
@property (nonatomic, assign) CGFloat columnMargin;

@property (nonatomic, assign) CGFloat rowMargin;
@property (nonatomic, assign) UIEdgeInsets sectionInset;

@property (nonatomic, assign) NSInteger columnCount;
@property (nonatomic, weak)   id<WaterFlowLayoutDelgate> delegate;
@end

NS_ASSUME_NONNULL_END
