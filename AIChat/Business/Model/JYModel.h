//
//  JYModel.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    JYMessageTypeUnknown = 0,
    JYMessageTypeUser = 1,
    JYMessageTypeAI = 2,
    JYMessageTypeSearch = 3,
} JYMessageType;

typedef enum : NSUInteger {
    JYMessageAIModelNone = 0,
    JYMessageAIModelMixed = 1,
    JYMessageAIModelDeepseek = 2,
    JYMessageAIModelDoubao = 3,
    JYMessageAIModelHunyuan = 4,
} JYMessageAIModel;

typedef enum : NSUInteger {
    JYMessageSearchEngineNone = 0,
    JYMessageSearchEngineToutiao = 1,
    JYMessageSearchEngineBaidu = 2,
    JYMessageSearchEngineSogou = 3,
} JYMessageSearchEngine;

typedef enum : NSUInteger {
    JYMessageStatusNone = 0,
    JYMessageStatusWaiting = 1,
    JYMessageStatusSearching = 2,
    JYMessageStatusAIThinking = 3,
    JYMessageStatusAIReplying = 4,
    JYMessageStatusDone = 5,
} JYMessageStatus;

extern NSString * _Nonnull const JYMessageEventMessage;
extern NSString * _Nonnull const JYMessageEventDone;

extern NSString * _Nonnull const JYMessageTypeNameUser;
extern NSString * _Nonnull const JYMessageTypeNameAI;
extern NSString * _Nonnull const JYMessageTypeNameSearch;

extern NSString * _Nonnull const JYMessageModelNameMixed;
extern NSString * _Nonnull const JYMessageModelNameDeepseek;
extern NSString * _Nonnull const JYMessageModelNameDoubao;
extern NSString * _Nonnull const JYMessageModelNameHunyuan;

extern NSString * _Nonnull const JYMessageModelDeepThinking;
extern NSString * _Nonnull const JYMessageModelFast;

extern NSString * _Nonnull const JYMessageOutputThought;
extern NSString * _Nonnull const JYMessageOutputContent;

extern NSString * _Nonnull const JYMessageSearchEngineNameToutiao;
extern NSString * _Nonnull const JYMessageSearchEngineNameBaidu;
extern NSString * _Nonnull const JYMessageSearchEngineNameSogou;

#pragma mark - JYMessage

@interface JYMessage : NSObject

@property(nonatomic, assign, readonly) JYMessageType type;

@end

#pragma mark - JYMessageUser

@interface JYMessageUser : JYMessage

@property(nonatomic, copy, nonnull) NSString *contentId;
@property(nonatomic, copy, nonnull) NSString *content;

@end

#pragma mark - JYMessageAI

@interface JYMessageAI : JYMessage

@property(nonatomic, assign) JYMessageAIModel model;
@property(nonatomic, copy, nonnull) NSString *thoughtId;
@property(nonatomic, copy, nonnull, readonly) NSString *thought;
@property(nonatomic, copy, nonnull) NSString *contentId;
@property(nonatomic, copy, nonnull, readonly) NSString *content;

- (void)appendThought:(NSString *_Nonnull)thought;
- (void)appendContent:(NSString *_Nonnull)content;

+ (JYMessageAIModel)aiModelFromModelName:(NSString *_Nullable)modelName;
+ (NSString *_Nonnull)modelDescriptionWithAIModel:(JYMessageAIModel)aiModel;

@end

#pragma mark - JYMessageSearch

@interface JYMessageSearchResult : NSObject

@property(nonatomic, copy, nonnull) NSString *title;
@property(nonatomic, copy, nonnull) NSString *url;

@end


@interface JYMessageSearch : JYMessage

@property(nonatomic, assign) JYMessageSearchEngine engine;
@property(nonatomic, copy, nonnull, readonly) NSArray<JYMessageSearchResult *> *resultList;

- (void)appendResult:(JYMessageSearchResult *_Nonnull)result;

+ (JYMessageSearchEngine)searchEngineFromEngineName:(NSString *_Nullable)engineName;
+ (NSString *_Nonnull)engineDescriptionWithSearchEngine:(JYMessageSearchEngine)searchEngine;

@end

#pragma mark - JYCozeData

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
