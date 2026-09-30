#include "webview_proxy.h"

#include <webkit2/webkit2.h>

static void on_method_call(FlMethodChannel* channel, FlMethodCall* call,
                           gpointer user_data) {
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  if (g_strcmp0(method, "setProxyPort") != 0 || args == nullptr ||
      fl_value_get_type(args) != FL_VALUE_TYPE_INT) {
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_error_response_new(
            "invalid_request", "Expected a local HTTP proxy port", nullptr));
    fl_method_call_respond(call, response, nullptr);
    return;
  }

  const int64_t port = fl_value_get_int(args);
  if (port < 1 || port > 65535) {
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_error_response_new(
            "invalid_port", "Proxy port is out of range", nullptr));
    fl_method_call_respond(call, response, nullptr);
    return;
  }

  gchar* uri = g_strdup_printf("http://127.0.0.1:%ld", static_cast<long>(port));
  WebKitNetworkProxySettings* settings =
      webkit_network_proxy_settings_new(uri, nullptr);
  WebKitWebContext* context = webkit_web_context_get_default();
  WebKitWebsiteDataManager* manager =
      webkit_web_context_get_website_data_manager(context);
  webkit_website_data_manager_set_network_proxy_settings(
      manager, WEBKIT_NETWORK_PROXY_MODE_CUSTOM, settings);
  g_object_set_data_full(G_OBJECT(context), "pirate-wallet-proxy-uri",
                         g_strdup(uri), g_free);
  webkit_network_proxy_settings_free(settings);
  g_free(uri);

  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  fl_method_call_respond(call, response, nullptr);
}

void register_webview_proxy(FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "pirate_wallet/webview_proxy", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, on_method_call, nullptr,
                                            nullptr);
  g_object_unref(channel);
}
