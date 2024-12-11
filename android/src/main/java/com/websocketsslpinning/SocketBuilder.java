package com.websocketsslpinning;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;

import androidx.annotation.NonNull;

import java.io.BufferedInputStream;
import java.io.InputStream;
import java.security.KeyStore;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.util.Arrays;
import java.util.concurrent.TimeUnit;

import com.facebook.react.bridge.ReadableArray;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.logging.HttpLoggingInterceptor;

public class SocketBuilder {
  private Request.Builder request;

  private static SSLContext sslContext;

  private HttpLoggingInterceptor logging = new HttpLoggingInterceptor().setLevel(HttpLoggingInterceptor.Level.HEADERS);

  private OkHttpClient.Builder httpClient = new OkHttpClient.Builder().addInterceptor(logging);

  private SocketBuilder(Request.Builder request) {
    this.request = request;
  }

  public static SocketBuilder with(@NonNull String url) {
    if (!url.regionMatches(true, 0, "ws:", 0, 3) && !url.regionMatches(true, 0, "wss:", 0, 4))
      throw new IllegalArgumentException("Web Socket url must start with ws or wss");

    return new SocketBuilder(new Request.Builder().url(url));
  }

  public SocketBuilder setCertificate(ReadableArray certs) {
    X509TrustManager manager = initSSLPinning(certs);
    httpClient.sslSocketFactory(sslContext.getSocketFactory(), manager);

    return this;
  }

  public SocketBuilder setPingInterval(long interval, @NonNull TimeUnit unit) {
    httpClient.pingInterval(interval, unit);
    return this;
  }

  public SocketBuilder setConnectTimeout(long interval, @NonNull TimeUnit unit) {
    httpClient.connectTimeout(interval, unit);
    return this;
  }

  public SocketBuilder setReadTimeout(long interval, @NonNull TimeUnit unit) {
    httpClient.readTimeout(interval, unit);
    return this;
  }

  public SocketBuilder setWriteTimeout(long interval, @NonNull TimeUnit unit) {
    httpClient.writeTimeout(interval, unit);
    return this;
  }

  public SocketBuilder addHeader(@NonNull String name, @NonNull String value) {
     request.addHeader(name, value);
     return this;
  }

  private static X509TrustManager initSSLPinning(ReadableArray certs) {
    X509TrustManager trustManager = null;
    try {
      sslContext = SSLContext.getInstance("TLS");
      CertificateFactory cf = CertificateFactory.getInstance("X.509");
      String keyStoreType = KeyStore.getDefaultType();
      KeyStore keyStore = KeyStore.getInstance(keyStoreType);
      keyStore.load(null, null);

      for (int i = 0; i < certs.size(); i++) {
        String filename = certs.getString(i);
        InputStream caInput = new BufferedInputStream(com.websocketsslpinning.utils.OkHttpUtils.class.getClassLoader().getResourceAsStream("assets/" + filename + ".cer"));
        Certificate ca;
        try {
          ca = cf.generateCertificate(caInput);
        } finally {
          caInput.close();
        }

        keyStore.setCertificateEntry(filename, ca);
      }

      String tmfAlgorithm = TrustManagerFactory.getDefaultAlgorithm();
      TrustManagerFactory tmf = TrustManagerFactory.getInstance(tmfAlgorithm);
      tmf.init(keyStore);

      TrustManager[] trustManagers = tmf.getTrustManagers();
      if (trustManagers.length != 1 || !(trustManagers[0] instanceof X509TrustManager)) {
        throw new IllegalStateException("Unexpected default trust managers:" + Arrays.toString(trustManagers));
      }
      trustManager = (X509TrustManager) trustManagers[0];

      sslContext.init(null, new TrustManager[]{trustManager}, null);

    } catch (Exception e) {
      e.printStackTrace();
    }
    return trustManager;
  }

  public Socket build() {
    return Socket.init(httpClient, request.build());
  }

}
