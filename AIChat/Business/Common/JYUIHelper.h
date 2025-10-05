//
//  JYUIHelper.h
//  AIChat
//
//  Created by JiangYing on 2025/10/4.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JYUIHelper : NSObject

+ (UIWindow *_Nullable)getKeyWindow;

@end

@interface UIColor (JYExtension)

+ (UIColor *_Nonnull)firstTextColor;
+ (UIColor *_Nonnull)secondTextColor;

+ (UIColor *_Nonnull)placeholderColor;
+ (UIColor *_Nonnull)highlightColor;
+ (UIColor *_Nonnull)separatorLineColor;

@end
