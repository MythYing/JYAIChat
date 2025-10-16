//
//  JYHelper.h
//  AIChat
//
//  Created by JiangYing on 2025/10/4.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <JYEventSource/EventSource.h>

@interface JYHelper : NSObject

+ (NSString *_Nonnull)searchUrl;
+ (NSString *_Nonnull)webContentListUrl;
+ (NSString *_Nonnull)aiModelUrl;

@end

@interface JYUIHelper : NSObject

+ (UIWindow *_Nullable)getKeyWindow;

@end

@interface UIColor (JYExtension)

+ (UIColor *_Nonnull)firstTextColor;
+ (UIColor *_Nonnull)secondTextColor;
+ (UIColor *_Nonnull)thirdTextColor;

+ (UIColor *_Nonnull)placeholderColor;
+ (UIColor *_Nonnull)highlightColor;
+ (UIColor *_Nonnull)separatorLineColor;

@end

@interface NSString (JYExtension)

- (NSString *_Nonnull)stringByTrimmingLeftCharactersInSet:(NSCharacterSet *_Nonnull)characterSet;
- (NSString *_Nonnull)stringByTrimmingRightCharactersInSet:(NSCharacterSet *_Nonnull)characterSet;
- (NSString *_Nonnull)stringByRemovingInvisibleCharacters;

@end

@interface EventSource (JYExtension)

- (void)onMessage:(EventSourceEventHandler _Nullable)onMessage
          onClose:(EventSourceEventHandler _Nullable)onClose
          onError:(EventSourceEventHandler _Nullable)onError;

@end


@interface NSError (JYExtension)

+  (NSError *_Nonnull)emptyResultError;

@end
