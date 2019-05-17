//
//  ViewController.m
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"
#import "PresentVideoView.h"
#import "VideoPlayerViewController.h"
@interface ViewController ()<CollectionViewDidSelectedDelegate,CAAnimationDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    PresentVideoView *presentView = [[PresentVideoView alloc] initWithFrame:self.scrollView.bounds delegate:self];
    
    [self.scrollView addSubview:presentView];
    
}

- (void)collectionView:(UICollectionView *)collectionView cellDidSelected:(NSIndexPath *)indexPath {
    NSLog(@"%@",collectionView);
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    VideoPlayerViewController *videoViewController = [storyBoard instantiateViewControllerWithIdentifier:@"VideoPlayerViewController"];
    
    CATransition *transition = [CATransition animation];
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.duration = 0.5f;
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromTop;
    transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    
    
    
    [self.navigationController pushViewController:videoViewController animated:YES];
}

@end
