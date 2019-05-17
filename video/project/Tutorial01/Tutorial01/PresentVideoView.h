//
//  PresentVideoView.h
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol CollectionViewDidSelectedDelegate <NSObject>
- (void)collectionView:(UICollectionView *)collectionView cellDidSelected:(NSIndexPath *)indexPath;


@end
@interface PresentVideoView : UIView
@property (nonatomic, weak) id<CollectionViewDidSelectedDelegate> delegate;
- (instancetype)initWithFrame:(CGRect)frame delegate:(id)delegate;
@end

NS_ASSUME_NONNULL_END
