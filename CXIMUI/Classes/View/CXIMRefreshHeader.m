//
//  CXIMRefreshHeader.m
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import "CXIMRefreshHeader.h"
#import <CXUIKit/CXUIKit.h>

@interface CXIMRefreshHeader () {
    UIActivityIndicatorView *_indicatorView;
}

@end

@implementation CXIMRefreshHeader

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.stateLabel.font = CX_PingFangSC_RegularFont(10.0);
        self.lastUpdatedTimeLabel.hidden = YES;
        
        _indicatorView = [UIActivityIndicatorView grayIndicatorView];
        _indicatorView.hidesWhenStopped = NO;
        [self addSubview:_indicatorView];
        
        [self setTitle:@"下拉可以刷新" forState:MJRefreshStateIdle];
        [self setTitle:@"松开刷新" forState:MJRefreshStatePulling];
        [self setTitle:@"正在刷新" forState:MJRefreshStateRefreshing];
        
        [self setIndicatorColor:CXHexIColor(0x666666)];
    }
    
    return self;
}

- (void)setState:(MJRefreshState)state{
    MJRefreshCheckState
    
    if(state == MJRefreshStateIdle){
        if(oldState == MJRefreshStateRefreshing){
            [UIView animateWithDuration:MJRefreshSlowAnimationDuration animations:^{
                self->_indicatorView.alpha = 0.0;
            } completion:^(BOOL finished){
                if(self.state != MJRefreshStateIdle){
                    return;
                }
                
                self->_indicatorView.alpha = 1.0;
                [self->_indicatorView stopAnimating];
            }];
        }else{
            [_indicatorView stopAnimating];
        }
    }else if(state == MJRefreshStatePulling){
        _indicatorView.alpha = 1.0;
        [_indicatorView startAnimating];
    }else if(state == MJRefreshStateRefreshing){
        _indicatorView.alpha = 1.0;
        [_indicatorView startAnimating];
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat indicatorView_W = _indicatorView.bounds.size.width;
    CGFloat indicatorView_H = _indicatorView.bounds.size.height;
    CGFloat indicatorView_Y = (CGRectGetHeight(self.bounds) - indicatorView_H) * 0.5;
    CGFloat indicatorView_X = 0;
    
    CGFloat stateLabel_H = 20.0;
    CGFloat stateLabel_W = [self.stateLabel sizeThatFits:CGSizeMake(200.0, stateLabel_H)].width;
    CGFloat stateLabel_Y = (CGRectGetHeight(self.bounds) - stateLabel_H) * 0.5;
    CGFloat stateLabel_X = 0;
    
    if(self.stateLabel.isHidden){
        indicatorView_X = (CGRectGetWidth(self.bounds) - indicatorView_W) * 0.5;
    }else{
        indicatorView_X = (CGRectGetWidth(self.bounds) - indicatorView_W - stateLabel_W - 10.0) * 0.5;
    }
    _indicatorView.frame = (CGRect){indicatorView_X, indicatorView_Y, indicatorView_W, indicatorView_H};
    
    stateLabel_X = CGRectGetMaxX(_indicatorView.frame) + 10.0;
    self.stateLabel.frame = (CGRect){stateLabel_X, stateLabel_Y, stateLabel_W, stateLabel_H};
}

- (UIColor *)indicatorColor{
    return _indicatorView.color ?: self.stateLabel.textColor;
}

- (void)setIndicatorColor:(UIColor *)indicatorColor{
    _indicatorView.color = indicatorColor;
    self.stateLabel.textColor = indicatorColor;
}

@end
