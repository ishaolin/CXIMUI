//
//  CXIMTipTableViewCell.m
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import "CXIMTipTableViewCell.h"

@interface CXIMTipTableViewCell () {
    UILabel *_tipLabel;
}

@end

@implementation CXIMTipTableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView{
    static NSString *reuseIdentifier = @"CXIMTipTableViewCell";
    return [self cellWithTableView:tableView reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    if(self = [super initWithReuseIdentifier:reuseIdentifier]){
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.font = CX_PingFangSC_RegularFont(10.0);
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.backgroundColor = [CXHexIColor(0x666666) colorWithAlphaComponent:0.2];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.numberOfLines = 0;
        [self.contentView addSubview:_tipLabel];
    }
    
    return self;
}

- (void)setMessageModel:(CXIMMessageModel *)messageModel{
    [super setMessageModel:messageModel];
    
    _tipLabel.text = messageModel.sysMsg;
    _tipLabel.frame = messageModel.sysMsgFrame;
    [_tipLabel cx_roundedCornerRadii:3.0];
}

@end
