//
//  JYModel.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <Foundation/Foundation.h>
#import <YYModel/YYModel.h>

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

extern NSString * _Nonnull const JYMessageEventThought;
extern NSString * _Nonnull const JYMessageEventContent;
extern NSString * _Nonnull const JYMessageEventError;

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
@property(nonatomic, copy, nonnull, readonly) NSString *thought;
@property(nonatomic, copy, nonnull, readonly) NSString *content;

- (void)appendThought:(NSString *_Nonnull)thought;
- (void)appendContent:(NSString *_Nonnull)content;

@end

#pragma mark - JYMessageSearch

@interface JYMessageSearchResult : NSObject

@property(nonatomic, copy, nonnull) NSString *title;
@property(nonatomic, copy, nonnull) NSString *url;
@property(nonatomic, copy, nonnull) NSString *content;

@end


@interface JYMessageSearch : JYMessage

@property(nonatomic, assign) JYMessageSearchEngine engine;
@property(nonatomic, copy, nonnull, readonly) NSArray<JYMessageSearchResult *> *resultList;

- (void)setResultList:(NSArray<JYMessageSearchResult *> *_Nonnull)resultList;
- (void)refreshResult:(JYMessageSearchResult *_Nonnull)result;

@end

#pragma mark - JYAIModelData

@interface JYAIModelData : NSObject

@property(nonatomic, copy, nonnull) NSString *content;
@property(nonatomic, assign) BOOL isBegin;
@property(nonatomic, assign) BOOL isEnd;

@end

#pragma mark - Transform

extern JYMessageAIModel aiModel(NSString *_Nullable modelName);
extern NSString *_Nonnull aiModelName(JYMessageAIModel model);
extern NSString *_Nonnull aiModelDescription(JYMessageAIModel model);

extern JYMessageSearchEngine searchEngine(NSString *_Nullable engineName);
extern NSString *_Nonnull searchEngineName(JYMessageSearchEngine engine);
extern NSString *_Nonnull searchEngineDescription(JYMessageSearchEngine engine);
