package com.websocketsslpinning;

public interface OnMessageListener {
  /**
   * Invoked when a new message is received from a web socket
   * @param data Data being received
   */
  void onMessage(String data);
}
