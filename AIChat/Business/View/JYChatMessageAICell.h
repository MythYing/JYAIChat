//
//  JYChatMessageAICell.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <JYNonReusableTableView/JYNonReusableTableView.h>
#import "JYModel.h"

@interface JYChatMessageAICell : JYNonReusableTableViewCell

- (void)refreshWithMessage:(JYMessageAI *_Nonnull)message;

@end
