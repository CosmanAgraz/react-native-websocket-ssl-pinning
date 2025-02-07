//
//  SRWebSocketDelegate.h
//  react-native-websocket-ssl-pinning
//
//  Created by Akhil Thomas on 2025-02-05.
//

#import <Foundation/Foundation.h>
#import "SocketRocket.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SRWebSocketDelegate <NSObject>

@optional

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessageWithString:(NSString *)string;
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessageWithData:(NSData *)data;

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(nullable NSString *)reason wasClean:(BOOL)wasClean;

@end

NS_ASSUME_NONNULL_END
