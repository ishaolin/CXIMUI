//
//  CXIMTableViewCell.h
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import "CXIMImageDefines.h"
#import "CXIMMessageModel.h"

@class CXIMTableViewCell;

@protocol CXIMTableViewCellDelegate <NSObject>

@optional

- (void)IMTableViewCell:(CXIMTableViewCell *)cell didClickImage:(UIImageView *)imageView;
- (void)IMTableViewCellDidClickResend:(CXIMTableViewCell *)cell;
- (void)IMTableViewCellDidClickUserAvatar:(CXIMTableViewCell *)cell;
- (void)IMTableViewCellDidClickSelfAvatar:(CXIMTableViewCell *)cell;
- (void)IMTableViewCellDidClickSound:(CXIMTableViewCell *)cell;

@end

@interface CXIMTableViewCell : CXTableViewCell

@property (nonatomic, weak) id<CXIMTableViewCellDelegate> delegate;
@property (nonatomic, strong) CXIMMessageModel *messageModel;

+ (CXIMTableViewCell *)cellWithTableView:(UITableView *)tableView
                            messageModel:(CXIMMessageModel *)messageModel;

@end
