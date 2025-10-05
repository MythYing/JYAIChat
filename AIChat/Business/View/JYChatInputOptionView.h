//
//  JYChatInputOptionView.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <UIKit/UIKit.h>

@interface JYChatInputOptionView : UIView

@property(nonatomic, assign) BOOL isSelected;
@property(nonatomic, copy, nullable) void (^selectAction)(void);

- (void)refreshWithImage:(UIImage *_Nonnull)image title:(NSString *_Nonnull)title;

@end
