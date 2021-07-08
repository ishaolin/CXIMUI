//
//  CXIMChatViewController.m
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import "CXIMChatViewController.h"
#import <CXIMSDK/CXIMSDK.h>
#import "CXIMTableViewCell.h"
#import "CXIMImageTableViewCell.h"
#import "CXIMRefreshHeader.h"
#import "CXIMCameraViewController.h"
#import "CXIMMessageModel+CXAssetBrowserSupport.h"
#import "CXIMImageDefines.h"
#import "NSDate+CXIMExtensions.h"
#import "CXIMMessageHandler.h"

@interface CXIMChatViewController () <CXIMMessageListener, CXIMChatToolbarDelegate, CXIMTableViewCellDelegate, CXAssetBrowserDelegate> {
    CXIMRefreshHeader *_refreshHeader;
    NSMutableArray<CXIMMessageModel *> *_messageModels;
    CXIMMessageModel *_lastTimeMessageModel; // 显示时间判断
    
    CXIMMessageModel *_soundPlayingModel;
    TIMMessage *_lastPageMessage;
}

@property (nonatomic, weak, readonly) CXAssetBrowser *browser;

@end

@implementation CXIMChatViewController

- (void)setChatParams:(CXIMChatParams *)params{
    if(CXStringIsEmpty(params.id) || [[_conversation getReceiver] isEqualToString:params.id]){
        return;
    }
    _conversation = [[CXIMManager sharedManager] conversationWithIdentifier:params.id type:params.type];
    
    void (^reloadMessageBlock)(void) = ^{
        if(self->_lastTimeMessageModel){
            [self->_messageModels removeAllObjects];
            self->_lastTimeMessageModel = nil;
            self->_lastPageMessage = nil;
            [self->_browser dismissWithAnimated:NO];
            [self->_tableView reloadData];
            
            [self loadHistoryMessage];
        }
    };
    
    self.title = params.name;
    if(params.type != CX_IM_CONVERSATION_C2C){
        reloadMessageBlock();
        return;
    }
    
    if(CXStringIsEmpty(self.title)){
        TIMUserProfile *profile = [CXIMProfileUtils friendProfile:params.id];
        if(profile){
            self.title = profile.displayName;
        }else{
            [CXIMProfileUtils userProfile:params.id success:^(TIMUserProfile * _Nullable profile) {
                self.title = profile.displayName;
            } failure:nil];
        }
    }
    
    reloadMessageBlock();
}

- (void)onNewMessage:(NSArray<TIMMessage *> *)messages{
    [self didReceiveNewMessages:messages];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = CXHexIColor(0xF9F9F9);
    _messageModels = [NSMutableArray array];
    [[CXIMManager sharedManager] addMessageListener:self];
    
    _refreshHeader = [CXIMRefreshHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadHistoryMessage)];
    _refreshHeader.stateLabel.hidden = YES;
    
    _chatToolbar = [[CXIMChatToolbar alloc] init];
    _chatToolbar.minimumHeight = 50.0 + [UIScreen mainScreen].cx_safeAreaInsets.bottom;
    _chatToolbar.delegate = self;
    _chatToolbar.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:_chatToolbar];
    CGFloat chatToolbar_X = 0;
    CGFloat chatToolbar_W = CGRectGetWidth(self.view.bounds);
    CGFloat chatToolbar_H = _chatToolbar.minimumHeight;
    CGFloat chatToolbar_Y = CGRectGetHeight(self.view.bounds) - chatToolbar_H;
    _chatToolbar.frame = (CGRect){chatToolbar_X, chatToolbar_Y, chatToolbar_W, chatToolbar_H};
    
    CGFloat tableView_X = chatToolbar_X;
    CGFloat tableView_Y = CGRectGetMaxY(self.navigationBar.frame);
    CGFloat tableView_W = chatToolbar_W;
    CGFloat tableView_H = chatToolbar_Y - tableView_Y;
    _tableView = [[CXTableView alloc] initWithFrame:CGRectMake(tableView_X, tableView_Y, tableView_W, tableView_H) style:UITableViewStylePlain];
    _tableView.backgroundColor = CXHexIColor(0xF9F9F9);
    _tableView.estimatedRowHeight = 0.0;
    _tableView.estimatedSectionFooterHeight = 0.0;
    _tableView.estimatedSectionHeaderHeight = 0.0;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    @weakify(self);
    _tableView.hitTestBlock = ^UIView *(CXTableView *tableView, UIView *hitTestView, CGPoint point, UIEvent *event) {
        @strongify(self);
        [self.view endEditing:YES];
        return hitTestView;
    };
    
    [self loadHistoryMessage];
}

