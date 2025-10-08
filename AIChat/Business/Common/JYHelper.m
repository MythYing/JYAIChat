//
//  JYHelper.m
//  AIChat
//
//  Created by JiangYing on 2025/10/4.
//

#import "JYHelper.h"
#import <YYKit/YYKit.h>

@implementation JYHelper

+ (NSString *)authorization {
    return @"Bearer sat_H1Mqn84uMjTk2iodnjgmQd0HYrKYSvaoTNH0nXjNLO8gGt1o5CLvVkqyL9qNEWqW";
}

+ (NSString *)workflowUrl {
    return @"https://api.coze.cn/v1/workflow/stream_run";
}

+ (NSString *)workflowId {
    return @"7557225276296888329";
}

+ (NSString *)workflowVersion {
    return @"v0.0.6";
}

@end

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

+ (UIColor *)thirdTextColor {
    return [UIColor colorWithRGB:0x888888];
}

+ (UIColor *)placeholderColor {
    return [UIColor colorWithRGB:0xAAAAAA];
}

+ (UIColor *)highlightColor {
    return [UIColor colorWithRGB:0x772BFD];
}

+ (UIColor *)separatorLineColor {
    return [UIColor colorWithRGB:0xEBEBEB];
}

@end

@implementation NSString (JYExtension)

- (NSString *)stringByTrimmingLeftCharactersInSet:(NSCharacterSet *)characterSet {
    NSUInteger length = [self length];
    if (length == 0) {
        return self;
    }
    
    unichar charBuffer[length];
    [self getCharacters:charBuffer range:NSMakeRange(0, length)];

    NSUInteger location = 0;
    while (location < length && [characterSet characterIsMember:charBuffer[location]]) {
        location++;
    }
    return [self substringWithRange:NSMakeRange(location, length - location)];
}

- (NSString *)stringByTrimmingRightCharactersInSet:(NSCharacterSet *)characterSet {
    NSUInteger length = [self length];
    if (length == 0) {
        return self;
    }
    
    unichar charBuffer[length];
    [self getCharacters:charBuffer range:NSMakeRange(0, length)];

    while (length > 0 && [characterSet characterIsMember:charBuffer[length - 1]]) {
        length--;
    }
    return [self substringWithRange:NSMakeRange(0, length)];
}

@end
