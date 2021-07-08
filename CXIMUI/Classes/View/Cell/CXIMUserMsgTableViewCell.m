//
//  CXIMUserMsgTableViewCell.m
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import "CXIMUserMsgTableViewCell.h"

@interface CXIMUserMsgTableViewCell () {
    UIImageView *_avatarView;
    UILabel *_nameLabel;
    UIImageView *_failedView;
    UIActivityIndicatorView *_indicatorView;
    UILabel *_errorMsgLabel;
}

@end

@implementation CXIMUserMsgTableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView{
    static NSString *reuseIdentifier = @"CXIMUserMsgTableViewCell";
    return [self cellWithTableView:tableView reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    if(self = [super initWithReuseIdentifier:reuseIdentifier]){
        _avatarView = [[UIImageView alloc] init];
        _avatarView.userInteractionEnabled = YES;
        [_avatarView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAvatarViewTapGestureRecognizer:)]];
        [self.contentView addSubview:_avatarView];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = CX_PingFangSC_RegularFont(10.0);
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.textColor = [CXHexIColor(0x333333) colorWithAlphaComponent:0.6];
        [self.contentView addSubview:_nameLabel];
        
        _failedView = [[UIImageView alloc] init];
        _failedView.image = CX_IMUI_IMAGE(@"im_msg_send_error");
        _failedView.userInteractionEnabled = YES;
        [_failedView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleFailedViewTapGestureRecognizer:)]];
        [self.contentView addSubview:_failedView];
        
        _indicatorView = [CXSystemAdapter grayActivityIndicatorView];
        [self.contentView addSubview:_indicatorView];
        
        _errorMsgLabel = [[UILabel alloc] init];
        _errorMsgLabel.font = CX_PingFangSC_RegularFont(12.0);
        _errorMsgLabel.textAlignment = NSTextAlignmentCenter;
        _errorMsgLabel.textColor = CXHexIColor(0xCBCED1);
        [self.contentView addSubview:_errorMsgLabel];
    }
    
    return self;
}

- (void)handleAvatarViewTapGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer{
    if([self.messageModel.message isSelf]){
        if([self.delegate respondsToSelector:@selector(IMTableViewCellDidClickSelfAvatar:)]){
            [self.delegate IMTableViewCellDidClickSelfAvatar:self];
        }
    }else{
        if([self.delegate respondsToSelector:@selector(IMTableViewCellDidClickUserAvatar:)]){
            [self.delegate IMTableViewCellDidClickUserAvatar:self];
        }
    }
}

- (void)handleFailedViewTapGestureRecognizer:(UITapGestureRecognizer *)gestureRecognizer{
    if([self.delegate respondsToSelector:@selector(IMTableViewCellDidClickResend:)]){
        [self.delegate IMTableViewCellDidClickResend:self];
    }
}

- (void)setMessageModel:(CXIMMessageModel *)messageModel{
    [super setMessageModel:messageModel];
    
    _nameLabel.text = messageModel.profile.nickname;
    _nameLabel.frame = messageModel.nameFrame;
    _nameLabel.textAlignment = [messageModel.message isSelf] ? NSTextAlignmentRight : NSTextAlignmentLeft;
    
    [_avatarView cx_setImageWithURL:messageModel.profile.faceURL];
    _avatarView.frame = messageModel.avatarFrame;
    [_avatarView cx_roundedCornerRadii:CGRectGetWidth(messageModel.avatarFrame) * 0.5];
    
    _failedView.frame = messageModel.loadingFrame;
    _indicatorView.frame = messageModel.loadingFrame;
    
    switch (messageModel.message.status) {
        case TIM_MSG_STATUS_SENDING:{
            [_indicatorView startAnimating];
            _indicatorView.hidden = NO;
            _failedView.hidden = YES;
        }
            break;
        case TIM_MSG_STATUS_SEND_SUCC:{
            [_indicatorView stopAnimating];
            _failedView.hidden = YES;
        }
            break;
        case TIM_MSG_STATUS_SEND_FAIL:{
            [_indicatorView stopAnimating];
            _failedView.hidden = NO;
        }
            break;
        default:
            break;
    }
    
    _errorMsgLabel.text = messageModel.errorMsg;
    _errorMsgLabel.frame = messageModel.errorMsgFrame;
}

@end
