//
//  CXIMImageTableViewCell.m
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import "CXIMImageTableViewCell.h"

@implementation CXIMImageTableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView{
    static NSString *reuseIdentifier = @"CXIMImageTableViewCell";
    return [self cellWithTableView:tableView reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    if(self = [super initWithReuseIdentifier:reuseIdentifier]){
        _IMImageView = [[UIImageView alloc]init];
        _IMImageView.backgroundColor = CXHexIColor(0xE6E6E6);
        _IMImageView.userInteractionEnabled = YES;
        [_IMImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageViewTapGestureRecognizer:)]];
        [self.contentView addSubview:_IMImageView];
    }
    
    return self;
}

- (void)handleImageViewTapGestureRecognizer:(UITapGestureRecognizer *)tapGestureRecognizer{
    if([self.delegate respondsToSelector:@selector(IMTableViewCell:didClickImage:)]){
        [self.delegate IMTableViewCell:self didClickImage:_IMImageView];
    }
}

- (void)setMessageModel:(CXIMMessageModel *)messageModel{
    [super setMessageModel:messageModel];
    
    _IMImageView.frame = messageModel.contentFrame;
    [_IMImageView cx_roundedCornerRadii:4.0];
    
    if(![messageModel.elem isKindOfClass:[TIMImageElem class]]){
        return;
    }
    
    TIMImageElem *elem = (TIMImageElem *)messageModel.elem;
    if([[NSFileManager defaultManager] fileExistsAtPath:elem.path]){
        _IMImageView.image = [UIImage imageWithContentsOfFile:elem.path];
    }else{
        __block TIMImage *image = nil;
        [elem.imageList enumerateObjectsUsingBlock:^(TIMImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(obj.type == TIM_IMAGE_TYPE_THUMB){
                image = obj;
                *stop = YES;
            }
        }];
        
        [_IMImageView cx_setImageWithURL:image.url];
    }
}

@end
