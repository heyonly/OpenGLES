//
//  AGLKTextureLoader.h
//  Tutorial04
//
//  Created by heyonly on 2019/4/29.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface AGLKTextureInfo : NSObject
{
@private
    GLuint              name;
    GLenum              target;
    GLuint              width;
    GLuint              height;
}

@property (nonatomic, assign) GLuint name;
@property (nonatomic, assign) GLuint target;
@property (nonatomic, assign) GLuint width;
@property (nonatomic, assign) GLuint height;
- (id)initWithName:(GLuint)aName target:(GLenum)aTarget width:(GLuint)aWidth height:(GLuint)aHeight;
@end


@interface AGLKTextureLoader : NSObject
+ (AGLKTextureInfo *)textureWithCGImage:(CGImageRef)cgImage options:(NSDictionary *)options error:(NSError **)outError;
@end

NS_ASSUME_NONNULL_END
