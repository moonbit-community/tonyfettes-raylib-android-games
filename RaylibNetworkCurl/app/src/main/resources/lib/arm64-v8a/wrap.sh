#!/system/bin/sh
HERE="$(cd "$(dirname "$0")" && pwd)"
export ASAN_OPTIONS="log_to_syslog=false:allow_user_segv_handler=1:halt_on_error=0:detect_leaks=0"
ASAN_LIB=$(ls "$HERE"/libclang_rt.asan-*-android.so 2>/dev/null)
if [ -n "$ASAN_LIB" ]; then
    export LD_PRELOAD="$ASAN_LIB"
fi
exec "$@"
