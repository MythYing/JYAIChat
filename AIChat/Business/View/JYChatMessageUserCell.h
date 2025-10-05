//
//  JYChatMessageUserCell.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <UIKit/UIKit.h>
#import "JYModel.h"

@interface JYChatMessageUserCell : UITableViewCell

@property(nonatomic, copy, class, readonly, nonnull) NSString *identifier;

+ (CGFloat)cellHeightWithMessage:(JYMessage *_Nonnull)message;

- (void)refreshWithMessage:(JYMessage *_Nonnull)message;

@end
