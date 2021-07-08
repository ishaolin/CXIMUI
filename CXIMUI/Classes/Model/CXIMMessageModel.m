//
//  CXIMMessageModel.m
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import "CXIMMessageModel.h"

static UIEdgeInsets IM_CONTENT_EDGEINSETS = {10.0, 18.0, 10.0, 18.0};
static CGFloat      IM_CONTENT_avatar_M   = 7.0;

static NSDictionary<NSAttributedStringKey, id> *IMTimeAttributes = nil;
static NSDictionary<NSAttributedStringKey, id> *IMTextAttributes = nil;
static NSDictionary<NSAttributedStringKey, id> *IMErrorAttributes = nil;

@interface CXIMMessageModel () {
    TIMUserProfile *_profile;
    TIMConversationType _type;
}

@end

@implementation CXIMMessageModel

- (instancetype)initWithMessage:(TIMMessage *)message{
    if(self = [super init]){
        _message = message;
        _type = [[message getConversation] getType];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            IMTimeAttributes = @{NSFontAttributeName : CX_PingFangSC_RegularFont(10.0)};
            IMTextAttributes = @{NSFontAttributeName : CX_PingFangSC_RegularFont(14.0)};
            IMErrorAttributes = @{NSFontAttributeName : CX_PingFangSC_RegularFont(12.0)};
        });
        
        [self layoutSubviews];
    }
    
    return self;
}

- (TIMElem *)elem{
    return _message.elem;
}

- (void)setErrorMsg:(NSString *)errorMsg{
    if(_errorMsg == errorMsg){
        return;
    }
    
    _errorMsg = errorMsg;
    [self layoutSubviews];
}

- (void)setTime:(NSString *)time{
    if(_time == time){
        return;
    }
    
    _time = time;
    [self layoutSubviews];
}

- (TIMUserProfile *)profile{
    if(_profile){
        return _profile;
    }
    
    if([self.message isSelf]){
        _profile = [CXIMManager sharedManager].selfProfile;
    }else{
        if(_type == TIM_GROUP){
            _profile = [self.message getSenderProfile];
        }else if(_type == TIM_C2C){
            _profile = [CXIMProfileUtils friendProfile:[self.message sender]];
            if(CXStringIsEmpty(_profile.displayName)){
                [CXIMProfileUtils userProfile:[self.message sender] success:^(TIMUserProfile * _Nullable profile) {
                    self->_profile = profile;
                } failure:nil];
            }
        }
    }
    
    return _profile;
}

