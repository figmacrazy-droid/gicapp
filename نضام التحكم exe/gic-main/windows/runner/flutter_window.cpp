#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Setup window resizing method channel
  window_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "gic/window",
      &flutter::StandardMethodCodec::GetInstance());

  window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        HWND hwnd = this->GetHandle();
        if (call.method_name().compare("maximize") == 0) {
          if (hwnd) {
            ::ShowWindow(hwnd, SW_MAXIMIZE);
            ::SetWindowTextW(hwnd, L"كلية الغد الدولية - لوحة تحكم النظام الإداري");
          }
          result->Success();
        } else if (call.method_name().compare("expand") == 0) {
          if (hwnd) {
            int screen_width = ::GetSystemMetrics(SM_CXSCREEN);
            int screen_height = ::GetSystemMetrics(SM_CYSCREEN);
            int window_width = 1366;
            int window_height = 820;
            int origin_x = (screen_width - window_width) / 2;
            int origin_y = (screen_height - window_height) / 2;
            if (origin_x < 0) origin_x = 10;
            if (origin_y < 0) origin_y = 10;
            ::ShowWindow(hwnd, SW_RESTORE);
            ::SetWindowPos(hwnd, HWND_TOP, origin_x, origin_y, window_width, window_height, SWP_SHOWWINDOW);
            ::SetWindowTextW(hwnd, L"كلية الغد الدولية - لوحة تحكم النظام الإداري");
          }
          result->Success();
        } else if (call.method_name().compare("shrinkToLogin") == 0) {
          if (hwnd) {
            ::ShowWindow(hwnd, SW_RESTORE);
            int screen_width = ::GetSystemMetrics(SM_CXSCREEN);
            int screen_height = ::GetSystemMetrics(SM_CYSCREEN);
            int window_width = 450;
            int window_height = 600;
            int origin_x = (screen_width - window_width) / 2;
            int origin_y = (screen_height - window_height) / 2;
            if (origin_x < 0) origin_x = 10;
            if (origin_y < 0) origin_y = 10;
            ::SetWindowPos(hwnd, HWND_TOP, origin_x, origin_y, window_width, window_height, SWP_SHOWWINDOW);
            ::SetWindowTextW(hwnd, L"كلية الغد الدولية - تسجيل الدخول");
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  window_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
