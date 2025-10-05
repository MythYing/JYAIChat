//
//  JYChatNavigationBar.h
//  AIChat
//
//  Created by JiangYing on 2025/10/4.
//

#import <UIKit/UIKit.h>

@interface JYChatNavigationBar : UIView

@property(nonatomic, copy, nullable) void (^newChatAction)(void);

@end
