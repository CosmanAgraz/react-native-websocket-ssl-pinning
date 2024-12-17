package com.websocketsslpinning;

import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.modules.network.ForwardingCookieHandler;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import okhttp3.Cookie;
import okhttp3.CookieJar;
import okhttp3.Headers;
import okhttp3.HttpUrl;
import okhttp3.Response;

import com.google.gson.Gson;

/**
 * TODO use proper RFC6455 spec on websocket closures
 * 7.4.1.  Defined Status Codes

   Endpoints MAY use the following pre-defined status codes when sending
   a Close frame.

   1000

      1000 indicates a normal closure, meaning that the purpose for
      which the connection was established has been fulfilled.

   1001

      1001 indicates that an endpoint is "going away", such as a server
      going down or a browser having navigated away from a page.

   1002

      1002 indicates that an endpoint is terminating the connection due
      to a protocol error.

   1003

      1003 indicates that an endpoint is terminating the connection
      because it has received a type of data it cannot accept (e.g., an
      endpoint that understands only text data MAY send this if it
      receives a binary message).
 */

public class WebSocketSslPinningModule extends ReactContextBaseJavaModule {


    private static final String OPT_SSL_PINNING_KEY = "sslPinning";
    private static final String DISABLE_ALL_SECURITY = "disableAllSecurity";
    private static final String RESPONSE_TYPE = "responseType";
    private static final String KEY_NOT_ADDED_ERROR = "sslPinning key was not added";

    private final ReactApplicationContext reactContext;
    private final HashMap<String, List<Cookie>> cookieStore;
    private CookieJar cookieJar = null;
    private ForwardingCookieHandler cookieHandler;

    public WebSocketSslPinningModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        cookieStore = new HashMap<>();
        cookieHandler = new ForwardingCookieHandler(reactContext);
        cookieJar = new CookieJar() {

            @Override
            public synchronized void saveFromResponse(HttpUrl url, List<Cookie> unmodifiableCookieList) {
                for (Cookie cookie : unmodifiableCookieList) {
                    setCookie(url, cookie);
                }
            }

            @Override
            public synchronized List<Cookie> loadForRequest(HttpUrl url) {
                List<Cookie> cookies = cookieStore.get(url.host());
                return cookies != null ? cookies : new ArrayList<Cookie>();
            }

            public void setCookie(HttpUrl url, Cookie cookie) {

                final String host = url.host();

                List<Cookie> cookieListForUrl = cookieStore.get(host);
                if (cookieListForUrl == null) {
                    cookieListForUrl = new ArrayList<Cookie>();
                    cookieStore.put(host, cookieListForUrl);
                }
                try {
                    putCookie(url, cookieListForUrl, cookie);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            private void putCookie(HttpUrl url, List<Cookie> storedCookieList, Cookie newCookie) throws URISyntaxException, IOException {

                Cookie oldCookie = null;
                Map<String, List<String>> cookieMap = new HashMap<>();

                for (Cookie storedCookie : storedCookieList) {

                    // create key for comparison
                    final String oldCookieKey = storedCookie.name() + storedCookie.path();
                    final String newCookieKey = newCookie.name() + newCookie.path();

                    if (oldCookieKey.equals(newCookieKey)) {
                        oldCookie = storedCookie;
                        break;
                    }
                }
                if (oldCookie != null) {
                    storedCookieList.remove(oldCookie);
                }
                storedCookieList.add(newCookie);

                cookieMap.put("Set-cookie", Collections.singletonList(newCookie.toString()));
                cookieHandler.put(url.uri(), cookieMap);
            }
        };

    }

    public static String getDomainName(String url) throws URISyntaxException {
        URI uri = new URI(url);
        String domain = uri.getHost();
        return domain.startsWith("www.") ? domain.substring(4) : domain;
    }


    @ReactMethod
    public void getCookies(String domain, final Promise promise) {
        try {
            WritableMap map = new WritableNativeMap();

            List<Cookie> cookies = cookieStore.get(getDomainName(domain));

            if (cookies != null) {
                for (Cookie cookie : cookies) {
                    map.putString(cookie.name(), cookie.value());
                }
            }

            promise.resolve(map);
        } catch (Exception e) {
            promise.reject(e);
        }
    }


    @ReactMethod
    public void removeCookieByName(String cookieName, final Promise promise) {
        List<Cookie> cookies = null;

        for (String domain : cookieStore.keySet()) {
            List<Cookie> newCookiesList = new ArrayList<>();

            cookies = cookieStore.get(domain);
            if (cookies != null) {
                for (Cookie cookie : cookies) {
                    if (!cookie.name().equals(cookieName)) {
                        newCookiesList.add(cookie);
                    }
                }
                cookieStore.put(domain, newCookiesList);
            }
        }

        promise.resolve(null);
    }

    /**
     * Send this to Javascript
     * @param eventName
     * @param params
     */
    private void sendEvent(String eventName, @Nullable String params) {
        this.reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params);
    }

