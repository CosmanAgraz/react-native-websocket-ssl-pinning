# react-native-websocket-ssl-pinning

Creates a secure WebSocket connection using ssl-pinning technique.

## Installation

```
yarn add react-native-websocket-ssl-pinning
```

## API

### Methods

#### fetch(string: url, any: obj)
Attempts to open the WSS connection to specified endpoint. Certs must be `.cer` format

Example:
```
      fetch(`wss://${domain}/`, {
        method: 'GET',
        sslPinning: {
          certs: ['rootCA_public'],
        },
      });
```

#### sendWebSocketMessage(string: message)
Sends a messaage. Must be called after *fetch*.


#### terminateWebSocket(void)
Aggressively stops the web socket connection and instance


#### closeWebSocket(string: reason)
Closes the web socket.

### Members

#### NativeEventEmitter eventEmitter
Requires the following listeners:
'onOpen'
'onClosed'
'onFailure'
'onMessage'

Each listener requires a callback function.

Example:
```
openListener = eventEmitter.addListener('onOpen', socketOpen);
closeListener = eventEmitter.addListener('onClosed', socketClosed);
messageListener = eventEmitter.addListener('onMessage', socketMsg);
failureListener = eventEmitter.addListener('onFailure', socketFailed);

// when web socket is terminated, clean up the listeners
openListener.remove();
closeListener.remove();
messageListener.remove();
failureListener.remove();
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
