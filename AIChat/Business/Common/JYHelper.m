//
//  JYHelper.m
//  AIChat
//
//  Created by JiangYing on 2025/10/4.
//

#import "JYHelper.h"
#import "JYMacro.h"

@implementation JYHelper

+ (NSString *)searchUrl {
    return @"https://api.bubbclean.com/search";
}

+ (NSString *)webContentListUrl {
    return @"https://api.bubbclean.com/web_content_list";
}

+ (NSString *)aiModelUrl {
    return @"https://api.bubbclean.com/ai_model";
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

- (NSString *)stringByRemovingInvisibleCharacters {
    NSString *pattern = @"[\\u200b-\\u200f\\ufeff\\x00-\\x1f\\x7f]";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (error) {
        return self;
    }
    
    NSString *result = [regex stringByReplacingMatchesInString:self
                                                       options:0
                                                         range:NSMakeRange(0, self.length)
                                                  withTemplate:@""];
    return result;
}

@end

@implementation EventSource (JYExtension)

- (void)onMessage:(EventSourceEventHandler)onMessage
          onClose:(EventSourceEventHandler)onClose
          onError:(EventSourceEventHandler)onError {
    [self onMessage:^(EventSourceEvent * _Nonnull event) {
        if (![event.event isEqualToString:@"token_stat"]) {
            NSLog(@"[jy] onMessage: \n"
                  "event.id: %@ \n"
                  "event.event: %@ \n"
                  "event.data: %@", event.id, event.event, event.data);
        }
        JY_SAFE_BLOCK(onMessage, event);
    }];
    [self onClose:^(EventSourceEvent * _Nonnull event) {
        NSLog(@"[jy] onClose: \n"
              "event.id: %@ \n"
              "event.event: %@ \n"
              "event.data: %@", event.id, event.event, event.data);
        JY_SAFE_BLOCK(onClose, event);
    }];
    [self onError:^(EventSourceEvent * _Nonnull event) {
        NSLog(@"[jy] onError: \n"
              "error: %@", event.error);
        JY_SAFE_BLOCK(onError, event);
    }];
}

@end

@implementation NSError (JYExtension)

+ (NSError *)emptyResultError {
    return [NSError errorWithDomain:@"JYChatErrorDomain"
                               code:1
                           userInfo:@{
        NSLocalizedDescriptionKey: @"result is empty",
    }];
}

@end
