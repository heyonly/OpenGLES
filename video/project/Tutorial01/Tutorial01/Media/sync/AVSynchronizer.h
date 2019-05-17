//
//  AVSynchronizer.h
//  Tutorial01
//
//  Created by heyonly on 2019/5/7.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BuriedPoint.h"
#import "VideoFrame.h"
#import "AudioFrame.h"

#define TIMEOUT_DECODE_ERROR            20
#define TIMEOUT_BUFFER                  10


NS_ASSUME_NONNULL_BEGIN

typedef enum OpenState{
    OPEN_SUCCESS,
    OPEN_FAILED,
    CLIENT_CANCEL
}OpenState;

@protocol PlayerStateDelegate <NSObject>

- (void)openSuccessed;

- (void)connectFailed;

- (void)hideLoading;

- (void)onCompletion;

- (void)buriedPointCallback:(BuriedPoint *)buriedPoint;

- (void)restart;

@end

@interface AVSynchronizer : NSObject
@property (nonatomic, weak) id<PlayerStateDelegate>playerStateDelegate;

- (id)initWithPlayerStateDelegate:(id<PlayerStateDelegate>)playerStateDelegate;

- (OpenState) openFile: (NSString *) path usingHWCodec: (BOOL) usingHWCodec
            parameters:(NSDictionary*) parameters error: (NSError **) perror;

- (OpenState) openFile: (NSString *) path usingHWCodec: (BOOL) usingHWCodec
                 error: (NSError **) perror;

- (void) closeFile;


- (void) audioCallbackFillData: (SInt16 *) outData
                     numFrames: (UInt32) numFrames
                   numChannels: (UInt32) numChannels;

- (VideoFrame*) getCorrectVideoFrame;

- (void) run;
- (BOOL) isOpenInputSuccess;
- (void) interrupt;

- (BOOL) usingHWCodec;

- (BOOL) isPlayCompleted;

- (NSInteger) getAudioSampleRate;
- (NSInteger) getAudioChannels;
- (CGFloat) getVideoFPS;
- (NSInteger) getVideoFrameHeight;
- (NSInteger) getVideoFrameWidth;
- (BOOL) isValid;
- (CGFloat) getDuration;

@end

NS_ASSUME_NONNULL_END
