//
//  RCTWebSocketSsLPinning.h
//  VCallPlus
//
//  Created by Akhil Thomas on 2024-12-31.
//

#ifndef RCTWebSocketSsLPinning_h
#define RCTWebSocketSsLPinning_h

//  RCTCalendarModule.h
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#import "WebSocketStates.h"

@interface RCTWebSocketSslPinning : RCTEventEmitter <RCTBridgeModule, NSURLSessionWebSocketDelegate>

@property bool connectionDrop;
@property bool hasListeners;

- (void)startObserving;
- (void)stopObserving;

// Socket
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionWebSocketTask *webSocketTask;
@property WebSocketState *state;

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask
    didOpenWithProtocol:(NSString *)protocol;

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closSeCode reason:(NSData *)reason;

- (void)startReceivingMessages;

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;

// React Native
-(void)sendEventToJavaScript:(NSString *)eventName withParams:(id)params;
@end

#endif /* RCTWebSocketSsLPinning_h */
