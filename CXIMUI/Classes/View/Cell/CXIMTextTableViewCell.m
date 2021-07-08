//
//  CXIMTextTableViewCell.m
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import "CXIMTextTableViewCell.h"

@interface CXIMTextTableViewCell () {
    UIImageView *_textBackgroundView;
    UILabel *_textLabel;
}

@end

@implementation CXIMTextTableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView{
    static NSString *reuseIdentifier = @"CXIMTextTableViewCell";
    return [self cellWithTableView:tableView reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    if(self = [super initWithReuseIdentifier:reuseIdentifier]){
        _textBackgroundView = [[UIImageView alloc] init];
        _textBackgroundView.userInteractionEnabled = YES;
        [_textBackgroundView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestureRecognizer:)]];
        [self.contentView addSubview:_textBackgroundView];
        
        _textLabel = [[UILabel alloc] init];
        _textLabel.font = CX_PingFangSC_RegularFont(14.0);
        _textLabel.textAlignment = NSTextAlignmentLeft;
        _textLabel.numberOfLines = 0;
        [_textBackgroundView addSubview:_textLabel];
    }
    
    return self;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    if(action == @selector(copyText:)){
        return YES;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (BOOL)canBecomeFirstResponder{
    return YES;
}

- (void)handleLongPressGestureRecognizer:(UILongPressGestureRecognizer *)longPressGestureRecognizer{
    if(longPressGestureRecognizer.state != UIGestureRecognizerStateBegan){
        return;
    }
    
    if(CXStringIsEmpty(_textLabel.text)){
        return;
    }
    
    [self becomeFirstResponder];
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    menuController.menuItems = @[[[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(copyText:)]];
    if(menuController.isMenuVisible){
        return;
    }
    
    [menuController setTargetRect:_textBackgroundView.bounds inView:_textBackgroundView];
    [menuController setMenuVisible:YES animated:YES];
}

- (void)copyText:(UIMenuController *)menuController{
    [UIPasteboard generalPasteboard].string = _textLabel.text;
}

- (void)setMessageModel:(CXIMMessageModel *)messageModel{
    [super setMessageModel:messageModel];
    
    if([messageModel.message isSelf]){
        _textLabel.textColor = CXHexIColor(0x005069);
    }else{
        _textLabel.textColor = CXHexIColor(0x212121);
    }
    
    TIMTextElem *elem = (TIMTextElem *)messageModel.elem;
    if(elem.text.length > 1){
        _textLabel.textAlignment = NSTextAlignmentLeft;
    }else{
        _textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    _textLabel.text = elem.text;
    _textLabel.frame = messageModel.textFrame;
    _textBackgroundView.frame = messageModel.contentFrame;
    
    if([messageModel.message isSelf]){
        UIImage *image = CX_IMUI_IMAGE(@"im_msg_bg_self");
        _textBackgroundView.image = [image cx_resizableImage];
    }else{
        UIImage *image = CX_IMUI_IMAGE(@"im_msg_bg_other");
        _textBackgroundView.image = [image cx_resizableImage];
    }
}

@end