    /**
     * Javascript message to JSON
     * @param message
     * @return
     */
    private String convertReadableMapToJson(ReadableMap readableMap) {
        Gson gson = new Gson();
        return gson.toJson(Arguments.toBundle(readableMap));
    }

  /**
   * Send this over the network
   * @param message JSON message
   * @param callback response send to Javascript
   */
  @ReactMethod
    public void sendWebSocketMessage(String message, final Callback callback) {
        try {
            boolean sent = Socket.getInstance().send("test", message);
            if (sent) {
                callback.invoke(null, "Message sent successfully");
            } else {
                callback.invoke("SEND_ERROR", "Failed to send message");
            }
        } catch (Exception e) {
            callback.invoke("SEND_ERROR", "Failed to send message: " + e.getMessage());
        }
    }

    @ReactMethod
    public void fetch(String hostname, final ReadableMap options, final Callback callback) {
        final WritableMap response = Arguments.createMap();

        if (hostname.startsWith("wss://") || hostname.startsWith("ws://")) {
            if (options.hasKey(OPT_SSL_PINNING_KEY)) {
                if (options.getMap(OPT_SSL_PINNING_KEY).hasKey("certs")) {
                    ReadableArray certs = options.getMap(OPT_SSL_PINNING_KEY).getArray("certs");
                    if (certs != null && certs.size() == 0) {
                        throw new RuntimeException("certs array is empty");
                    }

                    Socket mSocket = SocketBuilder.with(hostname).setCertificate(certs).setPingInterval(10, TimeUnit.SECONDS)
                      .setConnectTimeout(10, TimeUnit.SECONDS)
                      .setReadTimeout(10, TimeUnit.SECONDS)
                      .setWriteTimeout(10, TimeUnit.SECONDS).build();


                    mSocket.addOnChangeStateListener(new OnStateChangeListener() {
                      // Socket connection events
                      @Override
                      public void onChange(SocketState status) {
                        switch (status) {
                          case OPEN:
                            Log.d("WebSocketSsLPinning", "Socket is ONLINE: " + status);
                            break;
                          case CLOSING: case CLOSED: case RECONNECTING:
                          case RECONNECT_ATTEMPT: case CONNECT_ERROR:
                            Log.d("WebSocketSsLPinning", "Socket state changed to: " + status);
                            break;
                        }
                      }

                      @Override
                      public void onFailure(Throwable t) {
                        sendEvent("onFailure", t.getMessage());
                      }

                      @Override
                      public void onOpen(Response response) {
                          sendEvent("onOpen", response.message());
                      }

                      @Override
                      public void onClosed(int code, String reason) {
                        Log.d("WebSocketSsLPinning", "Socket was closed.");
                      }
                    }).addOnEventResponseListener("wsapi", new OnEventResponseListener() {
                        @Override
                        public void onMessage(String event, String data) {
                            sendEvent("onMessage", data);
                        }
                    });

                    mSocket.connect();
                } else {
                    Log.e("WebSocketSsLPinning", "key certs was not found.");
                    return;
                }
            } else {
                Log.e("WebSocketSsLPinning", KEY_NOT_ADDED_ERROR);
                return;
            }
        }
        return;
    }

    @ReactMethod
    public void closeWebSocket(String reason, Callback callback) {
        Socket.getInstance().close();
        callback.invoke(null, "WebSocket successfully closed");
    }

    @ReactMethod
    public void terminateWebSocket(String reason, Callback callback) {
        Socket.getInstance().terminate();
        callback.invoke(null, "WebSocket successfully terminated");
    }


    @NonNull
    private WritableMap buildResponseHeaders(Response okHttpResponse) {
        Headers responseHeaders = okHttpResponse.headers();
        Set<String> headerNames = responseHeaders.names();
        WritableMap headers = Arguments.createMap();
        for (String header : headerNames) {
            headers.putString(header, responseHeaders.get(header));
        }
        return headers;
    }

    @Override
    public String getName() {
        return "WebSocketSslPinning";
    }

    // Required for rn built in EventEmitter Calls.
    @ReactMethod
    public void addListener(String eventName) {
        // Suppresses warnings
    }

    @ReactMethod
    public void removeListeners(Integer count) {
        // Suppresses warnings
    }

}
