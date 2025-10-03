//
//  JYMacro.h
//  AIChat
//
//  Created by JiangYing on 2025/10/3.
//

#ifndef JYMacro_h
#define JYMacro_h

#define JY_SAFE_CAST(Object, Class) \
    (UIWindowScene *)([Object isKindOfClass:[Class class]] ? Object : nil)

#endif /* JYMacro_h */