- (void)IMManager:(CXIMManager *)manager didReceiveNewMessages:(NSArray<TIMMessage *> *)messages{
    [self didReceiveNewMessages:messages];
}

- (void)didReceiveNewMessages:(NSArray<TIMMessage *> *)messages{
    [self didReceiveNewMessages:messages downloadAudio:nil];
}

- (void)didReceiveNewMessages:(NSArray<TIMMessage *> *)messages downloadAudio:(CXIMAudioDownloadBlock)audioBlock{
    [self setReadMessage:nil retryTimes:0];
    
    [CXIMMessageHandler convertMessages:messages conversation:_conversation completion:^(NSArray<CXIMMessageModel *> *messageModels) {
        if(CXArrayIsEmpty(messageModels)){
            return;
        }
        
        [messageModels enumerateObjectsUsingBlock:^(CXIMMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self->_messageModels addObject:obj];
            [self showMessageTime:obj];
            
            if([obj.elem isKindOfClass:[TIMSoundElem class]]){
                [obj downloadAudio:^(NSURL *audioURL) {
                    !audioBlock ?: audioBlock(audioURL, obj);
                }];
            }
        }];
        
        CGSize size = self.tableView.contentSize;
        CGPoint contentOffset = self.tableView.contentOffset;
        [self.tableView reloadData];
        
        if(size.height - contentOffset.y > CGRectGetHeight(self.tableView.frame) * 1.5){
            [self.tableView setContentOffset:contentOffset animated:NO];
        }else{
            [self scrollToBottomAnimated:NO];
        }
    }];
}

- (void)didReceiveHistoryMessages:(NSArray<TIMMessage *> *)messages{
    [self.tableView.mj_header endRefreshing];
    
    if(CXArrayIsEmpty(messages)){
        self.tableView.mj_header = nil;
        return;
    }
    
    [CXIMMessageHandler convertMessages:messages conversation:_conversation completion:^(NSArray<CXIMMessageModel *> *messageModels) {
        if(CXArrayIsEmpty(messageModels)){
            return;
        }
        
        NSUInteger count = self->_messageModels.count;
        if(count == 0){
            self.tableView.mj_header = self->_refreshHeader;
            [self setReadMessage:nil retryTimes:0];
        }
        
        [messageModels enumerateObjectsUsingBlock:^(CXIMMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self->_messageModels insertObject:obj atIndex:0];
            
            // 处理语音数据
            if([obj.elem isKindOfClass:[TIMSoundElem class]]){
                TIMSoundElem *soundElem = (TIMSoundElem *)obj.elem;
                NSString *path = CX_DOWNLOAD_PATH_GET([[CXUCryptor MD5:soundElem.uuid] stringByAppendingString:@".mp4"]);
                if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
                    [soundElem getSound:path succ:nil fail:nil];
                }
                obj.soundReaded = YES;
            }
        }];
        
        // 处理历史消息的时间显示问题
        self->_lastTimeMessageModel = nil; // 清除原标记
        __block CGPoint point = CGPointZero;
        [self->_messageModels enumerateObjectsUsingBlock:^(CXIMMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(idx <= messageModels.count){
                [self showMessageTime:obj];
                
                if(idx != messageModels.count){
                    point.y += obj.height;
                }
            }else{
                *stop = YES;
            }
        }];
        self->_lastTimeMessageModel = self->_messageModels.lastObject; // 还原原标记
        
        point.y -= self.tableView.contentInset.top;
        [self.tableView reloadData];
        
        if(count == 0){
            [self scrollToBottomAnimated:NO];
        }else{
            [self.tableView setContentOffset:point animated:NO];
        }
    }];
}

#pragma mark - 获取历史消息

- (void)loadHistoryMessage{
    [self.conversation historyMessage:CX_IM_MSSAGE_PAGE_SIZE last:_lastPageMessage success:^(NSArray<TIMMessage *> * _Nullable messages) {
        self->_lastPageMessage = messages.lastObject;
        [self didReceiveHistoryMessages:messages];
    } failure:^(int code, NSString * _Nullable error) {
        [self didReceiveHistoryMessages:nil];
    }];
}

#pragma mark - 父类功能方法

