//
//  JYPromiseHelper.m
//  AIChat
//
//  Created by JiangYing on 2025/10/16.
//

#import "JYPromiseHelper.h"
#import "JYMacro.h"
#import <JYEventSource/EventSource.h>
#import <AFNetworking/AFNetworking.h>
#import <CommonCrypto/CommonHMAC.h>

@interface JYPromiseHelper ()

@property(nonatomic, strong) YYThreadSafeArray *eventSourceList;

@end

@implementation JYPromiseHelper

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static JYPromiseHelper *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _eventSourceList = [YYThreadSafeArray array];
    }
    return self;
}

#pragma mark - Promise

- (AnyPromise *)requestSearchWithKeyword:(NSString *)keyword engine:(JYMessageSearchEngine)engine {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSString *urlString = JYHelper.searchUrl;
        NSDictionary *parameters = @{
            @"query": keyword ?: @"",
            @"engine": searchEngineName(engine),
            @"count": @(10),
        };
        
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [manager POST:urlString parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSDictionary *responseDic = JY_SAFE_CAST(responseObject, NSDictionary);
            NSArray *resultDicList = JY_SAFE_CAST(responseDic[@"data"][@"resultList"], NSArray);
            NSArray<JYMessageSearchResult *> *resultList = [resultDicList qmui_compactMapWithBlock:^id _Nullable(NSString * _Nonnull item) {
                JYMessageSearchResult *result = [JYMessageSearchResult yy_modelWithJSON:item];
                return (result.title.length > 0 && result.url.length > 0) ? result : nil;
            }];
            if (resultList.count > 0) {
                NSLog(@"[jy] requestSearch onResult, result: %@", resultList.yy_modelToJSONString);
                resolve(resultList);
            } else {
                NSError *error = NSError.emptyResultError;
                NSLog(@"[jy] requestSearch onError, error: %@", error);
                resolve(error);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"[jy] requestSearch onError, error: %@", error);
            resolve(error);
            return;
        }];
    }];
}

- (AnyPromise *)requestWebContentListWithUrlList:(NSArray<NSString *> *)urlList {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSString *urlString = JYHelper.webContentListUrl;
        NSDictionary *parameters = @{
            @"urlList": urlList ?: @[],
        };
        
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [manager POST:urlString parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSDictionary *responseDic = JY_SAFE_CAST(responseObject, NSDictionary);
            NSArray *resultDicList = JY_SAFE_CAST(responseDic[@"data"][@"resultList"], NSArray);
            NSArray<JYMessageSearchResult *> *resultList = [resultDicList qmui_compactMapWithBlock:^id _Nullable(NSString * _Nonnull item) {
                JYMessageSearchResult *result = [JYMessageSearchResult yy_modelWithJSON:item];
                return (result.title.length > 0 && result.url.length > 0 && result.content.length > 0) ? result : nil;
            }];
            if (resultList.count > 0) {
                NSLog(@"[jy] requestWebContent onResult, result: %@", resultList.yy_modelToJSONString);
                resolve(resultList);
            } else {
                NSError *error = NSError.emptyResultError;
                NSLog(@"[jy] requestWebContent onError, error: %@", error);
                resolve(error);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"[jy] requestWebContent onError, error: %@", error);
            resolve(error);
            return;
        }];
    }];
}

- (AnyPromise *)requestSearchKeywordWithQuery:(NSString *)query {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSString *prompt = [NSString stringWithFormat: @"# 角色""\n"
                            "你是一个擅长“提取搜索关键词”的专家，用户会给你一段问题的文本，你能准确地提取关键词，以供搜索使用。""\n"
                            "# 限制""\n"
                            "只回复提取后的关键词，不回复其它无关内容，多个关键词之间用空格分隔。""\n"
                            "# 问题""\n"
                            "%@""\n", query ?: @""];
        EventSourceConfig *config = [[EventSourceConfig alloc] init];
        config.url = [NSURL URLWithString:JYHelper.aiModelUrl];
        config.method = @"POST";
        config.headers = @{
            @"Content-Type": @"application/json",
        };
        config.body = @{
            @"prompt": prompt,
            @"model": JYMessageModelNameDeepseek,
            @"enableDeepThinking": @(NO),
            @"enableStream": @(NO),
        }.jsonStringEncoded.dataValue;
        EventSource *eventSource = [[EventSource alloc] initWithConfig:config];
        [self.eventSourceList addObject:eventSource];
        
        @weakify(eventSource);
        __block NSString *result;
        [eventSource onMessage:^(EventSourceEvent * _Nonnull event) {
            if ([event.event isEqualToString:JYMessageEventContent]) {
                JYAIModelData *data = [JYAIModelData yy_modelWithJSON:event.data];
                result = data.content;
            }
        } onClose:^(EventSourceEvent * _Nonnull event) {
            @strongify(eventSource);
            [self.eventSourceList removeObject:eventSource];
            if (result.length > 0) {
                NSLog(@"[jy] requestSearchKeyword onResult, result: %@", result);
                resolve(result);
            } else {
                NSError *error = NSError.emptyResultError;
                NSLog(@"[jy] requestSearchKeyword onError, error: %@", error);
                resolve(error);
            }
        } onError:^(EventSourceEvent * _Nonnull event) {
            @strongify(eventSource);
            [self.eventSourceList removeObject:eventSource];
            NSLog(@"[jy] requestSearchKeyword onError, error: %@", event.error);
            resolve(event.error);
        }];
    }];
}

