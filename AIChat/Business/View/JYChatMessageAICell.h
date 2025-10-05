//
//  JYChatMessageAICell.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <UIKit/UIKit.h>
#import "JYModel.h"
#import <JYNonReusableTableView/JYNonReusableTableView.h>

@interface JYChatMessageAICell : JYNonReusableTableViewCell

- (void)refreshWithMessage:(JYMessage *_Nonnull)message;

@end
