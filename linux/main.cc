#include <X11/Xlib.h>
#include <clocale>
#include <cstring>
#include <cstdlib>
#include "my_application.h"

int main(int argc, char** argv) {
  // Flutter's localization loader cannot build the first frame under the
  // process-only C locale used by some desktop launchers.
  const char* locale = std::getenv("LC_ALL");
  if (locale != nullptr &&
      (std::strcmp(locale, "C") == 0 || std::strncmp(locale, "C.", 2) == 0)) {
    const char* language = std::getenv("LANG");
    const char* fallback = language != nullptr &&
            std::strcmp(language, "C") != 0 &&
            std::strncmp(language, "C.", 2) != 0 &&
            std::setlocale(LC_ALL, language) != nullptr
        ? language
        : "en_US.UTF-8";
    if (std::setlocale(LC_ALL, fallback) != nullptr) {
      setenv("LC_ALL", fallback, 1);
    }
  }
  XInitThreads();
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
