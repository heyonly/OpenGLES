//
//  ViewController.h
//  Tutorial05
//
//  Created by heyonly on 2019/4/30.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "AGLKElementIndexArrayBuffer.h"
@interface ViewController : GLKViewController
@property (strong, nonatomic) GLKBaseEffect *baseEffect;

@property (strong, nonatomic) AGLKElementIndexArrayBuffer * vertexBuffer;
@property (strong, nonatomic) GLKTextureInfo *textureInfo0;
@property (strong, nonatomic) GLKTextureInfo *textureInfo1;

@end