- (void)startRecording:(CXAudioRecorderProgressBlock)progressBlock
        peakPowerBlock:(CXAudioRecorderPeakPowerBlock)peakPowerBlock
         finishedBlock:(CXIMAudioRecordFinishedBlock)finishedBlock
        cancelledBlock:(CXAudioRecorderCancelledBlock)cancelledBlock{
    if([CXAudioRecorder sharedRecorder].isRecording){
        return ;
    }
    
    [self stopAudioPlay];
    
    [[CXAudioRecorder sharedRecorder] startRecording:progressBlock peakPowerBlock:peakPowerBlock finishedBlock:^(CXAudioRecorder *recorder, NSString *filePath, NSUInteger duration, NSError *error) {
        [self sendSoundMessage:filePath];
        !finishedBlock ?: finishedBlock(filePath, error);
    } cancelledBlock:cancelledBlock];
}

- (void)stopRecord{
    [[CXAudioRecorder sharedRecorder] stopRecording];
}

- (void)cancelRecord{
    [[CXAudioRecorder sharedRecorder] cancelRecording];
}

#pragma mark - 设置已读

- (void)setReadMessage:(TIMMessage *)message retryTimes:(NSInteger)retryTimes{
    if(retryTimes < 0){
        return;
    }
    
    @weakify(self)
    [_conversation setReadMessage:message succ:nil fail:^(int code, NSString *msg) {
        @strongify(self)
        [self setReadMessage:message retryTimes:(retryTimes - 1)];
    }];
}

#pragma mark - UITableViewDelegate代理方法

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _messageModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CXIMMessageModel *messageModel = _messageModels[indexPath.row];
    CXIMTableViewCell *cell = [CXIMTableViewCell cellWithTableView:tableView messageModel:messageModel];
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CXIMMessageModel *messageModel = _messageModels[indexPath.row];
    CGFloat height = messageModel.height;
    if(indexPath.row == _messageModels.count - 1){
        height += 15.0;
    }
    
    return height;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
}

#pragma mark - CXIMChatToolbarDelegate

- (void)IMChatToolbar:(CXIMChatToolbar *)chatToolbar sendText:(NSString *)text{
    if(CXStringIsAllSpace(text)){
        [chatToolbar endEditing:YES];
        [CXAlertControllerUtils showAlertWithConfigBlock:^(CXAlertControllerConfigModel *config) {
            config.title = @"不能发送空白消息";
            config.buttonTitles = @[@"确定"];
        } completion:nil];
    }else{
        [self sendTextMessage:text];
    }
}

- (void)IMChatToolbarActionForSelectPhoto:(CXIMChatToolbar *)chatToolbar{
    [self.view endEditing:YES];
    CXDataRecord(@"30000110");
    [self didEnterCameraPage];
    
    CXIMCameraViewController *cameraViewController = [[CXIMCameraViewController alloc] initWithCompletionBlock:^(CXIMCameraViewController *VC, NSString *videoPath, NSArray<NSString *> *imagePaths) {
        if(CXStringIsEmpty(videoPath)){
            [imagePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self sendMessage:[TIMMessage messageWithImage:obj]];
            }];
        }else{
            [self sendVideoMessage:videoPath coverPath:imagePaths.firstObject];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self didExitCameraPage];
        });
    }];
    
    [self.navigationController pushViewController:cameraViewController animated:YES];
}

- (void)IMChatToolbar:(CXIMChatToolbar *)chatToolbar didChangeFrame:(CGRect)frame changeType:(CXIMChangeType)changeType{
    CGFloat offsetY = CGRectGetMaxY(self.view.frame) - chatToolbar.minimumHeight - CGRectGetMinY(frame);
    [self didChangeChatToolbarFrameOffsetY:offsetY changeType:changeType];
    
    if(changeType == CXIMChangeTypeKeyboardHide){
        [_tableView reloadData];
    }
    
    [self scrollToBottomAnimated:NO];
}

- (void)didChangeChatToolbarFrameOffsetY:(CGFloat)offsetY changeType:(CXIMChangeType)changeType{
    [self setTableViewFrameOffsetY:offsetY contentOffsetTop:0];
}

- (void)setTableViewFrameOffsetY:(CGFloat)offsetY contentOffsetTop:(CGFloat)offsetTop{
    CGRect frame = self.tableView.frame;
    frame.origin.y = CGRectGetMaxY(self.navigationBar.frame) - offsetY;
    self.tableView.contentInset = UIEdgeInsetsMake(offsetY + offsetTop, 0, 0, 0);
    self.tableView.frame = frame;
}

#pragma mark - 发送消息

- (void)sendTextMessage:(NSString *)text{
    [self sendMessage:[TIMMessage messageWithText:text]];
}

- (void)sendImageMessage:(NSString *)imagePath{
    [self sendMessage:[TIMMessage messageWithImage:imagePath]];
}

