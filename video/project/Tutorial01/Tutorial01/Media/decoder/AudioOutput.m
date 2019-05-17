//
//  AudioOutput.m
//  Tutorial01
//
//  Created by heyonly on 2019/5/15.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "AudioOutput.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>


static const AudioUnitElement inputElement = 1;

static OSStatus InputRenderCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData);

@interface AudioOutput ()
{
    SInt16 *                    _outData;
}
@property (nonatomic, strong) AVAudioSession    *audioSession;
@property (nonatomic, assign) AUGraph           auGraph;
@property (nonatomic, assign) AUNode            ioNode;
@property (nonatomic, assign) AudioUnit         ioUnit;
@property (nonatomic, assign) AUNode            convertNode;
@property (nonatomic, assign) AudioUnit         convertUnit;

@property (readwrite,copy) id<FillDataDelegate> fillAudioDataDelegate;
@end


@implementation AudioOutput
- (id) initWithChannels:(NSInteger) channels sampleRate:(NSInteger) sampleRate bytesPerSample:(NSInteger) bytePerSample filleDataDelegate:(id<FillDataDelegate>) fillAudioDataDelegate
{
    if (self = [super init]) {
        NSError *error;
        self.audioSession = [AVAudioSession sharedInstance];
        [self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        
        [self.audioSession setPreferredSampleRate:sampleRate error:&error];
        [self.audioSession setActive:YES error:&error];
        
        _outData = (SInt16 *)calloc(8192, sizeof(SInt16));
        _fillAudioDataDelegate = fillAudioDataDelegate;
        _sampleRate = sampleRate;
        _channels = channels;
        [self createAudioUnitGraph];
    }
    return self;
}

- (void)createAudioUnitGraph {
    OSStatus status = noErr;
    
    status = NewAUGraph(&_auGraph);
    
    AudioComponentDescription ioDescription;
    ioDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioDescription.componentType = kAudioUnitType_Output;
    ioDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    ioDescription.componentFlags = 0;
    ioDescription.componentFlagsMask = 0;
    
    status = AUGraphAddNode(_auGraph, &ioDescription, &_ioNode);
    
    AudioComponentDescription convertDescription;
    convertDescription.componentType = kAudioUnitType_FormatConverter;
    convertDescription.componentSubType = kAudioUnitSubType_AUConverter;
    convertDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    convertDescription.componentFlags = 0;
    convertDescription.componentFlagsMask = 0;
    
    status = AUGraphAddNode(_auGraph, &convertDescription, &_convertNode);
    
    status = AUGraphOpen(_auGraph);
    
    status = AUGraphNodeInfo(_auGraph, _ioNode, NULL, &_ioUnit);
    
    status = AUGraphNodeInfo(_auGraph, _convertNode, NULL, &_convertUnit);
    
    UInt32 bytesPerSample = sizeof(Float32);
    
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate = _sampleRate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    asbd.mBitsPerChannel = 8 * bytesPerSample;
    asbd.mBytesPerFrame = bytesPerSample;
    asbd.mBytesPerPacket = bytesPerSample;
    asbd.mFramesPerPacket = 1;
    asbd.mChannelsPerFrame = _channels;
    
    status = AudioUnitSetProperty(_ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, inputElement, &asbd, sizeof(asbd));
    
    AudioStreamBasicDescription clientFormat16Int;
    UInt32 bytesPerSample1 = sizeof(SInt16);
    
    clientFormat16Int.mFormatID             = kAudioFormatLinearPCM;
    clientFormat16Int.mFormatFlags          = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    clientFormat16Int.mBytesPerPacket       = bytesPerSample1 * _channels;
    clientFormat16Int.mFramesPerPacket      = 1;
    clientFormat16Int.mBytesPerFrame        = bytesPerSample1 * _channels;
    clientFormat16Int.mChannelsPerFrame     = _channels;
    clientFormat16Int.mBitsPerChannel       = 8 * bytesPerSample1;
    clientFormat16Int.mSampleRate           = _sampleRate;
    
    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd, sizeof(asbd));
    
    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &clientFormat16Int, sizeof(clientFormat16Int));
    
    status = AUGraphConnectNodeInput(_auGraph, _convertNode, 0, _ioNode, 0);
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = &InputRenderCallback;
    callbackStruct.inputProcRefCon = (__bridge void*)(self);
    
    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, sizeof(callbackStruct));
    
    CAShow(_auGraph);
    
    AUGraphInitialize(_auGraph);
}


- (OSStatus)renderData:(AudioBufferList *)ioData
           atTimeStamp:(const AudioTimeStamp *)timeStamp
            forElement:(UInt32)element
          numberFrames:(UInt32)numFrames
                 flags:(AudioUnitRenderActionFlags *)flags
{
    for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
        memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    if(_fillAudioDataDelegate)
    {
        [_fillAudioDataDelegate fillAudioData:_outData numFrames:numFrames numChannels:_channels];
        for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
            memcpy((SInt16 *)ioData->mBuffers[iBuffer].mData, _outData, ioData->mBuffers[iBuffer].mDataByteSize);
        }
    }
    
    return noErr;
}
- (void)play {
    OSStatus status = AUGraphStart(_auGraph);
    NSLog(@"AUGraphStart:%d",status);
}

- (void)stop {
    AUGraphStop(_auGraph);
}
@end

static OSStatus InputRenderCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData)
{
    AudioOutput *audioOutput = (__bridge id)inRefCon;
    return [audioOutput renderData:ioData
                       atTimeStamp:inTimeStamp
                        forElement:inBusNumber
                      numberFrames:inNumberFrames
                             flags:ioActionFlags];
}
