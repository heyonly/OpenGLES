//
//  ViewController.h
//  Tutorial01
//
//  Created by heyonly on 2019/4/29.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
@interface ViewController : UIViewController
{
    CADisplayLink *displayLink;
    GLuint      vertexBufferID;
}

@property (nonatomic, assign) NSInteger preferredFramesPerSecond;
@property (nonatomic, assign, readonly) NSInteger framesPerSecond;

@property (nonatomic, assign, getter=isPaused) BOOL paused;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@end

