-- Creates the addon object every other file hangs its functions on.
-- Files share things through `ns` (the private table WoW passes to each file):
--   ns.addon        the addon object               ns.Util, ns.Codec  small helpers (Core/)
--   ns.Rules        rules data (Data/)             ns.FeatureKit      shorthand for features (Data/)
--   ns.Glossary     hover explanations (Data/)     ns.Themes          theme presets (UI/)
--   ns.defaults     the saved-data shape (Core/)   ns.Levels          the choices per level (Sheet/)
--   ns.RollText     wording of rolls (Actions/)    ns.UI              sheet window helpers (UI/)
--   ns.DialogSkin   the look of dialogs (UI/)      ns.Sync            sharing stats (Integrations/)
--   ns.Opt          settings helpers (Options/)    ns.options         the settings tree (Options/)
--   ns.Wizard       creation wizard (Wizard/)      ns.LevelDialog     the level dialog (Options/)
-- docs/ARCHITECTURE.md, section 2, says what each holds.
local ADDON, ns = ...

ns.addon = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
