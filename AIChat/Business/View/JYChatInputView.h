//
//  JYChatInputView.h
//  AIChat
//
//  Created by JiangYing on 2025/10/4.
//

#import <UIKit/UIKit.h>
#import "JYChatInputOptionView.h"

@interface JYChatInputView : UIView

@property(nonatomic, strong, nonnull) UITextView *textView;
@property(nonatomic, strong, nonnull) JYChatInputOptionView *deepThinkingOptionView;
@property(nonatomic, strong, nonnull) JYChatInputOptionView *onlineSearchOptionView;

@property(nonatomic, copy, nullable) void (^sendAction)(void);

@end
