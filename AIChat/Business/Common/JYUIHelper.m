//
//  JYUIHelper.m
//  AIChat
//
//  Created by JiangYing on 2025/10/4.
//

#import "JYUIHelper.h"
#import <YYKit/YYKit.h>

@implementation JYUIHelper

+ (UIWindow *)getKeyWindow {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) {
                    break;
                }
            }
        }
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0
        keyWindow = [UIApplication sharedApplication].keyWindow;
#endif
    }
    return keyWindow;
}

@end

@implementation UIColor (JYExtension)

+ (UIColor *)firstTextColor {
    return [UIColor colorWithRGB:0x222222];
}

+ (UIColor *)secondTextColor {
    return [UIColor colorWithRGB:0x444444];
}

+ (UIColor *)placeholderColor {
    return [UIColor colorWithRGB:0xAAAAAA];
}

+ (UIColor *)highlightColor {
    return [UIColor colorWithRGB:0x629760];
}

+ (UIColor *)separatorLineColor {
    return [UIColor colorWithRGB:0xEBEBEB];
}

@end