- (void)layoutSubviews{
    CGFloat screen_W = [UIScreen mainScreen].bounds.size.width;
    CGFloat max_image_video_H = screen_W * 0.373;
    CGFloat max_image_video_W = screen_W * 0.373;
    
    CGFloat time_W = 0;
    CGFloat time_H = 0;
    CGFloat time_X = 0;
    CGFloat time_Y = 0;
    CGFloat avatar_Y = 20.0;
    
    if([CXStringUtil isValidString:_time]){
        time_H = 20.0;
        time_W = [_time boundingRectWithSize:CGSizeMake(screen_W, time_H)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:IMTimeAttributes
                                     context:nil].size.width + 15.0;
        time_Y = IM_CONTENT_EDGEINSETS.top;
        time_X = (screen_W - time_W) * 0.5;
        avatar_Y = time_Y + time_H + IM_CONTENT_EDGEINSETS.bottom;
    }
    _timeFrame = (CGRect){time_X, time_Y, time_W, time_H};
    
    if([self.elem isKindOfClass:[TIMGroupTipsElem class]]){
        TIMGroupTipsElem *sysElem = (TIMGroupTipsElem *)self.elem;
        switch(sysElem.type){
            case TIM_GROUP_TIPS_TYPE_INVITE:
                _sysMsg = [NSString stringWithFormat:@"%@加入群", [self groupTipElemChangedUserInfo:sysElem.changedUserInfo]];
                break;
            case TIM_GROUP_TIPS_TYPE_QUIT_GRP:{
                _sysMsg = [NSString stringWithFormat:@"%@退出群", [self groupTipElemChangedUserInfo:sysElem.changedUserInfo]];
                break;
            }
            case TIM_GROUP_TIPS_TYPE_KICKED:{
                _sysMsg = [NSString stringWithFormat:@"%@退出群", [self groupTipElemChangedUserInfo:sysElem.changedUserInfo]];
                break;
            }
            case TIM_GROUP_TIPS_TYPE_SET_ADMIN:
                _sysMsg = @"管理员变更";
                break;
            case TIM_GROUP_TIPS_TYPE_CANCEL_ADMIN:
                _sysMsg = @"管理员变更";
                break;
            case TIM_GROUP_TIPS_TYPE_INFO_CHANGE:
                _sysMsg = @"管理员变更";
                break;
            case TIM_GROUP_TIPS_TYPE_MEMBER_INFO_CHANGE:
                _sysMsg = [NSString stringWithFormat:@"%@资料变更", [self groupTipElemChangedUserInfo:sysElem.changedUserInfo]];
                break;
            default:
                break;
        }
        
        [self layoutSysSubviews:screen_W];
        return;
    }
    
    CGFloat avatar_H = 45.0;
    CGFloat avatar_W = avatar_H;
    CGFloat avatar_L = 18.0;
    CGFloat avatar_X = [_message isSelf] ? (screen_W - avatar_W - avatar_L) : avatar_L;
    _avatarFrame = (CGRect){avatar_X, avatar_Y, avatar_W, avatar_H};
    
    if(_type != TIM_GROUP || [_message isSelf]){
        CGFloat nameFrame_X = CGRectGetMaxX(_avatarFrame) + IM_CONTENT_avatar_M;
        CGFloat nameFrame_Y = CGRectGetMinY(_avatarFrame);
        CGFloat nameFrame_W = screen_W - nameFrame_X * 2;
        CGFloat nameFrame_H = 0.0;
        _nameFrame = (CGRect){nameFrame_X, nameFrame_Y, nameFrame_W, nameFrame_H};
    }else{
        CGFloat nameFrame_X = CGRectGetMaxX(_avatarFrame) + IM_CONTENT_avatar_M;
        CGFloat nameFrame_Y = CGRectGetMinY(_avatarFrame);
        CGFloat nameFrame_W = screen_W - nameFrame_X * 2;
        CGFloat nameFrame_H = 15.0;
        _nameFrame = (CGRect){nameFrame_X, nameFrame_Y, nameFrame_W, nameFrame_H};
    }
    
    if([self.elem isKindOfClass:[TIMTextElem class]]){
        CGFloat top = 12.5;
        CGFloat left = [_message isSelf] ? 13.0 : 17.0;
        CGFloat bottom = top;
        CGFloat right = [_message isSelf] ? 17.0 : 13.0;
        UIEdgeInsets IM_TEXT_EDGEINSETS = {top, left, bottom, right};
        TIMTextElem *textElem = (TIMTextElem *)self.elem;
        CGFloat max_W = screen_W - (avatar_H + avatar_L + IM_CONTENT_avatar_M) * 2 - (IM_TEXT_EDGEINSETS.left + IM_TEXT_EDGEINSETS.right);
        CGSize size = [textElem.text boundingRectWithSize:CGSizeMake(max_W, MAXFLOAT)
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:IMTextAttributes
                                                  context:nil].size;
        size.width = MAX(size.width, 19.5);
        size.height = MAX(size.height, 19.5);
        
        _textFrame = (CGRect){IM_TEXT_EDGEINSETS.left, IM_TEXT_EDGEINSETS.top, size};
        CGFloat contentFrame_W = size.width + IM_TEXT_EDGEINSETS.left + IM_TEXT_EDGEINSETS.right;
        CGFloat contentFrame_H = size.height + IM_TEXT_EDGEINSETS.top + IM_TEXT_EDGEINSETS.bottom;
        CGFloat contentFrame_Y = 0;
        CGFloat contentFrame_X = 0;
        
        if([_message isSelf]){
            contentFrame_Y = CX_MARGIN(2.5) + CGRectGetMaxY(_nameFrame);
            contentFrame_X = CGRectGetMinX(_avatarFrame) - contentFrame_W - IM_CONTENT_avatar_M;
        }else{
            contentFrame_Y = CX_MARGIN(4.0) + CGRectGetMaxY(_nameFrame);
            contentFrame_X = CGRectGetMaxX(_avatarFrame) + IM_CONTENT_avatar_M;
        }
        _contentFrame = (CGRect){contentFrame_X, contentFrame_Y, contentFrame_W, contentFrame_H};
    }else if([self.elem isKindOfClass:[TIMImageElem class]]){
        TIMImageElem *imageElem = (TIMImageElem *)self.elem;
        CGFloat imageElem_W = 0;
        CGFloat imageElem_H = 0;
        
        TIMImage *thumb_imImage = nil;
        for(NSUInteger i = 0; i < imageElem.imageList.count; i ++){
            TIMImage *imImage = imageElem.imageList[i];
            if(imImage.type == TIM_IMAGE_TYPE_THUMB){
                thumb_imImage = imImage;
                break;
            }
        }
        
        CGFloat real_image_w = thumb_imImage.width;
        CGFloat real_image_h = thumb_imImage.height;
        
        // 如果手指图片不存在但是路径存在说明是本次发送的图片
        if(!thumb_imImage && [[NSFileManager defaultManager] fileExistsAtPath:imageElem.path]){
            UIImage *image = [UIImage imageWithContentsOfFile:imageElem.path];
            real_image_w = image.size.width;
            real_image_h = image.size.height;
        }
        
        if(real_image_w > real_image_h){
            // 宽 > 高
            if(real_image_w < max_image_video_W){
                //宽<最大宽
                imageElem_W = real_image_w;
                imageElem_H = real_image_h;
            }else{
                // 宽 > 最大宽
                imageElem_W = max_image_video_W;
                imageElem_H = max_image_video_W / real_image_w * real_image_h;
            }
        }else{
            // 宽 < 高
            if(real_image_h < max_image_video_H){
                // 高 < 最大高
                imageElem_W = real_image_w;
                imageElem_H = real_image_h;
            }else{
                // 高 > 最大高
                imageElem_H = max_image_video_H;
                imageElem_W = imageElem_H / real_image_h * real_image_w;
            }
        }
        
        CGFloat imageElem_X = 0;
        CGFloat imageElem_Y = _avatarFrame.origin.y + 5.0;
        if([_message isSelf]){
            imageElem_X = screen_W - (avatar_L + avatar_H + IM_CONTENT_avatar_M) - imageElem_W;
        }else{
            imageElem_X = (avatar_L + avatar_H + IM_CONTENT_avatar_M);
        }
        
        if(_type == TIM_GROUP && ![_message isSelf]){
            imageElem_Y += 19.0;
        }
        
        _contentFrame = (CGRect){imageElem_X, imageElem_Y, imageElem_W, imageElem_H};
    }else if([self.elem isKindOfClass:[TIMVideoElem class]]){
        TIMVideoElem *videoElem = (TIMVideoElem *)self.elem;
        CGFloat imageElem_W = 0;
        CGFloat imageElem_H = 0;
        TIMSnapshot *snapshot = videoElem.snapshot;
        CGFloat real_image_w = snapshot.width;
        CGFloat real_image_h = snapshot.height;
        
        if(real_image_w > real_image_h){
            // 宽 > 高
            if(real_image_w < max_image_video_W){
                // 宽 < 最大宽
                imageElem_W = real_image_w;
                imageElem_H = real_image_h;
            }else{
                // 宽 > 最大宽
                imageElem_W = max_image_video_W;
                imageElem_H = max_image_video_W / real_image_w * real_image_h;
            }
        }else{
            // 宽 < 高
            if(real_image_h < max_image_video_H){
                // 高 < 最大高
                imageElem_W = real_image_w;
                imageElem_H = real_image_h;
            }else{
                // 高 > 最大高
                imageElem_H = max_image_video_H;
                imageElem_W = imageElem_H / real_image_h * real_image_w;
            }
        }
        
        CGFloat imageElem_X = 0;
        CGFloat imageElem_Y = _avatarFrame.origin.y + 5.0;
        if([_message isSelf]){
            imageElem_X = screen_W - (avatar_L + avatar_H + IM_CONTENT_avatar_M) - imageElem_W;
        }else{
            imageElem_X = (avatar_L + avatar_H + IM_CONTENT_avatar_M);
        }
        
        if(_type == TIM_GROUP && ![_message isSelf]){
            imageElem_Y += 19.0;
        }
        _contentFrame = (CGRect){imageElem_X, imageElem_Y, imageElem_W, imageElem_H};
        
        CGFloat videoPlay_W = 28.0;
        CGFloat videoPlay_H = videoPlay_W;
        CGFloat videoPlay_X = (imageElem_W - videoPlay_W) * 0.5;
        CGFloat videoPlay_Y = (imageElem_H - videoPlay_H) * 0.5;
        _videoPlayFrame = (CGRect){videoPlay_X, videoPlay_Y, videoPlay_W, videoPlay_H};
        
        CGFloat videoTime_W = imageElem_W - 5.0;
        CGFloat videoTime_H = 12.0;
        CGFloat videoTime_X = 0;
        CGFloat videoTime_Y = imageElem_H - videoTime_H - 10.0;
        _videoTimeFrame = (CGRect){videoTime_X, videoTime_Y, videoTime_W, videoTime_H};
    }else if ([self.elem isKindOfClass:[TIMSoundElem class]]){
        TIMSoundElem *soundElem = (TIMSoundElem *)self.elem;
        CGFloat contentFrame_W = 0;
        CGFloat contentFrame_H = 44.6;
        CGFloat contentFrame_Y = 0;
        CGFloat contentFrame_X = 0;
        
        if(soundElem.second <= 3){
            // 小于3秒的宽度固定
            contentFrame_W = 84.0;
        }else{
            // 大于3秒的部分平分(200.0-84.0)的距离
            contentFrame_W = 2 * (soundElem.second - 3.0) + 84.0;
        }
        
        if([_message isSelf]){
            contentFrame_Y = CX_MARGIN(2.5) + CGRectGetMaxY(_nameFrame);
            contentFrame_X = CGRectGetMinX(_avatarFrame) - contentFrame_W - IM_CONTENT_avatar_M;
        }else{
            contentFrame_Y = CX_MARGIN(4.0) + CGRectGetMaxY(_nameFrame);
            contentFrame_X = CGRectGetMaxX(_avatarFrame) + IM_CONTENT_avatar_M;
        }
        _contentFrame = (CGRect){contentFrame_X, contentFrame_Y, contentFrame_W, contentFrame_H};
    }else{
        _sysMsg = @"不支持的消息类型";
        [self layoutSysSubviews:screen_W];
        return;
    }
    
    CGFloat loading_W = 20.0;
    CGFloat loading_H = loading_W;
    CGFloat loading_X = CGRectGetMinX(_contentFrame) - loading_W - 12.0;
    CGFloat loading_Y = CGRectGetMidY(_contentFrame) - loading_H * 0.5;
    _loadingFrame = (CGRect){loading_X, loading_Y, loading_W, loading_H};
    
    if(CXStringIsEmpty(_errorMsg)){
        _errorMsgFrame = CGRectZero;
        _height = CGRectGetMaxY(_contentFrame) + 5.0;
    }else{
        CGSize errorMsgSize = [_errorMsg boundingRectWithSize:CGSizeMake(screen_W - avatar_L * 2, MAXFLOAT)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:IMErrorAttributes
                                                      context:nil].size;
        CGFloat errorMsg_X = (screen_W - errorMsgSize.width) * 0.5;
        CGFloat errorMsg_Y = CGRectGetMaxY(_contentFrame) + 20.0;
        CGFloat errorMsg_W = errorMsgSize.width;
        CGFloat errorMsg_H = errorMsgSize.height;
        _errorMsgFrame = (CGRect){errorMsg_X, errorMsg_Y, errorMsg_W, errorMsg_H};
        _height = CGRectGetMaxY(_errorMsgFrame);
    }
}

