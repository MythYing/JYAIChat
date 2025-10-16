//
//  JYChatMessageAICell.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <UIKit/UIKit.h>
#import "JYModel.h"

typedef enum : NSUInteger {
    JYChatMessageAICellAnimationStatusNone = 0,
    JYChatMessageAICellAnimationStatusReady = 1,
    JYChatMessageAICellAnimationStatusRunning = 2,
    JYChatMessageAICellAnimationStatusFulfilled = 3,
} JYChatMessageAICellAnimationStatus;

@interface JYChatMessageAICell : UIView

- (void)refreshWithModel:(JYMessageAIModel)model;

- (void)appendThought:(NSString *_Nonnull)thought;
- (void)finishAppendThought;
- (void)appendContent:(NSString *_Nonnull)content;
- (void)finishAppendContent;

@property(nonatomic, copy, nullable) void (^startAnimationAction)(void);
@property(nonatomic, copy, nullable) void (^stopAnimationAction)(void);
@property(nonatomic, copy, nullable) void (^startThoughtAnimationAction)(void);
@property(nonatomic, copy, nullable) void (^stopThoughtAnimationAction)(void);
@property(nonatomic, copy, nullable) void (^startContentAnimationAction)(void);
@property(nonatomic, copy, nullable) void (^stopContentAnimationAction)(void);
@property(nonatomic, assign, readonly) JYChatMessageAICellAnimationStatus animationStatus;

- (void)startAnimation;

@end
