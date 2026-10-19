#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

static std::wstring Utf8ToWide(const std::string& utf8_str) {
  if (utf8_str.empty()) return std::wstring();
  int size = ::MultiByteToWideChar(CP_UTF8, 0, utf8_str.c_str(), -1, NULL, 0);
  std::wstring wide(size, 0);
  ::MultiByteToWideChar(CP_UTF8, 0, utf8_str.c_str(), -1, &wide[0], size);
  if (!wide.empty() && wide.back() == L'\0') wide.pop_back();
  return wide;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  int screen_width = ::GetSystemMetrics(SM_CXSCREEN);
  int screen_height = ::GetSystemMetrics(SM_CYSCREEN);
  int window_width = 450;
  int window_height = 600;
  int origin_x = (screen_width - window_width) / 2;
  int origin_y = (screen_height - window_height) / 2;
  if (origin_x < 0) origin_x = 10;
  if (origin_y < 0) origin_y = 10;

  Win32Window::Point origin(origin_x, origin_y);
  Win32Window::Size size(window_width, window_height);
  if (!window.Create(Utf8ToWide("كلية الغد الدولية - تسجيل الدخول"), origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