- (void)layoutSysSubviews:(CGFloat)screenWidth{
    CGSize size = [_sysMsg boundingRectWithSize:CGSizeMake(screenWidth - 40.0, MAXFLOAT)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:IMTimeAttributes
                                        context:nil].size;
    CGFloat sysMsg_W = size.width + 15.0;
    CGFloat sysMsg_H = size.height > 20.0 ? (size.height + 10.0) : 20.0;
    CGFloat sysMsg_X = (screenWidth - sysMsg_W) * 0.5;
    CGFloat sysMsg_Y = CGRectGetMaxY(_timeFrame) + IM_CONTENT_EDGEINSETS.bottom;
    _sysMsgFrame = (CGRect){sysMsg_X, sysMsg_Y, sysMsg_W, sysMsg_H};
    _height = CGRectGetMaxY(_sysMsgFrame);
}

- (void)downloadVideo:(CXIMDownloadVideoBlock)videoBlock
        snapshotBlock:(CXIMDownloadVideoSnapshotBlock)snapshotBlock{
    if([self.elem isKindOfClass:[TIMVideoElem class]]){
        TIMVideoElem *videoElem = (TIMVideoElem *)self.elem;
        [self downloadVideoWithElem:videoElem videoBlock:videoBlock];
        [self downloadSnapshotWithElem:videoElem snapshotBlock:snapshotBlock];
    }
}

