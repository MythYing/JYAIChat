//
//  JYChatViewController.h
//  AIChat
//
//  Created by JiangYing on 2025/10/3.
//

#import <UIKit/UIKit.h>
#import "JYChatInputView.h"

@interface JYChatViewController : UIViewController

@property(nonatomic, strong, readonly, nonnull) UIScrollView *scrollView;
@property(nonatomic, strong, readonly, nonnull) UIStackView *stackView;
@property(nonatomic, strong, readonly, nonnull) JYChatInputView *inputView;

- (void)startScrollTimer;
- (void)stopScrollTimer;

@end
