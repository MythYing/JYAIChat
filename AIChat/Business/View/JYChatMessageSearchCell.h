//
//  JYChatMessageSearchCell.h
//  AIChat
//
//  Created by JiangYing on 2025/10/8.
//

#import <JYNonReusableTableView/JYNonReusableTableView.h>
#import "JYModel.h"

@interface JYChatMessageSearchCell : JYNonReusableTableViewCell

- (void)refreshWithMessage:(JYMessageSearch *_Nonnull)message;

- (void)appendResult:(JYMessageSearchResult *_Nonnull)result;

@end