- (void)downloadSnapshotWithElem:(TIMVideoElem *)videoElem
                   snapshotBlock:(CXIMDownloadVideoSnapshotBlock)snapshotBlock{
    if(!snapshotBlock){
        return;
    }
    
    if([self.message isSelf] && [[NSFileManager defaultManager] fileExistsAtPath:videoElem.snapshotPath]){
        UIImage *image = [UIImage imageWithContentsOfFile:videoElem.snapshotPath];
        snapshotBlock(image);
        return;
    }
    
    NSString *fileName = [[CXUCryptor MD5:videoElem.snapshot.uuid] stringByAppendingString:@".jpg"];
    NSString *filePath = CX_IM_IMAGE_PATH_GET(fileName);
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        snapshotBlock(image);
        return;
    }
    
    [videoElem.snapshot getImage:filePath succ:^{
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        snapshotBlock(image);
    } fail:^(int code, NSString *msg) {
        snapshotBlock(nil);
    }];
}

- (void)downloadVideoWithElem:(TIMVideoElem *)videoElem
                   videoBlock:(CXIMDownloadVideoBlock)videoBlock{
    if(!videoBlock){
        return;
    }
    
    if([self.message isSelf] && [[NSFileManager defaultManager] fileExistsAtPath:videoElem.videoPath]){
        videoBlock([NSURL fileURLWithPath:videoElem.videoPath]);
        return;
    }
    
    NSString *videoName = [[CXUCryptor MD5:videoElem.video.uuid] stringByAppendingString:@".mp4"];
    NSString *videoPath = CX_DOWNLOAD_PATH_GET(videoName);
    if([[NSFileManager defaultManager] fileExistsAtPath:videoPath]){
        videoBlock([NSURL fileURLWithPath:videoPath]);
        return;
    }
    
    [videoElem.video getVideo:videoPath succ:^{
        videoBlock([NSURL fileURLWithPath:videoPath]);
    } fail:^(int code, NSString *msg) {
        videoBlock(nil);
    }];
}

