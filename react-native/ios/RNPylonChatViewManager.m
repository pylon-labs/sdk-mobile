//
//  RNPylonChatViewManager.m
//  RNPylonChat
//
//  React Native bridge to PylonChat iOS SDK
//

#import <React/RCTViewManager.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNPylonChatViewManager, RCTViewManager)

// Config props
RCT_EXPORT_VIEW_PROPERTY(appId, NSString)
RCT_EXPORT_VIEW_PROPERTY(widgetBaseUrl, NSString)
RCT_EXPORT_VIEW_PROPERTY(widgetScriptUrl, NSString)
RCT_EXPORT_VIEW_PROPERTY(enableLogging, BOOL)
RCT_EXPORT_VIEW_PROPERTY(debugMode, BOOL)
RCT_EXPORT_VIEW_PROPERTY(primaryColor, NSString)

// User props
RCT_EXPORT_VIEW_PROPERTY(userEmail, NSString)
RCT_EXPORT_VIEW_PROPERTY(userName, NSString)
RCT_EXPORT_VIEW_PROPERTY(userAvatarUrl, NSString)
RCT_EXPORT_VIEW_PROPERTY(userEmailHash, NSString)
RCT_EXPORT_VIEW_PROPERTY(userAccountId, NSString)
RCT_EXPORT_VIEW_PROPERTY(userAccountExternalId, NSString)

// Coordinate space adjustment
RCT_EXPORT_VIEW_PROPERTY(topInset, NSNumber)

// Event callbacks (prefixed with rct to avoid Swift naming collision)
RCT_EXPORT_VIEW_PROPERTY(rctOnPylonLoaded, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(rctOnPylonInitialized, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(rctOnPylonReady, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(rctOnChatOpened, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(rctOnChatClosed, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(rctOnUnreadCountChanged, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(rctOnMessageReceived, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(rctOnPylonError, RCTBubblingEventBlock)

// Imperative methods
RCT_EXTERN_METHOD(openChat:(nonnull NSNumber *)reactTag)
RCT_EXTERN_METHOD(closeChat:(nonnull NSNumber *)reactTag)
RCT_EXTERN_METHOD(showChatBubble:(nonnull NSNumber *)reactTag)
RCT_EXTERN_METHOD(hideChatBubble:(nonnull NSNumber *)reactTag)
RCT_EXTERN_METHOD(showNewMessage:(nonnull NSNumber *)reactTag message:(NSString *)message isHtml:(BOOL)isHtml)
RCT_EXTERN_METHOD(setNewIssueCustomFields:(nonnull NSNumber *)reactTag fields:(NSDictionary *)fields)
RCT_EXTERN_METHOD(setTicketFormFields:(nonnull NSNumber *)reactTag fields:(NSDictionary *)fields)
RCT_EXTERN_METHOD(updateEmailHash:(nonnull NSNumber *)reactTag emailHash:(NSString *)emailHash)
RCT_EXTERN_METHOD(showTicketForm:(nonnull NSNumber *)reactTag slug:(NSString *)slug)
RCT_EXTERN_METHOD(showKnowledgeBaseArticle:(nonnull NSNumber *)reactTag articleId:(NSString *)articleId)

@end

