//
//  CXIMMessageModel.h
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import <CXIMSDK/CXIMSDK.h>
#import <CXUIKit/CXUIKit.h>
#import <CXFoundation/CXFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CXIMDownloadVideoSnapshotBlock)(UIImage * _Nullable image);
typedef void(^CXIMDownloadVideoBlock)(NSURL * _Nullable videoURL);
typedef void(^CXIMDownloadAudioBlock)(NSURL * _Nullable audioURL);

@interface CXIMMessageModel : NSObject

@property (nonatomic, strong, readonly) TIMMessage *message;
@property (nonatomic, strong, readonly) TIMElem *elem;
@property (nonatomic, strong, readonly) TIMUserProfile *profile;
@property (nonatomic, copy, readonly) NSString *sysMsg;
@property (nonatomic, copy) NSString *errorMsg;
@property (nonatomic, copy) NSString *time;
@property (nonatomic, assign, readonly) CGFloat height;
@property (nonatomic, assign, readonly) CGRect  avatarFrame;
@property (nonatomic, assign, readonly) CGRect  nameFrame;
@property (nonatomic, assign, readonly) CGRect  contentFrame;
@property (nonatomic, assign, readonly) CGRect  timeFrame;
@property (nonatomic, assign, readonly) CGRect  loadingFrame;
@property (nonatomic, assign, readonly) CGRect  textFrame;
@property (nonatomic, assign, readonly) CGRect  sysMsgFrame;
@property (nonatomic, assign, readonly) CGRect  videoPlayFrame;
@property (nonatomic, assign, readonly) CGRect  videoTimeFrame;
@property (nonatomic, assign, readonly) CGRect  errorMsgFrame;
@property (nonatomic, assign, getter = isSoundPlaying) BOOL soundPlaying;
@property (nonatomic, assign, getter = isSoundReaded)  BOOL soundReaded;

- (instancetype)initWithMessage:(TIMMessage *)message;

- (void)downloadVideo:(nullable CXIMDownloadVideoBlock)videoBlock
        snapshotBlock:(CXIMDownloadVideoSnapshotBlock)snapshotBlock;

- (void)downloadAudio:(CXIMDownloadAudioBlock)audioBlock;

@end

NS_ASSUME_NONNULL_END