- (void)downloadAudio:(CXIMDownloadAudioBlock)audioBlock{
    if(!audioBlock){
        return;
    }
    
    if(![self.elem isKindOfClass:[TIMSoundElem class]]){
        audioBlock(nil);
        return;
    }
    
    TIMSoundElem *soundElem = (TIMSoundElem *)self.elem;
    if([self.message isSelf] && [[NSFileManager defaultManager] fileExistsAtPath:soundElem.path]){
        audioBlock([NSURL fileURLWithPath:soundElem.path]);
        return;
    }
    
    NSString *audioName = [[CXUCryptor MD5:soundElem.uuid] stringByAppendingString:@".mp4"];
    NSString *audioPath = CX_DOWNLOAD_PATH_GET(audioName);
    if([[NSFileManager defaultManager] fileExistsAtPath:audioPath]){
        audioBlock([NSURL fileURLWithPath:audioPath]);
        return;
    }
    
    [soundElem getSound:audioPath succ:^{
        audioBlock([NSURL fileURLWithPath:audioPath]);
    } fail:^(int code, NSString *msg) {
        audioBlock(nil);
    }];
}

- (NSString *)groupTipElemChangedUserInfo:(NSDictionary *)info{
    NSMutableString *infoString = [NSMutableString string];
    [info enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[TIMUserProfile class]]){
            TIMUserProfile *userProfile = obj;
            if([CXStringUtil isValidString:userProfile.displayName]){
                [infoString appendFormat:@"、\"%@\"", userProfile.displayName];
            }
        }
    }];
    
    if([infoString hasPrefix:@"、"]){
        [infoString deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    
    return [infoString copy];
}

@end
