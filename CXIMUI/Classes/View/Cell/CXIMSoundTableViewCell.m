//
//  CXIMSoundTableViewCell.m
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import "CXIMSoundTableViewCell.h"

@interface CXIMSoundTableViewCell () {
    UIImageView *_soundBackgroundView;
    UIImageView *_animationView;
    UILabel *_soundTimeLabel;
    UIView *_readFlagView;
}

@end

@implementation CXIMSoundTableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView{
    static NSString *reuseIdentifier = @"CXIMSoundTableViewCell";
    return [self cellWithTableView:tableView reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    if(self = [super initWithReuseIdentifier:reuseIdentifier]){
        _soundBackgroundView = [[UIImageView alloc] init];
        _soundBackgroundView.userInteractionEnabled = YES;
        [_soundBackgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSoundTapGestureRecognizer:)]];
        [self.contentView addSubview:_soundBackgroundView];
        
        _animationView = [[UIImageView alloc] init];
        _animationView.animationDuration = 1.0;
        _animationView.animationRepeatCount = 0;
        [_soundBackgroundView addSubview:_animationView];
        
        _soundTimeLabel = [[UILabel alloc] init];
        _soundTimeLabel.font = CX_PingFangSC_RegularFont(14.0);
        _soundTimeLabel.numberOfLines = 0;
        [_soundBackgroundView addSubview:_soundTimeLabel];
        
        _readFlagView = [[UIView alloc] init];
        _readFlagView.backgroundColor = CXHexIColor(0xFC5655);
        [self.contentView addSubview:_readFlagView];
    }
    
    return self;
}

- (void)setMessageModel:(CXIMMessageModel *)messageModel{
    [super setMessageModel:messageModel];
    
    _soundBackgroundView.frame = messageModel.contentFrame;
    
    _readFlagView.hidden = messageModel.isSoundReaded;
    CGFloat readFlagView_W = 6.0;
    CGFloat readFlagView_H = readFlagView_W;
    CGFloat readFlagView_X = CGRectGetMaxX(messageModel.contentFrame) + readFlagView_W + 9.0;
    CGFloat readFlagView_Y = _soundBackgroundView.center.y - readFlagView_H * 0.5;
    _readFlagView.frame = (CGRect){readFlagView_X, readFlagView_Y, readFlagView_W, readFlagView_H};
    [_readFlagView cx_roundedCornerRadii:readFlagView_H * 0.5];
    
    CGFloat animationView_X = 17.0;
    CGFloat animationView_W = 15.0;
    CGFloat animationView_H = 18.0;
    CGFloat animationView_Y = (messageModel.contentFrame.size.height - animationView_H) * 0.5;
    
    TIMSoundElem *elem = (TIMSoundElem *)messageModel.elem;
    _soundTimeLabel.text = [NSString stringWithFormat:@"%d″", elem.second];
    CGFloat soundTimeLabel_X = 18.0;
    CGFloat soundTimeLabel_H = 20.0;
    CGFloat soundTimeLabel_Y = (messageModel.contentFrame.size.height - soundTimeLabel_H) * 0.5;
    CGFloat soundTimeLabel_W = [_soundTimeLabel.text boundingRectWithSize:CGSizeMake(messageModel.contentFrame.size.width - animationView_W - animationView_X, soundTimeLabel_H) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : _soundTimeLabel.font} context:nil].size.width;
    
    if([messageModel.message isSelf]){
        UIImage *image = CX_IMUI_IMAGE(@"im_msg_bg_self");
        _soundBackgroundView.image = [image cx_resizableImage];
        _readFlagView.hidden = YES;
        animationView_X = messageModel.contentFrame.size.width - animationView_H -animationView_X;
        
        soundTimeLabel_X = animationView_X - soundTimeLabel_W - soundTimeLabel_X;
        _soundTimeLabel.frame = (CGRect){soundTimeLabel_X, soundTimeLabel_Y, soundTimeLabel_W, soundTimeLabel_H};
        _soundTimeLabel.textColor = CXHexIColor(0x005069);
        
        _animationView.frame = (CGRect){animationView_X, animationView_Y, animationView_W
            , animationView_H};
        _animationView.image = CX_IMUI_IMAGE(@"im_msg_sound_animation_self_3");
        _animationView.animationImages = @[CX_IMUI_IMAGE(@"im_msg_sound_animation_self_1"),
                                           CX_IMUI_IMAGE(@"im_msg_sound_animation_self_2"),
                                           CX_IMUI_IMAGE(@"im_msg_sound_animation_self_3")];
    }else{
        UIImage *image = CX_IMUI_IMAGE(@"im_msg_bg_other");
        _soundBackgroundView.image = [image cx_resizableImage];
        soundTimeLabel_X += animationView_X + animationView_W;
        _soundTimeLabel.frame = (CGRect){soundTimeLabel_X, soundTimeLabel_Y, soundTimeLabel_W, soundTimeLabel_H};
        _soundTimeLabel.textColor = CXHexIColor(0x212121);
        
        _animationView.frame = (CGRect){animationView_X, animationView_Y, animationView_W
            , animationView_H};
        _animationView.image = CX_IMUI_IMAGE(@"im_msg_sound_animation_other_3");
        _animationView.animationImages = @[CX_IMUI_IMAGE(@"im_msg_sound_animation_other_1"),
                                           CX_IMUI_IMAGE(@"im_msg_sound_animation_other_2"),
                                           CX_IMUI_IMAGE(@"im_msg_sound_animation_other_3")];
    }
    
    if(messageModel.isSoundPlaying){
        [_animationView startAnimating];
    }else{
        [_animationView stopAnimating];
    }
}

- (void)handleSoundTapGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer{
    if([self.delegate respondsToSelector:@selector(IMTableViewCellDidClickSound:)]){
        [self.delegate IMTableViewCellDidClickSound:self];
    }
}

@end
