//
//  ViewController.h
//  Tutorial04
//
//  Created by heyonly on 2019/4/29.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
@class AGLKVertexAttribArrayBuffer;

@interface ViewController : GLKViewController
@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@property (nonatomic, strong) AGLKVertexAttribArrayBuffer *vertexBuffer;

@end

