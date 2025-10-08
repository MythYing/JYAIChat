//
//  JYChatMessageUserCell.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <JYNonReusableTableView/JYNonReusableTableView.h>
#import "JYModel.h"

@interface JYChatMessageUserCell : JYNonReusableTableViewCell

- (void)refreshWithMessage:(JYMessageUser *_Nonnull)message;

@end
