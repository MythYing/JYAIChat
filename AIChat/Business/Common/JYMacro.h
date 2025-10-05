//
//  JYMacro.h
//  AIChat
//
//  Created by JiangYing on 2025/10/3.
//

#import <UIKit/UIKit.h>
#import <QMUIKit/QMUIKit.h>
#import <Masonry/Masonry.h>
#import <YYKit/YYKit.h>
#import "JYHelper.h"

#ifndef JYMacro_h
#define JYMacro_h

#define JY_SAFE_CAST(Object, Class) \
    (UIWindowScene *)([Object isKindOfClass:[Class class]] ? Object : nil)

#define JY_SAFE_BLOCK(Block, ...) \
    ( Block ? Block(__VA_ARGS__) : nil )

#endif /* JYMacro_h */
