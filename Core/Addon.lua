-- Creates the addon object every other file hangs its functions on.
-- Files share things through `ns` (the private table WoW passes to each file):
--   ns.addon   the addon object          ns.Rules   rules data (Data/)
--   ns.Util    small helpers             ns.UI      sheet window helpers (UI/)
--   ns.Opt     editor helpers (Options/) ns.Wizard  creation wizard (Wizard/)
local ADDON, ns = ...

ns.addon = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
