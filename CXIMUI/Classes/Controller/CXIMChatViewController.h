//
//  CXIMChatViewController.h
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import <CXUIKit/CXUIKit.h>
#import <CXFoundation/CXFoundation.h>
#import "CXIMChatToolbar.h"

#define CX_IM_MSSAGE_PAGE_SIZE      20  // 分页大小
#define CX_IM_CONVERSATION_C2C      1   // 会话类型：单聊
#define CX_IM_CONVERSATION_GROUP    2   // 会话类型：群聊

@class CXIMMessageModel, TIMConversation, TIMMessage, CXIMChatParams;

typedef void(^CXIMAudioRecordFinishedBlock)(NSString *filePath, NSError *error);
typedef void(^CXIMAudioDownloadBlock)(NSURL *audioURL, CXIMMessageModel *messageModel);

@interface CXIMChatViewController : CXBaseViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, readonly) CXTableView *tableView;
@property (nonatomic, strong, readonly) TIMConversation *conversation;
@property (nonatomic, strong, readonly) CXIMChatToolbar *chatToolbar;

- (void)setChatParams:(CXIMChatParams *)params;

- (void)sendTextMessage:(NSString *)text;
- (void)sendImageMessage:(NSString *)imagePath;
- (void)sendSoundMessage:(NSString *)soundPath;
- (void)sendVideoMessage:(NSString *)videoPath coverPath:(NSString *)coverPath;

- (void)startRecording:(CXAudioRecorderProgressBlock)progressBlock
        peakPowerBlock:(CXAudioRecorderPeakPowerBlock)peakPowerBlock
         finishedBlock:(CXIMAudioRecordFinishedBlock)finishedBlock
        cancelledBlock:(CXAudioRecorderCancelledBlock)cancelledBlock;

- (void)stopRecord;

- (void)cancelRecord;

- (void)playSound:(CXIMMessageModel *)messageModel
       completion:(CXAudioPlayerCompletionBlock)completion
    downloadAudio:(CXIMAudioDownloadBlock)audioBlock;

- (void)stopAudioPlay;

- (void)didChangeChatToolbarFrameOffsetY:(CGFloat)offsetY changeType:(CXIMChangeType)changeType;
- (void)setTableViewFrameOffsetY:(CGFloat)offsetY contentOffsetTop:(CGFloat)offsetTop;

- (void)didReceiveNewMessages:(NSArray<TIMMessage *> *)messages;

- (void)didReceiveNewMessages:(NSArray<TIMMessage *> *)messages
                downloadAudio:(CXIMAudioDownloadBlock)audioBlock;

- (void)browser:(CXAssetBrowser *)browser didStartPlayVideo:(NSURL *)videoURL;

- (void)browser:(CXAssetBrowser *)browser didStopPlayVideo:(NSURL *)videoURL;

- (void)didEnterCameraPage;

- (void)didExitCameraPage;

@end

@interface CXIMChatParams : NSObject

@property (nonatomic, copy) NSString *id; // 会话id，单聊为对方id，群聊为群id
@property (nonatomic, assign) NSInteger type; // 会话类型（CX_IM_CONVERSATION_C2C | CX_IM_CONVERSATION_GROUP）
@property (nonatomic, copy) NSString *name; // 页面显示的标题

@end
