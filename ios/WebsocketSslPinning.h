
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNWebsocketSslPinningSpec.h"

@interface WebsocketSslPinning : NSObject <NativeWebsocketSslPinningSpec>
#else
#import <React/RCTBridgeModule.h>

@interface WebsocketSslPinning : NSObject <RCTBridgeModule>
#endif

@end
