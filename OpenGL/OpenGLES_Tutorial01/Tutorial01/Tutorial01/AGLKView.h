//
//  AGLKView.h
//  Tutorial01
//
//  Created by heyonly on 2019/4/29.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
NS_ASSUME_NONNULL_BEGIN
@class AGLKView;

typedef enum {
    AGLKViewDrawableDepthFormatNone = 0,
    AGLKViewDrawableDepthFormat16,
}AGLKViewDrawableDepthFormat;

@protocol AGLKViewDelegate <NSObject>

@required
- (void)glkView:(AGLKView *)view drawInRect:(CGRect)rect;

@end

@interface AGLKView : UIView
{
    GLuint defaultFrameBuffer;
    GLuint colorRenderBuffer;
    GLuint depthRenderBuffer;
}
@property (nonatomic, weak) id<AGLKViewDelegate> delgate;

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign, readonly) NSInteger drawableWidth;
@property (nonatomic, assign, readonly) NSInteger drawableHeight;
@property (nonatomic, assign) AGLKViewDrawableDepthFormat drawableDepthFormat;
@end

NS_ASSUME_NONNULL_END