- (AnyPromise *)requestAIModelWithPrompt:(NSString *)prompt
                               aiMessage:(JYMessageAI *)aiMessage
                                  aiCell:(JYChatMessageAICell *)aiCell
                      enableDeepThinking:(BOOL)enableDeepThinking {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSString *modelName = aiModelName(aiMessage.model);
        EventSourceConfig *config = [[EventSourceConfig alloc] init];
        config.url = [NSURL URLWithString:JYHelper.aiModelUrl];
        config.method = @"POST";
        config.headers = @{
            @"Content-Type": @"application/json",
        };
        config.body = @{
            @"prompt": prompt,
            @"model": modelName,
            @"enableDeepThinking": @(enableDeepThinking),
            @"enableStream": @(YES),
        }.jsonStringEncoded.dataValue;
        EventSource *eventSource = [[EventSource alloc] initWithConfig:config];
        [self.eventSourceList addObject:eventSource];
        
        @weakify(eventSource);
        [eventSource onMessage:^(EventSourceEvent * _Nonnull event) {
            if ([event.event isEqualToString:JYMessageEventThought]) {
                JYAIModelData *data = [JYAIModelData yy_modelWithJSON:event.data];
                BOOL isBegin = aiMessage.thought.length == 0;
                BOOL isEnd = data.isEnd;
                NSString *thought = data.content ?: @"";
                if (isBegin) {
                    thought = [thought stringByTrimmingLeftCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                if (isEnd) {
                    thought = [thought stringByTrimmingRightCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                [aiMessage appendThought:thought];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [aiCell appendThought:thought];
                    if (isEnd) {
                        [aiCell finishAppendThought];
                    }
                });
            } else if ([event.event isEqualToString:JYMessageEventContent]) {
                JYAIModelData *data = [JYAIModelData yy_modelWithJSON:event.data];
                BOOL isBegin = aiMessage.content.length == 0;
                BOOL isEnd = data.isEnd;
                NSString *content = data.content ?: @"";
                if (isBegin) {
                    content = [content stringByTrimmingLeftCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                if (isEnd) {
                    content = [content stringByTrimmingRightCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                [aiMessage appendContent:content];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [aiCell appendContent:content];
                    if (isEnd) {
                        [aiCell finishAppendContent];
                    }
                });
            }
        } onClose:^(EventSourceEvent * _Nonnull event) {
            @strongify(eventSource);
            [self.eventSourceList removeObject:eventSource];
            dispatch_async(dispatch_get_main_queue(), ^{
                [aiCell finishAppendThought];
                [aiCell finishAppendContent];
            });
            if (aiMessage.content.length > 0) {
                NSLog(@"[jy] requestCozeModel onResult, modelName: %@, result: %@", modelName, aiMessage.content);
                resolve(aiMessage);
            } else {
                NSError *error = NSError.emptyResultError;
                NSLog(@"[jy] requestCozeModel onError, modelName: %@, error: %@", modelName, error);
                resolve(error);
            }
        } onError:^(EventSourceEvent * _Nonnull event) {
            @strongify(eventSource);
            [self.eventSourceList removeObject:eventSource];
            dispatch_async(dispatch_get_main_queue(), ^{
                [aiCell finishAppendThought];
                [aiCell finishAppendContent];
            });
            NSLog(@"[jy] requestCozeModel onError, modelName: %@, error: %@", modelName, event.error);
            resolve(event.error);
        }];
    }];
}

@end
