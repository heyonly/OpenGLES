//
//  ViewController.m
//  Tutorial01
//
//  Created by heyonly on 2019/4/10.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLView.h"
@interface ViewController ()
@property (nonatomic, strong) OpenGLView *glView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.glView = [[OpenGLView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.glView];
}


@end
