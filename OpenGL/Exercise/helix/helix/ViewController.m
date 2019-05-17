//
//  ViewController.m
//  helix
//
//  Created by heyonly on 2019/5/5.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated {

    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"01.jpeg" ofType:nil];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    [self presentViewController:activity animated:YES completion:nil];
    
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.uusafe.helix.widget"];
    NSString *uuid = [shared objectForKey:@"uuid"];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"title" message:uuid delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles:nil, nil];
    [alertView show];
    
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"title" message:groupUrl1 preferredStyle:UIAlertControllerStyleAlert];
//    [self presentViewController:alertController animated:YES completion:nil];
}
@end
