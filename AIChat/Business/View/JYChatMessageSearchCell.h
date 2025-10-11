//
//  JYChatMessageSearchCell.h
//  AIChat
//
//  Created by JiangYing on 2025/10/8.
//

#import <UIKit/UIKit.h>
#import "JYModel.h"

@interface JYChatMessageSearchCell : UIView

- (void)refreshWithMessage:(JYMessageSearch *_Nonnull)message;

- (void)appendResult:(JYMessageSearchResult *_Nonnull)result;

@end
