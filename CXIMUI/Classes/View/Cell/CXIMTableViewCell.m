//
//  CXIMTableViewCell.m
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import "CXIMTableViewCell.h"
#import "CXIMTextTableViewCell.h"
#import "CXIMImageTableViewCell.h"
#import "CXIMVideoTableViewCell.h"
#import "CXIMSoundTableViewCell.h"
#import "CXIMTipTableViewCell.h"

@interface CXIMTableViewCell () {
    UILabel *_timeLabel;
}

@end

@implementation CXIMTableViewCell

+ (CXIMTableViewCell *)cellWithTableView:(UITableView *)tableView messageModel:(CXIMMessageModel *)messageModel{
    CXIMTableViewCell *cell = nil;
    if([messageModel.elem isKindOfClass:[TIMTextElem class]]){
        cell = [CXIMTextTableViewCell cellWithTableView:tableView];
    }else if([messageModel.elem isKindOfClass:[TIMImageElem class]]){
        cell = [CXIMImageTableViewCell cellWithTableView:tableView];
    }else if([messageModel.elem isKindOfClass:[TIMVideoElem class]]){
        cell = [CXIMVideoTableViewCell cellWithTableView:tableView];
    }else if([messageModel.elem isKindOfClass:[TIMSoundElem class]]){
        cell = [CXIMSoundTableViewCell cellWithTableView:tableView];
    }else{
        cell = [CXIMTipTableViewCell cellWithTableView:tableView];
    }
    
    cell.messageModel = messageModel;
    return cell;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    if(self = [super initWithReuseIdentifier:reuseIdentifier]){
        self.backgroundView.backgroundColor = [UIColor clearColor];
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = CX_PingFangSC_RegularFont(10.0);
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.backgroundColor = [CXHexIColor(0x666666) colorWithAlphaComponent:0.2];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_timeLabel];
    }
    
    return self;
}

- (void)setMessageModel:(CXIMMessageModel *)messageModel{
    _messageModel = messageModel;
    
    _timeLabel.text  = messageModel.time;
    _timeLabel.frame = messageModel.timeFrame;
    [_timeLabel cx_roundedCornerRadii:3.0];
}

+ (UIColor *)highlightedColour{
    return nil;
}

@end
