package com.websocketsslpinning;


public interface OnEventResponseListener {
  /**
   * Invoked when a new message is received from the websocket with {event, data} structure
   *
   * @param event message event
   * @param data hopefully legible information
   */
  void onMessage(String event, String data);
}