- (void)sendSoundMessage:(NSString *)soundPath{
    [self sendMessage:[TIMMessage messageWithSound:soundPath]];
}

- (void)sendVideoMessage:(NSString *)videoPath coverPath:(NSString *)coverPath{
    [self sendMessage:[TIMMessage messageWithVideo:videoPath cover:coverPath]];
}

- (void)sendMessage:(TIMMessage *)message{
    [self sendMessage:message resend:NO];
}

- (void)sendMessage:(TIMMessage *)message resend:(BOOL)resend{
    if(!message){
        return;
    }
    
    if(![CXIMManager sharedManager].logined){
        [CXHUD showMsg:@"消息服务器未连接，请重新登录"];
    }
    
    CXIMMessageModel *model = [[CXIMMessageModel alloc] initWithMessage:message];
    if([message.elem isKindOfClass:[TIMSoundElem class]]){
        model.soundReaded = YES;
    }
    
    [self showMessageTime:model resend:resend];
    [_messageModels addObject:model];
    
    [_tableView reloadData];
    [self scrollToBottomAnimated:NO];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(_messageModels.count - 1) inSection:0];
    [_conversation sendMessage:message succ:^{
        [NSNotificationCenter notify:CXIMSendMsgFinishedNotification
                            userInfo:@{CXNotificationUserInfoKey0 : self->_conversation}];
        [self reloadRowsAtIndexPaths:@[indexPath]];
    } fail:^(int code, NSString *msg) {
        [NSNotificationCenter notify:CXIMSendMsgFinishedNotification
                            userInfo:@{CXNotificationUserInfoKey0 : self->_conversation}];
        if([self->_conversation getType] == TIM_C2C){
            /*
             * 20009: 消息发送双方互相不是好友，禁止发送（配置单聊消息校验好友关系才会出现）
             * 20010: 发送单聊消息，自己不是对方的好友（单向关系），禁止发送
             * 20011: 发送单聊消息，对方不是自己的好友（单向关系），禁止发送
             */
            NSString *errorMsg = nil;
            if(code == 20009 || code == 20010 || code == 20011){
                errorMsg = @"对方和你已不是好友关系";
            }else if (code == 10015){
                errorMsg = @"小队ID非法，请检查小队ID是否填写正确。";
            }
            
            model.errorMsg = errorMsg;
        }
        
        [self reloadRowsAtIndexPaths:@[indexPath]];
        [self scrollToBottomAnimated:NO];
    }];
}

- (void)showMessageTime:(CXIMMessageModel *)model{
    [self showMessageTime:model resend:NO];
}

- (void)showMessageTime:(CXIMMessageModel *)model resend:(BOOL)resend{
    NSDate *date = resend ? [NSDate date] : [model.message timestamp];
    if(_lastTimeMessageModel){
        NSDate *lastDate = [_lastTimeMessageModel.message timestamp];
        CGFloat lastTime = [lastDate cx_timeStampForMillisecond] / 1000.0;
        CGFloat time = [date cx_timeStampForMillisecond] / 1000.0;
        if(fabs(time - lastTime) > 300.0){
            model.time = [NSDate im_formattingDateToString:date];
        }
    }else{
        model.time = [NSDate im_formattingDateToString:date];
    }
    
    _lastTimeMessageModel = model;
}

- (void)reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths{
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)scrollToBottomAnimated:(BOOL)animated{
    CGPoint contentOffset = self.tableView.contentOffset;
    contentOffset.y = self.tableView.contentSize.height - CGRectGetHeight(self.tableView.frame);
    if(contentOffset.y + self.tableView.contentInset.top <= 0){
        return;
    }
    
    [self.tableView setContentOffset:contentOffset animated:animated];
}

- (void)IMTableViewCellDidClickResend:(CXIMTableViewCell *)cell{
    if([_messageModels containsObject:cell.messageModel]){
        [_messageModels removeObject:cell.messageModel];
        [_tableView reloadData];
    }
    
    _lastTimeMessageModel = _messageModels.lastObject;
    [self sendMessage:cell.messageModel.message resend:YES];
}

- (void)IMTableViewCellDidClickSound:(CXIMTableViewCell *)cell{
    [self playSound:cell.messageModel completion:nil downloadAudio:nil];
}

- (void)stopAudioPlay{
    if([CXAudioPlayer sharedPlayer].isPlaying){
        _soundPlayingModel.soundPlaying = NO;
        [[CXAudioPlayer sharedPlayer] stopPlay];
        [self.tableView reloadData];
    }
}

