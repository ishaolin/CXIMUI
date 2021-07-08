//
//  CXIMCameraControlView.m
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import "CXIMCameraControlView.h"
#import "CXIMImageDefines.h"

@interface CXIMCameraControlView () <CAAnimationDelegate> {
    UILabel *_tipsLabel;
    
    UIButton *_cancelButton;
    UIButton *_albumButton;
    UIButton *_resetButton;
    UIButton *_selectButton;
    
    UIView *_recordView;
    UIView *_recordInnerView;
    CAShapeLayer *_progressLayer;
}

@end

@implementation CXIMCameraControlView

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        _tipsLabel.font = CX_PingFangSC_RegularFont(11.0);
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.textColor = [UIColor whiteColor];
        _tipsLabel.text = @"轻触拍照，按住摄像";
        [self addSubview:_tipsLabel];
        
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setImage:CX_IMUI_IMAGE(@"im_camera_cancel") forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(handleActionForCancelButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_cancelButton];
        
        _albumButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_albumButton setImage:CX_IMUI_IMAGE(@"im_camera_album") forState:UIControlStateNormal];
        [_albumButton addTarget:self action:@selector(handleActionForAlbumButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_albumButton];
        
        _resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_resetButton setImage:CX_IMUI_IMAGE(@"im_camera_reset") forState:UIControlStateNormal];
        [_resetButton addTarget:self action:@selector(handleActionForResetButton:) forControlEvents:UIControlEventTouchUpInside];
        _resetButton.hidden = YES;
        [self addSubview:_resetButton];
        
        _selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectButton setImage:CX_IMUI_IMAGE(@"im_camera_select") forState:UIControlStateNormal];
        [_selectButton addTarget:self action:@selector(handleActionForSelectButton:) forControlEvents:UIControlEventTouchUpInside];
        _selectButton.hidden = YES;
        [self addSubview:_selectButton];
        
        _recordView = [[UIView alloc] init];
        _recordView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
        _recordView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        [_recordView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleRecordViewTapGestureRecognizer:)]];
        [_recordView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleRecordViewLongPressGestureRecognizer:)]];
        [self addSubview:_recordView];
        
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.lineWidth = 10.0;
        _progressLayer.strokeColor = CXHexIColor(0x59D8FF).CGColor;
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.strokeEnd = 0;
        [_recordView.layer addSublayer:_progressLayer];
        
        _recordInnerView = [[UIView alloc] init];
        _recordInnerView.backgroundColor = [UIColor whiteColor];
        [_recordView addSubview:_recordInnerView];
    }
    
    return self;
}

- (void)handleActionForCancelButton:(UIButton *)hancelButton{
    if([self.delegate respondsToSelector:@selector(IMCameraControlViewDidCancelAction:)]){
        [self.delegate IMCameraControlViewDidCancelAction:self];
    }
}

- (void)handleActionForAlbumButton:(UIButton *)albumButton{
    if([self.delegate respondsToSelector:@selector(IMCameraControlViewDidAlbumAction:)]){
        [self.delegate IMCameraControlViewDidAlbumAction:self];
    }
}

- (void)handleActionForResetButton:(UIButton *)resetButton{
    [self setRecordViewStateByHidden:NO];
    
    if([self.delegate respondsToSelector:@selector(IMCameraControlViewDidResetAction:)]){
        [self.delegate IMCameraControlViewDidResetAction:self];
    }
}

- (void)handleActionForSelectButton:(UIButton *)selectButton{
    if([self.delegate respondsToSelector:@selector(IMCameraControlViewDidSelectAction:)]){
        [self.delegate IMCameraControlViewDidSelectAction:self];
    }
}

- (void)handleRecordViewTapGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer{
    if([self.delegate respondsToSelector:@selector(IMCameraControlViewDidTakePictureAction:)]){
        [self.delegate IMCameraControlViewDidTakePictureAction:self];
    }
}

