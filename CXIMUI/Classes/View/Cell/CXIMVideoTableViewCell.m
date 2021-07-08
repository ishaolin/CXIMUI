//
//  CXIMVideoTableViewCell.m
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import "CXIMVideoTableViewCell.h"

@interface CXIMVideoTableViewCell () {
    UIImageView *_playView;
    UILabel *_videoTimeLabel;
}

@end

@implementation CXIMVideoTableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView{
    static NSString *reuseIdentifier = @"CXIMVideoTableViewCell";
    return [self cellWithTableView:tableView reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    if(self = [super initWithReuseIdentifier:reuseIdentifier]){
        _playView = [[UIImageView alloc] init];
        _playView.image = CX_IMUI_IMAGE(@"im_msg_video_play");
        [self.IMImageView addSubview:_playView];
        
        _videoTimeLabel = [[UILabel alloc] init];
        _videoTimeLabel.font = CX_PingFangSC_RegularFont(10.0);
        _videoTimeLabel.textAlignment = NSTextAlignmentRight;
        _videoTimeLabel.textColor = [UIColor whiteColor];
        [self.IMImageView addSubview:_videoTimeLabel];
    }
    
    return self;
}

- (void)setMessageModel:(CXIMMessageModel *)messageModel{
    [super setMessageModel:messageModel];
    
    _playView.frame = messageModel.videoPlayFrame;
    
    TIMVideoElem *elem = (TIMVideoElem *)messageModel.elem;
    NSInteger videoDuration = MAX(round(elem.video.duration / 1000.0), 1);
    _videoTimeLabel.text = [NSDate cx_mediaTimeString:videoDuration];
    _videoTimeLabel.frame = messageModel.videoTimeFrame;
    
    [messageModel downloadVideo:nil snapshotBlock:^(UIImage *image) {
        self.IMImageView.image = image;
    }];
}

@end
