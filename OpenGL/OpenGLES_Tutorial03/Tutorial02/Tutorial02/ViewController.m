//
//  ViewController.m
//  Tutorial02
//
//  Created by heyonly on 2019/4/11.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    OpenGLView *glView = [[OpenGLView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:glView];
}


@end
