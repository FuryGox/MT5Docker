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
AllowDllImport=1
Enabled=1
Account=0
Profile=0

[StartUp]
Expert=Advisors\lumir-mt5
Symbol=XAUUSD
EOF

# 1. Dọn dẹp các file lock cũ
rm -f /tmp/.X99-lock
rm -rf /tmp/.X11-unix/X99

# 2. Khởi động Xvfb
Xvfb :99 -screen 0 1280x1024x24 &
sleep 2

if ! pgrep -x "Xvfb" > /dev/null; then
    echo "LỖI: Xvfb không khởi động được!"
    exit 1
fi

export WINEPREFIX=/home/wine/.wine
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree,mshtml=;secur32=n,b"
export DISPLAY=:99

if [ -f "$WINEPREFIX/system.reg" ]; then
    if [ "$WINEARCH" = "win64" ] && [ ! -d "$WINEPREFIX/drive_c/windows/syswow64" ]; then
        rm -rf "$WINEPREFIX"
    fi
    if [ "$WINEARCH" = "win32" ] && [ -d "$WINEPREFIX/drive_c/windows/syswow64" ]; then
        rm -rf "$WINEPREFIX"
    fi
fi

wineboot -u
while pgrep wineserver > /dev/null; do sleep 1; done

wine reg add 'HKCU\Software\Wine\DllOverrides' /v mscoree /t REG_SZ /d '' /f
wine reg add 'HKCU\Software\Wine\DllOverrides' /v mshtml   /t REG_SZ /d '' /f
wine reg add 'HKCU\Software\Wine\DllOverrides' /v secur32  /t REG_SZ /d 'n,b' /f
while pgrep wineserver > /dev/null; do sleep 1; done

echo "Cấu hình Wine đã sẵn sàng."
echo "Login MT5 với tài khoản: $ACCOUNT, Server: $SERVER"
echo "Đang khởi động MT5..."

cd "$MT5_DIR"
"$WINE_BIN" "$MT5_EXE" /portable '/config:Z:\app\mt5\MT5Login.ini' &
MT5_PID=$!

# --- NEW AUTOMATION SECTION ---
echo "Waiting for MT5 window to initialize..."
sleep 15 # Wait for the GUI to actually load

# Find the MT5 window and bring it to front
WID=$(xdotool search --limit 1 --all --pid "$MT5_PID" --name "MetaTrader" || echo "")
if [ -n "$WID" ]; then
    xdotool windowactivate --sync "$WID"
fi

echo "Executing key sequence..."
# sequence: esc -> ctrl+o -> 3x ctrl+tab -> 7x tab -> enter -> URL -> enter
xdotool key Escape
sleep 1
xdotool key ctrl+o
sleep 2
xdotool key ctrl+Tab 
xdotool key ctrl+Tab
xdotool key ctrl+Tab
sleep 1
xdotool key Tab Tab Tab Tab Tab Tab Tab
sleep 1
xdotool key Return
xdotool key Down
xdotool key Return
sleep 1
xdotool type ""
xdotool key Return
sleep 1
xdotool key Tab
xdotool key Return
echo "Key sequence complete."
# ------------------------------

echo "MT5 đang chạy ngầm..."
wait "$MT5_PID"