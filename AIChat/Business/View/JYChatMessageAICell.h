//
//  JYChatMessageAICell.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <UIKit/UIKit.h>
#import <JYSegmentedLabel/JYSegmentedLabel.h>
#import "JYModel.h"

@interface JYChatMessageAICell : UIView

@property(nonatomic, assign) JYMessageAIModel model;

- (void)refreshWithMessage:(JYMessageAI *_Nonnull)message;

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
@property(nonatomic, assign, readonly) JYSegmentedLabelAnimationStatus animationStatus;

- (void)startAnimation;

@end
