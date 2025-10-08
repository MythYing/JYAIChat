//
//  JYHelper.h
//  AIChat
//
//  Created by JiangYing on 2025/10/4.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JYHelper : NSObject

+ (NSString *_Nonnull)authorization;
+ (NSString *_Nonnull)workflowUrl;
+ (NSString *_Nonnull)workflowId;
+ (NSString *_Nonnull)workflowVersion;

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

@end
