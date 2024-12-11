package com.websocketsslpinning;

import kotlin.jvm.Throws;
import okhttp3.Response;

public abstract class OnStateChangeListener {
  public void onOpen(Response response) {

  }

  public void onClosed(int code, String reason) {

  }

  public void onFailure(Throwable t) {

  }

  public void onReconnect(int attemptCount, long attemptDelay) {

  }

  /**
   * Invoked when a web socket connection status has changed
   */
  public void onChange(SocketState state) {

  }
}