- (void)handleRecordViewLongPressGestureRecognizer:(UILongPressGestureRecognizer *)gestureRecognizer{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:{
            [self addRecordViewAnimation];
            
            if([self.delegate respondsToSelector:@selector(IMCameraControlViewWillRecordVideoAction:)]){
                [self.delegate IMCameraControlViewWillRecordVideoAction:self];
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded:{
            [self removeRecordViewAnimation];
            
            if([self.delegate respondsToSelector:@selector(IMCameraControlViewDidRecordVideoAction:)]){
                [self.delegate IMCameraControlViewDidRecordVideoAction:self];
            }
        }
            break;
        default:
            break;
    }
}

- (void)addRecordViewAnimation{
    [UIView animateWithDuration:0.25 animations:^{
        self->_recordInnerView.transform = CGAffineTransformMakeScale(0.75, 0.75);
    }];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.fromValue = @(0);
    animation.toValue = @(1.0);
    animation.duration = CX_VIDEO_RECORD_MAX_DURATION;
    animation.delegate = self;
    [_progressLayer addAnimation:animation forKey:@"strokeAnimation"];
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag{
    if(flag){
        [self recordFinished];
    }
}

- (void)removeRecordViewAnimation{
    _recordInnerView.transform = CGAffineTransformIdentity;
    _progressLayer.strokeEnd = 0;
    [_progressLayer removeAnimationForKey:@"strokeAnimation"];
}

- (void)recordFinished{
    [self removeRecordViewAnimation];
    [self setRecordViewStateByHidden:YES];
}

- (void)setRecordViewStateByHidden:(BOOL)hidden{
    if(_recordView.hidden == hidden){
        return;
    }
    
    _cancelButton.hidden = hidden;
    _albumButton.hidden = hidden;
    _recordView.hidden = hidden;
    _resetButton.hidden = !hidden;
    _selectButton.hidden = !hidden;
    
    if(hidden){
        CGFloat translationX = self.center.x - 75.0;
        [UIView animateWithDuration:0.25 animations:^{
            self->_resetButton.transform = CGAffineTransformMakeTranslation(-translationX, 0);
            self->_selectButton.transform = CGAffineTransformMakeTranslation(translationX, 0);
        }];
    }else{
        self->_resetButton.transform = CGAffineTransformIdentity;
        self->_selectButton.transform = CGAffineTransformIdentity;
    }
}

- (void)dismissTipsLabelAnimated{
    if(!_tipsLabel){
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.0 animations:^{
            self->_tipsLabel.alpha = 0.1;
        } completion:^(BOOL finished) {
            [self->_tipsLabel removeFromSuperview];
            self->_tipsLabel = nil;
        }];
    });
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    if(CGRectGetWidth(_recordView.frame) > 0){
        return;
    }
    
    CGFloat tipsLabel_W = 135.0;
    CGFloat tipsLabel_H = 30.0;
    CGFloat tipsLabel_X = (CGRectGetWidth(self.bounds) - tipsLabel_W) * 0.5;
    CGFloat tipsLabel_Y = -10.0;
    _tipsLabel.frame = (CGRect){tipsLabel_X, tipsLabel_Y, tipsLabel_W, tipsLabel_H};
    [_tipsLabel cx_roundedCornerRadii:tipsLabel_H * 0.5];
    
    CGFloat recordView_W = 80.0;
    CGFloat recordView_H = recordView_W;
    CGFloat recordView_X = (CGRectGetWidth(self.bounds) - recordView_W) * 0.5;
    CGFloat recordView_Y = 40.0;
    _recordView.frame = (CGRect){recordView_X, recordView_Y, recordView_W, recordView_H};
    [_recordView cx_roundedCornerRadii:recordView_H * 0.5];
    
    CGFloat recordInnerView_W = 60.0;
    CGFloat recordInnerView_H = recordInnerView_W;
    CGFloat recordInnerView_X = (recordView_W - recordInnerView_W) * 0.5;
    CGFloat recordInnerView_Y = (recordView_H - recordInnerView_H) * 0.5;
    _recordInnerView.frame = (CGRect){recordInnerView_X, recordInnerView_Y, recordInnerView_W, recordInnerView_H};
    [_recordInnerView cx_roundedCornerRadii:recordInnerView_H * 0.5];
    
    CGFloat cancelButton_W = 32.0;
    CGFloat cancelButton_H = cancelButton_W;
    CGFloat cancelButton_X = CX_ASPECT(30.0);
    CGFloat cancelButton_Y = recordView_Y + (recordView_H - cancelButton_H) * 0.5;
    _cancelButton.frame = (CGRect){cancelButton_X, cancelButton_Y, cancelButton_W, cancelButton_H};
    
    CGFloat albumButton_W = cancelButton_W;
    CGFloat albumButton_H = albumButton_W;
    CGFloat albumButton_X = CGRectGetWidth(self.bounds) - albumButton_W - cancelButton_X;
    CGFloat albumButton_Y = cancelButton_Y;
    _albumButton.frame = (CGRect){albumButton_X, albumButton_Y, albumButton_W, albumButton_H};
    
    _resetButton.frame = _recordView.frame;
    _selectButton.frame = _recordView.frame;
    _progressLayer.path = [UIBezierPath bezierPathWithOvalInRect:_recordView.bounds].CGPath;
    
    [self dismissTipsLabelAnimated];
}

@end
