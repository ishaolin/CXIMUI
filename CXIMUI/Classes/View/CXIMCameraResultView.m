//
//  CXIMCameraResultView.m
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import "CXIMCameraResultView.h"
#import <CXUIKit/CXUIKit.h>
#import <CXFoundation/CXFoundation.h>

@interface CXIMCameraResultView () <CXVideoPlayerDelegate> {
    CXVideoPlayer *_videoPlayer;
    NSString *_videoPath;
}

@end

@implementation CXIMCameraResultView

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = [UIColor blackColor];
        
        _videoPlayer = [[CXVideoPlayer alloc] init];
        [_videoPlayer removePlayControl];
        _videoPlayer.delegate = self;
        [self addSubview:_videoPlayer];
        
        [self reset];
    }
    
    return self;
}

- (void)setRecordVideoPath:(NSString *)videoPath coverImage:(UIImage *)coverImage{
    _videoPath = videoPath;
    
    if(CXStringIsEmpty(videoPath) && coverImage){
        return;
    }
    
    self.hidden = NO;
    _videoPlayer.snapshotView.image = coverImage;
    if(CXStringIsEmpty(videoPath)){
        return;
    }
    
    [_videoPlayer setAssetURL:[NSURL fileURLWithPath:videoPath]];
}

- (void)videoPlayerDidReadyToPlay:(CXVideoPlayer *)videoPlayer{
    [videoPlayer play];
}

- (void)videoPlayerDidPlayToEnd:(CXVideoPlayer *)videoPlayer{
    [_videoPlayer play];
}

- (void)willResignActive{
    [_videoPlayer pause];
}

- (void)willEnterForeground{
    if(CXStringIsEmpty(_videoPath)){
        return;
    }
    
    [_videoPlayer showIndicator];
}

- (void)didBecomeActive{
    if(CXStringIsEmpty(_videoPath)){
        return;
    }
    
    [_videoPlayer hideIndicator];
    [_videoPlayer play];
}

- (void)reset{
    self.hidden = YES;
    
    [_videoPlayer pause];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    _videoPlayer.frame = self.bounds;
}

@end
