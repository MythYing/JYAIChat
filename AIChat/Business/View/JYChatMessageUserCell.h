//
//  JYChatMessageUserCell.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <UIKit/UIKit.h>
#import "JYModel.h"

@interface JYChatMessageUserCell : UIView

- (void)refreshWithMessage:(JYMessageUser *_Nonnull)message;

@end
