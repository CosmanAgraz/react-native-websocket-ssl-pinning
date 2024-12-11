package com.websocketsslpinning;

public interface OnEventListener {
  /**
   * Invoked when listener receives data
   * @param data from the emitter
   */
  void onMessage(String data);
}
