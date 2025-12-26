#include <gtk/gtk.h>
#include <webkit/webkit.h>

typedef struct {
  guint width;
  guint height;
  guint bytes_per_pixel;
  gchar *comment;
  char *pixel_data;
} Picture;

typedef struct {
  const Picture *pic;
  const char *url;
  WebKitWebView *webview;
} ButtonData;

extern const Picture grafana;
extern const Picture meteo;
extern const Picture buildbot;
extern const Picture gallery;
extern const Picture status;

ButtonData buttons[] = {
  {
    &grafana,
    "http://debiand843e635fb7:3000/d/574d7f7f-bc36-4dce-abf0-c2ddb74a452b/power?orgId=1&from=now-30m&to=now&timezone=browser&refresh=5s&kiosk",
    NULL,
  },
  {
    &meteo,
    "https://www.meteosuisse.admin.ch/previsions-locales/le-landeron/2525.html#forecast-tab=weekly-overview",
    NULL,
  },
  {
    &buildbot,
    "http://debiand843e635fb7:8010/",
    NULL,
  },
  {
    &gallery,
    "http://debiand843e635fb7:8080/search/%7B%22type%22:102,%22text%22:%22GLOBE.TROTTEUSE%22%7D?play=true&autoUpdateInterval=300&loopSlideshow=true&captionAlwaysOn=true&slideshowSpeed=5",
    NULL,
  },
  {
    &status,
    "  http://debiand843e635fb7:3000/d/rYdddlPWk/node-exporter-full?orgId=1&from=now-24h&to=now&timezone=browser&var-DS_PROMETHEUS=feyz1hxdjkbuob&var-job=router&var-nodename=debiand843e635fb7&var-node=debiand843e635fb7.home:9100&var-diskdevices=%5Ba-z%5D%2B%7Cnvme%5B0-9%5D%2Bn%5B0-9%5D%2B%7Cmmcblk%5B0-9%5D%2B&refresh=1m&kiosk",
    NULL,
  },
};

struct RestartData {
  unsigned tries;
  unsigned max_tries;
  unsigned try_window_ms;
  unsigned tries_timeout_id;
};

static gboolean reset_recovery_tries(struct RestartData *restart) {
  restart->tries = 0;
  restart->tries_timeout_id = 0;
  return G_SOURCE_REMOVE;
}

static gboolean
on_web_process_terminated_restart(WebKitWebView *web_view,
                                  WebKitWebProcessTerminationReason reason,
                                  struct RestartData *restart) {
  if (restart->tries_timeout_id) {
    g_source_remove(restart->tries_timeout_id);
    restart->tries_timeout_id = 0;
  }

  if (++restart->tries >= restart->max_tries) {
    g_critical("Renderer process terminated and failed to recover");
    return TRUE;
  }

  g_warning("Renderer process terminated, restarting (attempt %u/%u).",
            restart->tries, restart->max_tries);
  webkit_web_view_reload(web_view);

  restart->tries_timeout_id = g_timeout_add(
      restart->try_window_ms, (GSourceFunc)reset_recovery_tries, restart);
  return TRUE;
}

void on_button(GtkButton *btn, gpointer user_data) {
  ButtonData *data = (ButtonData *)user_data;
  webkit_web_view_load_uri(data->webview, data->url);
}

static void activate(GtkApplication *app, gpointer user_data) {
  // Window Setup
  GtkWidget *window = gtk_application_window_new(app);
  gtk_window_set_default_size(GTK_WINDOW(window), 1280, 1024);
  gtk_window_set_title(GTK_WINDOW(window), "PaGBrowser");

  // Dark Theme
  GtkSettings *gtk_settings = gtk_settings_get_default();
  g_object_set(gtk_settings, "gtk-application-prefer-dark-theme", TRUE, NULL);

  // WebView Setup
  WebKitWebView *webView = WEBKIT_WEB_VIEW(webkit_web_view_new());
  WebKitSettings *settings = webkit_web_view_get_settings(webView);
  webkit_settings_set_allow_modal_dialogs(settings, TRUE);
  // 1. Get the network session from the web view
  WebKitNetworkSession *session = webkit_web_view_get_network_session(webView);

  // 2. Set the TLS errors policy on the session
  webkit_network_session_set_tls_errors_policy(session,
                                               WEBKIT_TLS_ERRORS_POLICY_IGNORE);

  struct RestartData *restart = g_new0(struct RestartData, 1);
  restart->max_tries = 5;
  restart->try_window_ms = 1000;

  g_signal_connect_data(webView, "web-process-terminated",
                        G_CALLBACK(on_web_process_terminated_restart), restart,
                        (GClosureNotify)g_free, 0);

  webkit_web_view_load_uri(webView, buttons[0].url);

  // Layout
  GtkWidget *hbox = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);

  gtk_box_append(GTK_BOX(hbox), vbox);
  gtk_box_append(GTK_BOX(hbox), GTK_WIDGET(webView));
  gtk_widget_set_hexpand(GTK_WIDGET(webView), TRUE);

  gtk_window_set_child(GTK_WINDOW(window), hbox);

  for (int i = 0; i < (sizeof(buttons) / sizeof(ButtonData)); i++) {
    buttons[i].webview = webView;
    GtkWidget *button = gtk_button_new();
    GdkPixbuf *pixbuf = gdk_pixbuf_new_from_data(
        (const guchar *)buttons[i].pic->pixel_data, GDK_COLORSPACE_RGB,
        (buttons[i].pic->bytes_per_pixel == 4), 8, buttons[i].pic->width,
        buttons[i].pic->height,
        buttons[i].pic->width * buttons[i].pic->bytes_per_pixel, NULL, NULL);
    int target_size = 128;
    GdkPixbuf *scaled_pixbuf = gdk_pixbuf_scale_simple(
        pixbuf, target_size, target_size, GDK_INTERP_HYPER);
    GdkTexture *texture = gdk_texture_new_for_pixbuf(scaled_pixbuf);
    GtkWidget *image = gtk_image_new_from_paintable(GDK_PAINTABLE(texture));
    gtk_image_set_pixel_size(GTK_IMAGE(image), target_size);
    gtk_button_set_child(GTK_BUTTON(button), image);
    g_signal_connect(button, "clicked", G_CALLBACK(on_button), &buttons[i]);
    gtk_box_append(GTK_BOX(vbox), button);
    g_object_unref(pixbuf);
    g_object_unref(scaled_pixbuf);
    g_object_unref(texture);
  }
  gtk_window_present(GTK_WINDOW(window));
}

int main(int argc, char *argv[]) {
  GtkApplication *app = gtk_application_new("org.webkitgtk.PaGBrowser",
                                            G_APPLICATION_DEFAULT_FLAGS);
  g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
  int status = g_application_run(G_APPLICATION(app), argc, argv);
  g_object_unref(app);
  return status;
}
