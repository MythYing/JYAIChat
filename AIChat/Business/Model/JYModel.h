//
//  JYModel.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    JYMessageRoleUnknown = 0,
    JYMessageRoleUser = 1,
    JYMessageRoleAI = 2,
} JYMessageRole;

typedef enum : NSUInteger {
    JYMessageModelNone = 0,
    JYMessageModelMixed = 1,
    JYMessageModelDeepseek = 2,
    JYMessageModelDoubao = 3,
} JYMessageModel;

extern NSString * _Nonnull const JYMessageEventMessage;
extern NSString * _Nonnull const JYMessageEventDone;

extern NSString * _Nonnull const JYMessageModelNameMixed;
extern NSString * _Nonnull const JYMessageModelNameDeepseek;
extern NSString * _Nonnull const JYMessageModelNameDoubao;

extern NSString * _Nonnull const JYMessageModelDeepThinking;
extern NSString * _Nonnull const JYMessageModelFast;

extern NSString * _Nonnull const JYMessageOutputThought;
extern NSString * _Nonnull const JYMessageOutputContent;


@interface JYMessage : NSObject

@property(nonatomic, assign) JYMessageRole role;
@property(nonatomic, assign) JYMessageModel model;
@property(nonatomic, copy, nonnull) NSString *thoughtId;
@property(nonatomic, copy, nonnull) NSString *thought;
@property(nonatomic, copy, nonnull) NSString *contentId;
@property(nonatomic, copy, nonnull) NSString *content;

@end


@interface JYCozeData : NSObject

/// 输出节点的内容
@property(nonatomic, copy, nonnull) NSString *content;
/// 输出节点的内容类型，取值：text
@property(nonatomic, copy, nonnull) NSString *content_type;
/// 输出节点的类型，取值：Message、End
@property(nonatomic, copy, nonnull) NSString *node_type;
/// 输出节点的Id
@property(nonatomic, copy, nonnull) NSString *node_id;
/// 输出节点的标题，格式：大语言模型_是否深度思考_思考或内容
@property(nonatomic, copy, nonnull) NSString *node_title;
/// 输出节点的uuid，可作为消息的id
@property(nonatomic, copy, nonnull) NSString *node_execute_uuid;
/// 输出节点的序号
@property(nonatomic, copy, nonnull) NSString *node_seq_id;
/// 输出节点是否结束
@property(nonatomic, assign) BOOL node_is_finish;

@end
