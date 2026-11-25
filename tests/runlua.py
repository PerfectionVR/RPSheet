# Runs one Lua script with a Lua 5.1-compatible interpreter loaded from a DLL
# (LuaJIT's lua51.dll or the reference Lua 5.1). Where that DLL is comes from the
# environment variable RPSHEET_LUA_DLL (run.sh reads it from tests/local.cfg).
# usage: runlua.py script.lua [args...]   ->  ARG1, ARG2, ... as Lua globals
import ctypes, os, sys
path = os.environ.get("RPSHEET_LUA_DLL", "")
if not path or not os.path.exists(path):
    # No DLL: the Python module lupa (pip install lupa) carries a LuaJIT of its own.
    try:
        from lupa import luajit21 as lupa
    except ImportError:
        sys.exit("No Lua interpreter: set LUA_DLL in tests/local.cfg, or install the Python module lupa (see tests/README.md).")
    lua = lupa.LuaRuntime(unpack_returned_tuples=True, register_eval=False, encoding=None)
    g = lua.globals()
    for i, a in enumerate(sys.argv[2:]):
        g[("ARG%d" % (i + 1)).encode()] = a.encode()
    g[b"ACE_LIBS"] = os.environ.get("RPSHEET_ACE_LIBS", "").encode()
    try:
        lua.execute(b"local f, e = loadfile(...) if not f then error(e, 0) end f()", sys.argv[1].encode())
    except lupa.LuaError as error:
        text = error.args[0] if error.args else str(error)
        print("ERROR:", text.decode(errors="replace") if isinstance(text, bytes) else text)
    sys.stdout.flush()
    sys.exit(0)
dll = ctypes.CDLL(path)
dll.luaL_newstate.restype = ctypes.c_void_p
L = ctypes.c_void_p(dll.luaL_newstate())
dll.luaL_openlibs(L)
dll.lua_tolstring.restype = ctypes.c_char_p
dll.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
dll.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
dll.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
dll.lua_pushstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
dll.lua_setfield.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_char_p]
GLOBALS = -10002
def setglobal(name, value):
    dll.lua_pushstring(L, value.encode())
    dll.lua_setfield(L, GLOBALS, name.encode())
for i, a in enumerate(sys.argv[2:]):
    setglobal("ARG%d" % (i + 1), a)
# Folders that hold a copy of the Ace3 libraries, ";" between them (for the window tests).
setglobal("ACE_LIBS", os.environ.get("RPSHEET_ACE_LIBS", ""))
r = dll.luaL_loadfile(L, sys.argv[1].encode())
if r == 0:
    r = dll.lua_pcall(L, 0, 0, 0)
if r != 0:
    print("ERROR:", dll.lua_tolstring(L, -1, None).decode(errors="replace"))
sys.stdout.flush()
