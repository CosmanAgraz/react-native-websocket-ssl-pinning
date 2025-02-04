//
//  RCTWebSocketSsLPinning.h
//  react-native-websocket-ssl-pinning
//
//  Created by Sergio Cosman Agraz on 2024-12-31.
//

// NOTE: this file is not used, but this is where the development of the react-native-websocket-ssl-pinning library happens.
// Making changes to this file will not change the apps behavior unless the import line is changed in chWebSocket-RN.js
// from `import * as wss from 'react-native-websocket-ssl-pinning';` -> `import * as wss from './index';` (SCA)

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
@property (nonatomic, strong) NSString *webSocketUrlString;
@property (nonatomic, strong) NSDictionary *webSocketOptions;
@property (nonatomic, assign) NSInteger reconnectAttempts;

- (void)connectWebSocket;
- (void)reconnect;

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
