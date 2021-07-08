//
//  CXIMMessageModel+CXAssetBrowserSupport.m
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import "CXIMMessageModel+CXAssetBrowserSupport.h"

@implementation CXIMMessageModel (CXAssetBrowserSupport)

- (CXAssetModel *)assetBrowserDataModel{
    if([self.elem isKindOfClass:[TIMImageElem class]]){
        return [self assetBrowserDataModelWithImageElem:(TIMImageElem *)self.elem];
    }
    
    if([self.elem isKindOfClass:[TIMVideoElem class]]){
        return [self assetBrowserDataModelWithVideoElem:(TIMVideoElem *)self.elem];
    }
    
    return nil;
}

- (CXAssetModel *)assetBrowserDataModelWithImageElem:(TIMImageElem *)elem{
    if([self.message isSelf]){
        if([[NSFileManager defaultManager] fileExistsAtPath:elem.path]){
            return [[CXAssetModel alloc] initWithImageURL:[NSURL fileURLWithPath:elem.path]];
        }
    }
    
    __block NSString *imageURL = nil;
    [elem.imageList enumerateObjectsUsingBlock:^(TIMImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        imageURL = obj.url;
        if(obj.type == TIM_IMAGE_TYPE_LARGE){
            *stop = YES;
        }
    }];
    
    if(imageURL){
        return [[CXAssetModel alloc] initWithImageURL:[NSURL URLWithString:imageURL]];
    }
    
    return nil;
}

- (CXAssetModel *)assetBrowserDataModelWithVideoElem:(TIMVideoElem *)elem{
    if([self.message isSelf]){
        if([[NSFileManager defaultManager] fileExistsAtPath:elem.videoPath]){
            return [[CXAssetModel alloc] initWithVideoURL:[NSURL fileURLWithPath:elem.videoPath] videoSnapshotURL:[NSURL fileURLWithPath:elem.snapshotPath]];
        }
    }
    
    CXAssetModel *assetModel = [[CXAssetModel alloc] initWithVideoURL:nil videoSnapshotURL:[NSURL fileURLWithPath:elem.snapshotPath]];
    assetModel.userInfo = self;
    
    return assetModel;
}

@end
