#!/bin/bash
set -eu

ACCOUNT=${1:-}
PASSWORD=${2:-}
SERVER=${3:-}

if [ -z "$ACCOUNT" ] || [ -z "$PASSWORD" ] || [ -z "$SERVER" ]; then
    echo "Usage: $0 <account> <password> <server>"
    exit 1
fi

MT5_DIR=/app/mt5
LOGIN_FILE=$MT5_DIR/MT5Login.ini

if [ -f "$MT5_DIR/terminal64.exe" ]; then
    export WINEARCH=win64
    MT5_EXE=terminal64.exe
elif [ -f "$MT5_DIR/terminal.exe" ]; then
    export WINEARCH=win32
    MT5_EXE=terminal.exe
else
    echo "Cannot find MetaTrader executable in $MT5_DIR"
    exit 1
fi

WINE_BIN=wine
if [ "$WINEARCH" = "win64" ] && command -v wine64 > /dev/null 2>&1; then
    WINE_BIN=wine64
fi

if ! command -v "$WINE_BIN" > /dev/null 2>&1; then
    echo "Cannot find Wine launcher: $WINE_BIN"
    exit 1
fi

# 1. Tạo file cấu hình tự động login
cat <<EOF > "$LOGIN_FILE"
[Common]
Login=$ACCOUNT
Password=$PASSWORD
Server=$SERVER
KeepPrivate=0
NewsEnable=0

[Experts]
AllowLiveTrading=0
AllowDllImport=0
Enabled=1
Account=0
Profile=0

[StartUp]
Expert=Advisors\lumir-mt5
Symbol=XAUUSD
EOF

# 1. Dọn dẹp các file lock cũ nếu có (Tránh lỗi "Server is already active")
rm -f /tmp/.X99-lock
rm -rf /tmp/.X11-unix/X99

# 2. Khởi động Xvfb và kiểm tra xem nó đã chạy thực sự chưa
Xvfb :99 -screen 0 1280x1024x24 &
sleep 2

# Kiểm tra nếu Xvfb không chạy được thì thoát sớm để debug
if ! pgrep -x "Xvfb" > /dev/null; then
    echo "LỖI: Xvfb không khởi động được!"
    exit 1
fi

# 2. Cấu hình Wine để chạy ổn định hơn
export WINEPREFIX=/home/wine/.wine
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree,mshtml=;secur32=n,b"
export DISPLAY=:99

# Recreate the prefix only when its architecture does not match the bundled terminal.
if [ -f "$WINEPREFIX/system.reg" ]; then
    if [ "$WINEARCH" = "win64" ] && [ ! -d "$WINEPREFIX/drive_c/windows/syswow64" ]; then
        rm -rf "$WINEPREFIX"
    fi

    if [ "$WINEARCH" = "win32" ] && [ -d "$WINEPREFIX/drive_c/windows/syswow64" ]; then
        rm -rf "$WINEPREFIX"
    fi
fi

# Initialise Wine prefix and wait for wineserver to finish
wineboot -u
while pgrep wineserver > /dev/null; do sleep 1; done

# Apply DLL overrides via registry
wine reg add 'HKCU\Software\Wine\DllOverrides' /v mscoree /t REG_SZ /d '' /f
wine reg add 'HKCU\Software\Wine\DllOverrides' /v mshtml   /t REG_SZ /d '' /f
wine reg add 'HKCU\Software\Wine\DllOverrides' /v secur32  /t REG_SZ /d 'n,b' /f
while pgrep wineserver > /dev/null; do sleep 1; done

echo "Cấu hình Wine đã sẵn sàng."

echo "Login MT5 với tài khoản: $ACCOUNT, Server: $SERVER"

echo "Đang khởi động MT5..."

# 3. Chạy MT5 
# Chuyển vào thư mục chứa terminal để tránh lỗi đường dẫn tương đối nội bộ của Wine
cd "$MT5_DIR"

# QUAN TRỌNG: Phải có tiền tố /config: và đường dẫn Windows để MT5 luôn nạp đúng file login.
"$WINE_BIN" "$MT5_EXE" /portable '/config:Z:\app\mt5\MT5Login.ini' &
MT5_PID=$!

echo "MT5 đang chạy ngầm..."
wait "$MT5_PID"