- (void)playSound:(CXIMMessageModel *)messageModel completion:(CXAudioPlayerCompletionBlock)completion downloadAudio:(CXIMAudioDownloadBlock)audioBlock{
    if([CXAudioRecorder sharedRecorder].isRecording || ![messageModel.elem isKindOfClass:[TIMSoundElem class]]){
        return;
    }
    
    messageModel.soundReaded = YES;
    if([CXAudioPlayer sharedPlayer].isPlaying){
        [self stopAudioPlay];
        if(messageModel == _soundPlayingModel){
            !completion ?: completion([CXAudioPlayer sharedPlayer], nil);
            return;
        }
    }
    
    void (^playAudioBlock)(BOOL) = ^(BOOL playing){
        messageModel.soundPlaying = playing;
        [self.tableView reloadData];
    };
    
    [messageModel downloadAudio:^(NSURL *audioURL) {
        !audioBlock ?: audioBlock(audioURL, messageModel);
        if(!audioURL){
            return;
        }
        
        self->_soundPlayingModel = messageModel;
        playAudioBlock(YES);
        [[CXAudioPlayer sharedPlayer] setAudioPlayerCategory:AVAudioSessionCategoryPlayback];
        [[CXAudioPlayer sharedPlayer] playWithURL:audioURL completion:^(CXAudioPlayer *player, NSError *error) {
            playAudioBlock(NO);
            !completion ?: completion(player, error);
        }];
    }];
}

- (void)IMTableViewCell:(CXIMTableViewCell *)cell didClickImage:(UIImageView *)imageView{
    NSMutableArray<CXAssetModel *> *assetModels = [NSMutableArray array];
    NSMutableDictionary<NSNumber *, UIView *> *assetViews = [NSMutableDictionary dictionary];
    __block NSInteger currentIndex = 0;
    [_messageModels enumerateObjectsUsingBlock:^(CXIMMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CXAssetModel *assetModel = [obj assetBrowserDataModel];
        if(!assetModel){
            return;
        }
        
        if(obj == cell.messageModel){
            currentIndex = assetModels.count;
        }
        
        UIImageView *visibleImageView = [self visibleImageViewForMessageModel:obj];
        if(visibleImageView){
            assetViews[@(assetModels.count)] = visibleImageView;
        }
        
        [assetModels addObject:assetModel];
    }];
    
    CXAssetBrowser *browser = [[CXAssetBrowser alloc] init];
    browser.currentAssetView = imageView;
    browser.assetModels = [assetModels copy];
    browser.assetViews = [assetViews copy];
    browser.delegate = self;
    browser.saveButtonEnabled = YES;
    [browser showWithImage:imageView.image currentIndex:currentIndex];
    _browser = browser;
}

- (UIImageView *)visibleImageViewForMessageModel:(CXIMMessageModel *)messageModel{
    __block UIImageView *imageView = nil;
    [_tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[CXIMImageTableViewCell class]]){
            CXIMImageTableViewCell *cell = (CXIMImageTableViewCell *)obj;
            if(cell.messageModel == messageModel){
                imageView = cell.IMImageView;
                *stop = YES;
            }
        }
    }];
    
    return imageView;
}

- (void)browser:(CXAssetBrowser *)browser downloadVideo:(CXAssetModel *)assetModel snapshot:(CXAssetImageDownloadCompletionBlock)snapshot completion:(CXAssetVideoDownloadCompletionBlock)completion{
    if(!assetModel.userInfo){
        return;
    }
    
    if(assetModel.assetType != CXAssetTypeVideo){
        return;
    }
    
    CXIMMessageModel *messageModel = (CXIMMessageModel *)assetModel.userInfo;
    [messageModel downloadVideo:^(NSURL *videoURL) {
        completion(assetModel, videoURL);
    } snapshotBlock:^(UIImage *image) {
        snapshot(assetModel, image);
    }];
}

- (void)browser:(CXAssetBrowser *)browser saveAssetToPhotosAlbum:(id)asset{
    if([asset isKindOfClass:[UIImage class]]){
        CXImageWriteToSavedPhotosAlbum((UIImage *)asset);
    }
}

- (void)browser:(CXAssetBrowser *)browser didStartPlayVideo:(NSURL *)videoURL{
    [self stopAudioPlay];
}

- (void)browser:(CXAssetBrowser *)browser didStopPlayVideo:(NSURL *)videoURL{
    
}

- (void)didEnterCameraPage{
    [self stopAudioPlay];
}

- (void)didExitCameraPage{
    
}

@end

@implementation CXIMChatParams

@end
