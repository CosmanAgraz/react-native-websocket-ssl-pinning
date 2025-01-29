//
//  RCTWebSocketSsLPinning.m
//  VCallPlus
//
//  Created by Akhil Thomas on 2024-12-31.
//
// IMPORTANT: make sure to invoke the callback function on the RCT_EXPORT_METHODs
// failing to invoke the callback will result in memory leaks and may crash the app.

#import <React/RCTLog.h>
#import "RCTWebSocketSslPinning.h"

@implementation RCTWebSocketSslPinning

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(fetch:(NSString *)urlString withOptions:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback)
{
  RCTLogInfo(@"iOS: Connecting to WebSocket at %@ with options: %@", urlString, options.description);
    
  _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                           delegate:self
                                      delegateQueue:[NSOperationQueue mainQueue]];
  
  _webSocketTask = [_session webSocketTaskWithURL:[NSURL URLWithString:urlString]];
  
  [_webSocketTask resume];
    
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
    
    //send message
  callback(@[[NSNull null], @"Message sent successfully."]);
  } else {
      RCTLogError(@"iOS: Failed to send message: WebSocket is not connected.");
      callback(@[@"Failed to send message.", [NSNull null]]);
  }
}

RCT_EXPORT_METHOD(terminateWebSocket:(NSString *)reason callback:(RCTResponseSenderBlock)callback)
{
  [_webSocketTask cancel];
  callback(@[[NSNull null], @"WebSocket connection terminated."]);
}

RCT_EXPORT_METHOD(closeWebSocket:(NSString *)reason callback:(RCTResponseSenderBlock)callback)
{
    if (_webSocketTask.state == NSURLSessionTaskStateRunning) {
        // close connection with reason
      [_webSocketTask cancel];
      callback(@[[NSNull null], @"WebSocket connection closed."]);
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
  NSLog(@"iOS: Web Socket is open");
  [self startReceivingMessages];
  [self sendEventToJavaScript:@"onOpen" withParams:@{@"code": @"101", @"message": @"ok"}];
};

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(nullable NSData *)reason{
  NSLog(@"iOS: Web socket is closed");
  [self sendEventToJavaScript:@"onClosed" withParams:@{@"code": @"101", @"message": @"ok"}];
};

- (void)startReceivingMessages {
  [_webSocketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
    if (error) {
      NSLog(@"iOS: Error receiving message: %@", error.localizedDescription);
      return;
    }
    
    if (message.type == NSURLSessionWebSocketMessageTypeString) {
      [self sendEventToJavaScript:@"onMessage" withParams:@{@"payload": message.string}];
    } else if (message.type == NSURLSessionWebSocketMessageTypeData) {
      NSLog(@"iOS: Received binary message: %@", message.data);
    } else {
      NSLog(@"iOS: Received unknown message type.");
    }
    
    [self startReceivingMessages];
  }];
};

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
  // NSLog(@"iOS: Challenge Protection Space: %@ (%@)", challenge.protectionSpace.host, challenge.protectionSpace.authenticationMethod);
  // NSLog(@"iOS: Challenge Previous Failure Count: %ld", (long)challenge.previousFailureCount);

  // Check the authentication method
  if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
      SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
      if (serverTrust) {
          NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
          // NSLog(@"iOS: Server trust credential created: %@", credential);
          
          completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
          // NSLog(@"iOS: CompletionHandler called with disposition: UseCredential.");
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

@end
