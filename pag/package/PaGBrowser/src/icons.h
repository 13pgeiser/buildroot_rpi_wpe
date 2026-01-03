#ifndef _ICONS_
#define _ICONS_

#include <gtk/gtk.h>

typedef struct {
  guint  	 width;
  guint  	 height;
  guint  	 bytes_per_pixel;
  gchar  	*comment;
  char 	  *pixel_data;
} Picture;

extern const Picture grafana;
extern const Picture meteo;
extern const Picture buildbot;
extern const Picture gallery;
extern const Picture status;
extern const Picture electricity;
extern const Picture rts;

#endif // _ICONS_
