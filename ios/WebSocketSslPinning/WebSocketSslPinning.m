//
//  RCTWebSocketSsLPinning.m
// react-native-websocket-ssl-pinning
//
//  Created by Sergio Cosman Agraz on 2024-12-31.
//

// NOTE: this file is not used, but this is where the development of the react-native-websocket-ssl-pinning library happens.
// Making changes to this file will not change the apps behavior unless the import line is changed in chWebSocket-RN.js
// from `import * as wss from 'react-native-websocket-ssl-pinning';` -> `import * as wss from './index';` (SCA)

#import <React/RCTLog.h>
#import "RCTWebSocketSslPinning.h"

int MAX_COLLISION = 10;

@implementation RCTWebSocketSslPinning

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(fetch:(NSString *)urlString withOptions:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback)
{
  RCTLogInfo(@"iOS: Connecting to WebSocket at %@ with options: %@", urlString, options.description);
  
  _reconnectAttempts = 0;
  _webSocketUrlString = urlString;
  _webSocketOptions = options;
  
  [self connectWebSocket];
    
  callback(@[[NSNull null], @"WebSocket fetch initiated."]);
}

RCT_EXPORT_METHOD(sendWebSocketMessage:(NSString *)payload callback:(RCTResponseSenderBlock)callback)
{
  if (_webSocketTask.state == NSURLSessionTaskStateRunning) {
    NSURLSessionWebSocketMessage *message = [[NSURLSessionWebSocketMessage alloc] initWithString:payload];

    // Send the message
    [_webSocketTask sendMessage:message completionHandler:^(NSError * _Nullable error) {
      if (error) {
        callback(@[[@"Failed to send message: " stringByAppendingString:error.localizedDescription] , [NSNull null]]);
      }
    }];
  } else {
      callback(@[@"Failed to send message.", [NSNull null]]);
  }
}

RCT_EXPORT_METHOD(terminateWebSocket:(NSString *)reason callback:(RCTResponseSenderBlock)callback)
{
  [_webSocketTask cancel];
  [_session invalidateAndCancel];
  [_session flushWithCompletionHandler:^{
      NSLog(@"DEBUG: Flush completed!");
  }];
  
  callback(@[[NSNull null], @"WebSocket connection terminated."]);
}

RCT_EXPORT_METHOD(closeWebSocket:(NSString *)reason callback:(RCTResponseSenderBlock)callback)
{
    if (_webSocketTask.state == NSURLSessionTaskStateRunning) {
      [_webSocketTask cancel];
      [_session invalidateAndCancel];
      
      callback(@[[NSNull null], @"WebSocket successfully closed."]);
    } else {
      callback(@[@"WebSocket is not connected.", [NSNull null]]);
    }
}

/* Events we are allowed to send the Javascript execution context.
 */
- (NSArray<NSString *> *)supportedEvents {
    return @[@"onOpen", @"onClosed", @"onMessage", @"onFailure"];
}

/* Sends information to Javascript execution context.
 */
- (void)sendEventToJavaScript:(NSString *)eventName withParams:(id)params {
    if (self.bridge && _hasListeners) {
        [self sendEventWithName:eventName body:params];
    }
}

- (void)startObserving {
    _hasListeners = YES;
}

- (void)stopObserving {
    _hasListeners = NO;
}

// Web Socket stuff
- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(nullable NSString *) protocol {
  NSLog(@"DEBUG: Web Socket is open");
  _reconnectAttempts = 0;
  [self startReceivingMessages];
  [self sendEventToJavaScript:@"onOpen" withParams:@{@"code": @"101", @"message": @"ok"}];
};

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(nullable NSData *)reason{
  NSLog(@"DEBUG: Web Socket is clsoed");
};

- (void)startReceivingMessages {
  [_webSocketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
    if (error) {
      NSLog(@"DEBUG: Error receiving message: %@", error.localizedDescription);
      return;
    }
    
    if (message.type == NSURLSessionWebSocketMessageTypeString) {
      [self sendEventToJavaScript:@"onMessage" withParams:@{@"payload": message.string}];
    } else if (message.type == NSURLSessionWebSocketMessageTypeData) {
      NSLog(@"DEBUG: Received binary message: %@", message.data);
    } else {
      NSLog(@"DEBUG: Received unknown message type.");
    }
    
    [self startReceivingMessages];
  }];
};

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *) task
didCompleteWithError:(nullable NSError *)error {
  if (error) {
      RCTLogInfo(@"iOS: WebSocket task failed with error: %@", error.localizedDescription);
      RCTLogInfo(@"Error Code: %ld", (long)error.code);
      RCTLogInfo(@"Error Domain: %@", error.domain);
      RCTLogInfo(@"Error UserInfo: %@", error.userInfo);
    
    if ((long)error.code == -999) {
      RCTLogInfo(@"iOS: WebSocket task failed with error: %@", error.localizedDescription);
      return;
    } else {
      [self sendEventToJavaScript:@"onFailure"
                       withParams:@{@"code": [NSString stringWithFormat:@"%ld", (long)error.code], @"message": error.localizedDescription}];
      
      [_session invalidateAndCancel];
      [_session flushWithCompletionHandler:^{
          NSLog(@"DEBUG: Flush completed!");
      }];
      
      [self reconnect];
    }
  } else {
      RCTLogInfo(@"iOS: WebSocket task completed successfully.");
  }
}

- (void)reconnect {
  int collision = _reconnectAttempts > MAX_COLLISION ? MAX_COLLISION : _reconnectAttempts;
  int64_t delayTime = round((pow(2, collision) - 1) / 2) * NSEC_PER_SEC;
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayTime), dispatch_get_main_queue(), ^{
      [self connectWebSocket];
  });
}
  

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
  NSLog(@"iOS: Handshake: Received challenge.");
  
  // Log challenge details
  NSLog(@"iOS: Challenge Protection Space: %@ (%@)", challenge.protectionSpace.host, challenge.protectionSpace.authenticationMethod);
  NSLog(@"iOS: Challenge Previous Failure Count: %ld", (long)challenge.previousFailureCount);

  // Check the authentication method
  if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
      NSLog(@"iOS: Challenge requires server trust validation.");
      
      // Retrieve server trust
      SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
      if (serverTrust) {
          // Validate the server trust (optional: perform custom validation here)
          NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
          NSLog(@"iOS: Server trust credential created: %@", credential);
          
          // Use the credential to continue
          completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
          NSLog(@"iOS: CompletionHandler called with disposition: UseCredential.");
      } else {
          NSLog(@"iOS: Server trust is nil. Cancelling authentication challenge.");
          completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
      }
  } else {
      NSLog(@"iOS: Challenge authentication method is unsupported: %@", challenge.protectionSpace.authenticationMethod);
      
      // Default handling for unsupported challenges
      completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
      NSLog(@"iOS: CompletionHandler called with disposition: PerformDefaultHandling.");
  }
};

-(void)connectWebSocket {
  if (_reconnectAttempts >= 10) {
    [self sendEventToJavaScript:@"onFailure" withParams:@{@"code": @"1006", @"message": @"Maximum reconnect tries reach"}];
    return;
  }
  _reconnectAttempts += 1;
  NSLog(@"iOS: Attempting WebSocket connection (Attempt %ld)", (long)self.reconnectAttempts);
  
  _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                          delegate:self
                                    delegateQueue:[NSOperationQueue mainQueue]];
  
  _webSocketTask = [_session webSocketTaskWithURL:[NSURL URLWithString:_webSocketUrlString]];
  
  [_webSocketTask resume];
};

@end
