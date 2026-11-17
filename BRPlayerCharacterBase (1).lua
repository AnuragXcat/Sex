-- ================================================================
-- BRUTAL.LUA (Full Bypass + ESP + Bullet Track + Aimbot + No Spread + FOV + Magic Bullet + Memory Features)
-- Credits: AnuragXcat
-- Anti‑Crack: Expires 2026‑07‑11 06:00 AM
-- All features OFF by default; configure via MENU.
-- ================================================================

-- ================================================================
-- ANTI-CRACK / EXPIRY SYSTEM (Must run first)
-- ================================================================
local ExpiryDateStr = "2026-08-19"
local ServerTimeCache = nil
local LocalTimeCache = nil
local IsModExpired = nil
local bTamperDetected = false
local LastCheckedTime = nil
local TimeRollbackCount = 0

local function GetExpiryTimestamp()
    local dateParts = {}
    ExpiryDateStr:gsub("(%d+)", function(num)
        table.insert(dateParts, tonumber(num))
    end)
    return os.time({
        year = dateParts[1],
        month = dateParts[2],
        day = dateParts[3],
        hour = 6,
        min = 0,
        sec = 0
    })
end

local function CheckTimeRollback(currentTime)
    if not LastCheckedTime then
        LastCheckedTime = currentTime
        return false
    end
    local timeDiff = currentTime - LastCheckedTime
    if timeDiff < -300 then
        TimeRollbackCount = TimeRollbackCount + 1
        if TimeRollbackCount >= 2 then
            bTamperDetected = true
            return true
        end
    else
        TimeRollbackCount = math.max(0, TimeRollbackCount - 1)
    end
    LastCheckedTime = currentTime
    return false
end

local function GetNetworkOrLocalTime()
    if bTamperDetected then return nil end
    if ServerTimeCache and ServerTimeCache > 0 then
        local sysDiff = os.difftime(os.time(), LocalTimeCache or os.time())
        local calculatedTime = ServerTimeCache + sysDiff
        if CheckTimeRollback(calculatedTime) then return nil end
        return calculatedTime
    end
    local fetchTime = nil
    pcall(function()
        local gameState = EPawnState and EPawnState.GetGameState and EPawnState:GetGameState()
        if slua.isValid(gameState) and gameState.GetServerWorldTimeSeconds then
            local serverWorldTime = gameState:GetServerWorldTimeSeconds()
            if serverWorldTime and serverWorldTime > 0 then
                local serverStartTime = gameState.K2_GetGameServerStartTime or gameState.ServerStartTime
                if serverStartTime and serverStartTime > 0 then
                    fetchTime = serverStartTime + serverWorldTime
                end
            end
        end
    end)
    if not fetchTime then
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) and pc.GetServerTime then
                local serverTime = pc:GetServerTime()
                if serverTime and serverTime > 0 then
                    fetchTime = serverTime
                end
            end
        end)
    end
    if not fetchTime then
        pcall(function()
            if _G.HttpRequest then
                local urls = {
                    "http://worldtimeapi.org/api/timezone/Asia/Kolkata",
                    "http://timeapi.io/api/Time/current/zone?timeZone=Asia/Kolkata"
                }
                for _, url in ipairs(urls) do
                    local resp = _G.HttpRequest(url)
                    if resp and type(resp) == "string" and #resp > 0 then
                        local data = nil
                        pcall(function() data = json.decode(resp) end)
                        local parsedTime = nil
                        if data then
                            if data.unixtime then
                                parsedTime = tonumber(data.unixtime)
                            elseif data.timestamp then
                                parsedTime = tonumber(data.timestamp)
                            elseif data.datetime then
                                parsedTime = os.time({
                                    year = tonumber(string.sub(data.datetime, 1, 4)),
                                    month = tonumber(string.sub(data.datetime, 6, 7)),
                                    day = tonumber(string.sub(data.datetime, 9, 10)),
                                    hour = tonumber(string.sub(data.datetime, 12, 13)),
                                    min = tonumber(string.sub(data.datetime, 15, 16)),
                                    sec = tonumber(string.sub(data.datetime, 18, 19))
                                })
                            end
                        end
                        if parsedTime and parsedTime > 0 then
                            fetchTime = parsedTime
                            break
                        end
                    end
                end
            end
        end)
    end
    if not fetchTime then
        local currentOsTime = os.time()
        local dateT = os.date("*t", currentOsTime)
        if dateT.year >= 2024 and dateT.year <= 2030 then
            local maxOldTime = GetExpiryTimestamp() - 31536000
            if currentOsTime < maxOldTime then
                bTamperDetected = true
                return nil
            end
            fetchTime = currentOsTime
        else
            bTamperDetected = true
            return nil
        end
    end
    if fetchTime and fetchTime > 0 then
        local maxFutureTime = os.time() + (86400 * 10)
        if fetchTime > maxFutureTime then
            bTamperDetected = true
            return nil
        end
        ServerTimeCache = fetchTime
        LocalTimeCache = os.time()
    end
    return fetchTime
end

local function CheckModStatus()
    if bTamperDetected then
        _G._MOD_EXPIRED = true
        _G._TAMPER_DETECTED = true
        return false
    end
    if IsModExpired ~= nil then
        return IsModExpired
    end
    local currentTime = GetNetworkOrLocalTime()
    if not currentTime or currentTime <= 0 then
        IsModExpired = false
        _G._NO_SERVER_TIME = true
        _G._MOD_EXPIRED = true
        return false
    end
    if currentTime > GetExpiryTimestamp() then
        IsModExpired = false
        _G._MOD_EXPIRED = true
        return false
    end
    if LastCheckedTime and currentTime < (LastCheckedTime - 300) then
        TimeRollbackCount = TimeRollbackCount + 1
        if TimeRollbackCount >= 2 then
            IsModExpired = false
            _G._MOD_EXPIRED = true
            _G._TIME_ROLLBACK_DETECTED = true
            return false
        end
    end
    IsModExpired = true
    _G._MOD_EXPIRED = false
    return true
end

local function ShowAntiCrackPopup(reason)
    if _G._ANTICRACK_POPUP_SHOWN then return end
    _G._ANTICRACK_POPUP_SHOWN = true
    pcall(function()
        local msgBox = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
        local webView = package.loaded["client.slua.logic.url.logic_webview_sdk"] or require("client.slua.logic.url.logic_webview_sdk")
        _G._MOD_EXPIRED = true
        local function OpenTelegram()
            if webView then webView:OpenURL("https://t.me/AnuragXcat") end
        end
        local msg = "ANTI-CRACK PROTECTION ACTIVATED!\n\n"
        if reason == "tamper" then
            msg = msg .. "SYSTEM TAMPERING DETECTED!\n\nDATE CHANGE IS NOT ALLOWED!\n\n"
        elseif reason == "rollback" then
            msg = msg .. "TIME MANIPULATION DETECTED!\n\nDATE ROLLBACK IS NOT ALLOWED!\n\n"
        elseif _G._NO_SERVER_TIME then
            msg = "NO INTERNET CONNECTION DETECTED!\n\nMOD REQUIRES INTERNET\nTO VERIFY LICENSE!\n\n"
        else
            msg = "MOD EXPIRED ON " .. ExpiryDateStr .. " 06:00 AM!\n\nCONTACT @AnuragXcat\nTO GET NEW VERSION!\n\n"
        end
        msg = msg .. "DEVICE INFO SAVED\n\n@AnuragXcat"
        msgBox.Show(4, " ANTI-CRACK ", msg, OpenTelegram)
    end)
end

-- Run the check; if expired, stop loading and show popup
local modStatus = CheckModStatus()
if not modStatus then
    local reason = "expired"
    if _G._TAMPER_DETECTED then
        reason = "tamper"
    elseif _G._TIME_ROLLBACK_DETECTED then
        reason = "rollback"
    elseif _G._NO_SERVER_TIME then
        reason = "nointernet"
    end
    ShowAntiCrackPopup(reason)
    return  -- Stop loading the rest of the script
end

-- ================================================================
-- CLEAN ONLINE BYPASS v1.0 — Expiry-Locked, Zero Lag
-- Blocks: Anti-cheat network reporting only
-- Does NOT touch: File I/O, Sockets, DNS, Assets, Animations
-- ================================================================

if not _G._CLEAN_BYPASS_LOADED then
    _G._CLEAN_BYPASS_LOADED = true

    -- ===== 1. HTTP REQUEST BLOCKER (Anti-cheat URLs only) =====
    pcall(function()
        if _G.HttpRequest then
            local _origHttp = _G.HttpRequest
            local blockedHosts = {
                "tss.tencent", "syzsdk", "gcloud.qq", "reportlog", "tdos",
                "logupload", "feedback.wh", "crash2", "privacy.qq", "privacy.tencent",
                "mdt.qq", "act.tencentyun", "analytics", "report.qq", "anticheatexpert",
                "crashsight", "wetest", "log.tav", "sngd", "tracer", "intlsdk",
                "igamecj", "gpubgm", "googleads", "doubleclick", "firebaselogging",
                "bugly", "beacon", "helpshift", "tdm", "apm", "safeguard", "weiyun",
                "tencent-cloud", "sdkostrace", "mbgame", "csoversea", "pubgmobile",
                "down.anticheatexpert", "logiservice.qcloud", "opensdk.tencent",
                "loginsdkapi.zingplay", "firebase", "gvoice", "pubg.com", "bluehole.com",
                "krafton.com", "bgmi.com", "battlegroundsmobileindia.com", "app.adjust",
                "appsflyer", "braze", "clevertap", "mixpanel", "amplitude", "segment",
                "datadog", "newrelic", "sentry", "logrocket", "hotjar", "crashlytics"
            }
            _G.HttpRequest = function(url, ...)
                if type(url) == "string" then
                    local low = url:lower()
                    for _, host in ipairs(blockedHosts) do
                        if low:find(host, 1, true) then
                            return nil
                        end
                    end
                end
                return _origHttp(url, ...)
            end
        end
    end)

    -- ===== 2. NETUTIL SENDPACKET BLOCKER (Report packets only) =====
    pcall(function()
        if _G.NetUtil and _G.NetUtil.SendPacket then
            local _origSend = _G.NetUtil.SendPacket
            local blockedPackets = {
                "ReportAttackFlow", "ReportSecAttackFlow", "ReportHurtFlow",
                "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow",
                "ReportPlayerBehavior", "ReportTeammatHurt", "ReportPlayerMoveRoute",
                "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow",
                "report_parachute_data", "on_tss_sdk_anti_data", "report_unrealnet_exception",
                "ReportPlayerEquipmentInfo", "ReportAimFlow", "ReportHitFlow",
                "report_heavy_weapon_box_activation_flow", "report_heavy_weapon_box_item_flow",
                "ReportCircleFlow", "report_ds_player_circle_flow", "ReportJumpFlow",
                "ReportGameStartFlow", "ReportGameEndFlow", "report_players_ping",
                "report_player_ip", "report_player_frame_ping_record", "report_net_saturate",
                "report_ds_netsaturate", "report_ds_net_continuous_saturate",
                "report_ds_netrate", "report_unrealnet_clientstats",
                "report_serverstat_avgtickdelta", "report_all_players_address",
                "report_ai_strategyinfo", "ReportAIActionFlow", "ReportGenerateMonsterFlow",
                "report_ds_match_room_data", "SendSpectatingLog", "ReportIDCardProduceFlow",
                "ReportIDCardPickUpFlow", "ReportIDCardDestroyFlow", "ReportRevivalFlow",
                "ReportGameSetting", "ReportGameSettingNew", "ReportAntsVoiceTeamCreate",
                "ReportAntsVoiceTeamQuit", "report_common_info", "report_common_battle_info",
                "ClientRPC_SyncBanID", "ClientRPC_StrongTips", "ClientRPC_NormalTips",
                "ClientRPC_NotifyBan", "ClientRPC_NotifyPunish",
                "ClientRPC_NotifyIllegalProgram", "RPC_Server_ReportPlayerKillFlow",
                "RPC_Server_ClientSecMrpcsFlow", "RPC_Server_Heartbeat",
                "RPC_Server_SwiftHawk", "RPC_Server_ClientSwiftHawkWithParams",
                "RPC_Server_ReportSimulateCharacterLocation", "RPC_Client_ShootVertifyRes",
                "RPC_ClientCoronaLab", "RPC_Server_HawkReportCheat",
                "inspection_system_report_to_inspector", "ingame_voice_ban_notify",
                "inspection_system_notify_inspector", "SwiftHawk", "ClientSwiftHawk",
                "SwiftHawkReport", "SwiftHawkData", "AntiCheatReport", "CheatDetection",
                "ViolationReport", "SecurityViolation", "IntegrityCheck", "SignatureVerify",
                "Heartbeat", "ClientHeartbeat", "ServerHeartbeat", "CoronaLabReport",
                "CoronaLabData", "PlayerSecurityInfo", "ReportSecurityInfo", "SendSecurityData"
            }
            local blockedSet = {}
            for _, p in ipairs(blockedPackets) do blockedSet[p] = true end
            
            _G.NetUtil.SendPacket = function(packetName, ...)
                if blockedSet[packetName] then
                    return nil
                end
                return _origSend(packetName, ...)
            end
        end
    end)

    -- ===== 3. SENDRPC BLOCKER =====
    pcall(function()
        if _G.SendRPC then
            local _origRPC = _G.SendRPC
            local blockedRPCs = {
                "RPC_Server_ReportPlayerKillFlow", "RPC_Server_ClientSecMrpcsFlow",
                "RPC_Server_Heartbeat", "RPC_Server_SwiftHawk",
                "RPC_Server_ClientSwiftHawkWithParams",
                "RPC_Server_ReportSimulateCharacterLocation", "RPC_Client_ShootVertifyRes",
                "RPC_ClientCoronaLab", "RPC_Server_HawkReportCheat"
            }
            local blockedSet = {}
            for _, r in ipairs(blockedRPCs) do blockedSet[r] = true end
            
            _G.SendRPC = function(rpcName, ...)
                if blockedSet[rpcName] then
                    return nil
                end
                return _origRPC(rpcName, ...)
            end
        end
    end)

    -- ===== 4. GAMEPLAY CALLBACKS REPORT KILL =====
    pcall(function()
        if _G.GameplayCallbacks then
            local function void() end
            local kills = {
                "SendTssSdkAntiDataToLobby", "SendDSErrorLogToLobby",
                "SendDSHawkEyePatrolLogToLobby", "SendSecTLog", "SendDataMiningTLog",
                "SendActivityTLog", "SendClientMemUsage", "SendClientFPS",
                "OnClientCrashReport", "OnNetworkLossDetected", "ReportMatchRoomData",
                "ReportPlayersPing", "SendClientStats", "SendServerAvgTickDelta",
                "ReportHitFlow", "OnPlayerActorChannelError", "OnPlayerRPCValidateFailed",
                "ReportAttackFlow", "ReportSecAttackFlow", "ReportHurtFlow",
                "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow",
                "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate",
                "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition",
                "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData",
                "ReportEquipmentFlow", "ReportAimFlow", "ReportCircleFlow",
                "ReportDSCircleFlow", "ReportJumpFlow", "ReportAIStrategyInfo",
                "SendAIDeliveryInfo", "ReportDailyTaskInfo", "SendPlayerSpectatingLog",
                "ReportIDCardProduceFlow", "ReportIDCardPickUpFlow",
                "ReportIDCardDestroyFlow", "ReportRevivalFlow", "ReportGameSetting",
                "ReportGameSettingNew", "ReportAntsVoiceTeamCreate",
                "ReportAntsVoiceTeamQuit", "ReportCommonInfo", "ReportLightweightStat"
            }
            for _, fn in ipairs(kills) do
                if _G.GameplayCallbacks[fn] then
                    _G.GameplayCallbacks[fn] = void
                end
            end
        end
    end)

    -- ===== 5. TSS SDK NEUTRALIZE =====
    pcall(function()
        local Tss = _G.TssSdk or package.loaded["TssSdk"]
        if Tss then
            local function void() return true end
            local tssKill = {
                "GetSdkAntiData", "GameScreenshot", "GameScreenshot2", "IsEmulator",
                "QueryOpts", "GetShellDyMagicCode", "SetToken", "EnableDisableItem",
                "InvokeCrashFromShell", "GetUserTag", "QueryTssLibcAddr",
                "RegistLibcSendListener", "RegistLibcRecvListener",
                "RegistLibcConnectListener", "RegistLibcCloseListener", "GetMrpcsData2Ptr",
                "GetTPChannelVer", "SetGameChannelIp", "SetValueByKey", "SetChannelHost",
                "SetChannelBuiltinIp", "RecvSecSignature", "PushAntiData3",
                "QueryRemainsAntiDataCount", "GetAntiData3", "DelAntiData3",
                "SetSecToken", "GetThreadsInfo", "AddTouchEvent", "InitSwitchStr",
                "SetCDNHost", "SetEnabledConnector", "QueryHookInfo", "SetCSLicense",
                "AddAnoTouchEvent", "GetObjVMFuncAddr", "ScanMemory", "ScanSo",
                "ScanFile", "GetRiskFlag", "VerifyFileHash", "CheckKernel",
                "VerifyBoot", "GetAntiDataQueue", "ReportAntiData", "SendAntiData",
                "ReportSdkData", "SendSdkData", "OnRecvData", "Init", "Start",
                "Verify", "CheckIntegrity", "Check"
            }
            for _, fn in ipairs(tssKill) do
                if Tss[fn] then
                    Tss[fn] = void
                end
            end
            if Tss.antiDataQueue then
                Tss.antiDataQueue = { push = void, pop = function() return nil end,
                    size = function() return 0 end, clear = void, flush = void }
            end
        end
    end)

    -- ===== 6. UNREALNET FILTER =====
    pcall(function()
        if _G.UnrealNet and _G.UnrealNet.FilterNetworkException then
            local _orig = _G.UnrealNet.FilterNetworkException
            _G.UnrealNet.FilterNetworkException = function(et, em)
                if em and type(em) == "string" then
                    local le = em:lower()
                    if le:find("cheat") or le:find("ban") or le:find("idip") or
                       le:find("security") or le:find("integrity") or le:find("flag") then
                        return false
                    end
                end
                return _orig(et, em)
            end
        end
    end)

    print("[CLEAN-BYPASS] Online anti-cheat reporting BLOCKED. Zero lag mode.")
end
-- ================================================================
-- END CLEAN ONLINE BYPASS
-- ================================================================


-- ================================================================
-- CLASS SKELETON (Game must see this first)
-- ================================================================
local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
  Reliable = true,
  Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Object
  }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Bool
  }
}
local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")

-- ================================================================
-- HELPER FUNCTIONS (used by bypasses)
-- ================================================================
local function nop() return true end
local function retTrue() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retEmptyString() return "" end

local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

local function isValid(obj)
    return slua.isValid(obj)
end

-- ================================================================
-- FEATURE TOGGLES AND CONFIG (Defaults: ALL OFF)
-- ================================================================
_G.Mod_ESP_Enabled = false
_G.Mod_Aimbot_Enabled = false
_G.Mod_BulletTrack_Enabled = false
_G.Mod_NoSpread_Enabled = false
_G.Mod_FOV_Enabled = false
_G.Mod_MagicBullet_Enabled = false
_G.CheatsEnabled = true
_G.Mod_MapMarker_Enabled = false

-- Config values (defaults)
_G.Mod_Aimbot_Speed = 8          -- 1-10
_G.Mod_Aimbot_Distance = 450     -- 20-800 (cm)
_G.Mod_BulletTrack_MaxDistance = 99999999  -- cm, slider 10-1000 meters -> *100
_G.Mod_BulletTrack_MinDistance = 50        -- meters
_G.Mod_BulletTrack_BodyPart = 0            -- 0=head, 1=neck, 2=chest
_G.Mod_FOV_Value = 115                     -- 80-130
_G.Mod_MagicBullet_Size = 70               -- 0-500 (percent increase, default 70)

-- ================================================================
--  FULL BYPASS ENGINE (from original BRPlayerCharacterBase.lua)
-- ================================================================
if _G._BYPASS_LOADED then return end
_G._BYPASS_LOADED = true

local noop = function() return true end
local retFalse = function() return false end
local retZero = function() return 0 end
local retEmpty = function() return {} end
local retTrue = function() return true end
local retEmptyString = function() return "" end
local safe_require = function(path) local ok, mod = pcall(require, path); return ok and mod or nil end
local isValid = slua.isValid

-- modulePatches (full table from TrnDravix) - identical to your original
local modulePatches = {
    ["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"] = {
        methods = {
            ControlMHActive = noop, Tick = noop, OnTick = noop, ReceiveTick = noop, MHActiveLogic = noop,
            TriggerAvatarCheck = noop, StartAvatarCheck = noop, ReportItemID = noop, OnReportItemID = noop,
            ReceiveAnyDamage = noop, OnWeaponHitRecord = noop, ShowSecurityAlert = noop, StaticShowSecurityAlertInDev = noop,
            SendHisarData = noop, OnLogin = noop, ValidateSecurityData = noop, CheckMemoryIntegrity = noop,
            ReportAbnormalMemory = noop, OnMemoryScanComplete = noop, SendDetectionResult = noop, TriggerClientScan = noop,
            SendAntiDataFlow = noop, SendHitFireBtnFlow = noop, SkipAlertServer = function() end,
            CheckWeaponIntegrity = retTrue, CheckAvatarIntegrity = retTrue, CheckBulletIntegrity = retTrue,
            OnGameModeType = noop,
        },
        fields = { bMHActive = false, mHActive = 0 },
        retvals = { GetNetAvatarItemIDs = retEmpty, GetCurWeaponSkinID = retZero, GetDetectionResult = retEmpty },
        custom = function(m)
            if m.__inner_impl then
                local i = m.__inner_impl
                i.SendAntiDataFlow = noop; i.SendHitFireBtnFlow = noop; i.OnBattleResult = noop; i.SendHisarData = noop
            end
            if m.BlackList then for k in pairs(m.BlackList) do m.BlackList[k] = nil end end
            if m.SkipAlertServer then pcall(m.SkipAlertServer, m) end
        end,
    },
    ["GameLua.Mod.BaseMod.Common.Security.SafetyDetectionSubsystem"] = {
        methods = { DetectAbnormal = noop, ReportAbnormal = noop, OnDetectionResult = noop, TriggerSafetyScan = noop },
        retvals = { GetScanResults = retEmpty, IsAnomalyDetected = retFalse },
    },
    _G_AvatarCheckCallback = {
        table = "_G.AvatarCheckCallback",
        methods = {
            StartAvatarCheck = noop, OnReportItemID = noop,
            PostPlayerControllerLoginInit = function(pc)
                pcall(function()
                    if pc and pc.HiggsBosonComponent then
                        pc.HiggsBosonComponent:ControlMHActive(0)
                        pc.HiggsBosonComponent.bMHActive = false
                    end
                end)
            end
        }
    },
    ["GameLua.Mod.BaseMod.Common.Security.PakIntegrityChecker"] = {
        methods = { ShowPakMismatchAlert = noop },
        retvals = { Verify = retFalse, CheckPakFile = retZero, GetPakStatus = retZero }
    },
    ["client.slua.logic.pak.logic_pak_verify"] = {
        retvals = { Verify = retFalse, CheckPakFile = retZero, GetPakStatus = retZero }
    },
    _G_STExtra = {
        table = "_G.STExtraBlueprintFunctionLibrary",
        retvals = { CheckFileIntegrity = retFalse, VerifySignature = retFalse, CheckGameLuaIntegrity = retFalse }
    },
    _G_TssSDK = {
        table = "_G.TssSDK",
        methods = {
            ReportData = noop, SendToServer = noop, SetUserInfo = noop,
            Init = noop, Start = noop, Verify = retTrue, CheckIntegrity = retTrue, Check = retTrue,
        },
        retvals = { GetSignature = function() return "BYPASSED" end }
    },
    _G_TssSDKHelper = { table = "_G.TssSDKHelper", methods = { ReportData = noop } },
    _G_Bugly = { table = "_G.Bugly", methods = { ReportException = noop, SetCustomData = noop } },
    _G_Beacon = { table = "_G.Beacon", methods = { Report = noop } },
    _G_CrashSight = { table = "_G.CrashSight", methods = { ReportException = noop, SetCustomData = noop, Log = noop } },
    ["GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"] = {
        methods = {
            ClientRPC_SyncBanID = noop, ClientRPC_StrongTips = noop, ClientRPC_NormalTips = noop, Notify = noop,
            ClientRPC_NotifyBan = noop, ClientRPC_NotifyPunish = noop, ClientRPC_NotifyIllegalProgram = noop
        },
        custom = function(m) if m.__inner_impl then m.__inner_impl.SyncBanInfo = noop end end,
    },
    ["client.slua.logic.ban.ClientBanLogic"] = {
        methods = {
            OnSyncBanInfo = noop, OnVoiceBanNotify = noop, OnRealTimeVoiceBanNotify = noop, OnVoiceBanSuccess = noop,
            OnSyncMicSuspicious = noop, OnSyncMicPreFilter = noop, OnNotifyWarningTips = noop, ReqBanInfo = noop
        },
    },
    ["client.slua.logic.ban.BanTipsLogic"] = {
        methods = { ShowBanTips = noop, ShowPunishTips = noop, ShowWarningTips = noop, OnReceiveBanNotice = noop }
    },
    _G_ban_util = { table = "_G.ban_util", retvals = { CheckBanStatus = retFalse, GetBanTime = retZero, IsBanForever = retFalse } },
    _G_logic_tt_ban = {
        table = "_G.logic_tt_ban",
        methods = { CheckIfCanCreateRole = noop },
        retvals = { JumpAppealURL = retFalse, GetCarrierInfo = function() return '[{"mcc":"000"}]' end }
    },
    ["GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem"] = {
        methods = {
            _OnHawkSync = noop, _OnHawkReportSuccess = noop, _StartExitGameTimer = noop,
            _OnRecvInspectorBroadcastCount = noop, SendReportTLog = noop, ReportCheat = noop,
            _OnHawkFlag = noop, ReportPlayerFlag = noop, RequestFlagPlayer = noop, SendFlagReport = noop,
            RequestImprison = noop, IsDuringHawkEyePatrol = retFalse, HasReported = retTrue,
            _InitHawkEyePatrolSubsystem = noop, _CollectBeWatchedPlayerInfo = noop, ServerRPC_HawkReportCheat = noop,
        },
        retvals = { CanInspectorBroadcast = retFalse },
        custom = function(mod)
            if mod.__inner_impl then
                local i = mod.__inner_impl
                i._OnHawkSync = noop; i._OnHawkReportSuccess = noop; i.TryShowReportedTips = noop
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.ClientHawkEyePatrolSubsystem"] = {
        custom = function(mod)
            if mod.__inner_impl then
                local i = mod.__inner_impl
                i._OnHawkSync = noop; i._OnHawkReportSuccess = noop; i.TryShowReportedTips = noop
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Common.Subsystem.DataLayerSubsystem"] = {
        custom = function(m)
            if m.OnSpectatorReplayChanged then
                local o = m.OnSpectatorReplayChanged
                m.OnSpectatorReplayChanged = function(...)
                    _G.IsBeingWatched = true
                    return o(...)
                end
            end
        end,
    },
    _G_ServerDataMgr = {
        table = "_G.ServerDataMgr",
        custom = function(m)
            if m.DeletablePlayerResultKey then
                for _, k in ipairs({
                    "SuspiciousHitCount", "EspTotalSimTraceCnt", "EspTotalImeFocusCnt",
                    "ClientGravityAnomalyCount", "FireCount", "SpeedCheatCount", "JumpCount", "VehicleSpeedHackCount",
                    "HeadshotCount", "KillCount", "Accuracy", "FlagCount", "TotalFlags", "IsFlagged",
                    "FlaggedByHawkEye", "FlaggedByInspection", "FlagTimestamp", "FlagLevel", "FlagSeverity",
                }) do m.DeletablePlayerResultKey[k] = true end
            end
            if m.FlagCount then m.FlagCount = 0 end
            if m.TotalFlags then m.TotalFlags = 0 end
            if m.IsFlagged then m.IsFlagged = false end
            if m.FlaggedByHawkEye then m.FlaggedByHawkEye = false end
            if m.FlaggedByInspection then m.FlaggedByInspection = false end
            if m.FlagTimestamp then m.FlagTimestamp = 0 end
            if m.FlagLevel then m.FlagLevel = 0 end
            if m.FlagSeverity then m.FlagSeverity = 0 end
        end
    },
    ["client.slua.logic.report.ToolReportUtil"] = {
        retvals = { IsReleaseVersion = retFalse, IsWhite = retFalse, GetReportSwitch = retFalse }
    },
    _G_ClientToolsReport = { table = "_G.ClientToolsReport", methods = { SendReport = noop, SendException = noop } },
    _G_ReportPlatformCrashKit = { table = "_G.ReportPlatformCrashKit", methods = { Send = noop, ForceSend = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem"] = {
        methods = {
            CheckHitIntegrity = noop, InitSession = noop, OnBattleEnd = noop,
            LuaFunc1 = retTrue, LuaFunc4 = retFalse, LuaFunc5 = retFalse,
            LuaFunc6 = retFalse, LuaFunc7 = retFalse, LuaFunc8 = retFalse,
            LuaFunc9 = noop,
        }
    },
    ["GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem"] = {
        methods = { OnHandleBehaviorScore = noop, AIPerceptionScore = noop, ReportBehavior = noop },
        retvals = { CalcFinalScore = retZero }
    },
    _G_AntiAddictionHandler = {
        table = "_G.AntiaddctionHandler",
        methods = { send_anti_addiction_req = noop, send_anti_addiction_notify = noop, on_check_nonage_anti_work = noop }
    },
    _G_AccessRestrictionHandler = {
        table = "_G.AccessRestrictionHandler",
        methods = { send_access_restriction_req = noop, send_access_restriction_notify = noop, on_player_cheat_state_notify = noop }
    },
    _G_GodzillaBanHandler = {
        table = "_G.GodzillaBanHandler",
        methods = { send_godzilla_ban_req = noop, send_godzilla_unban_req = noop }
    },
    _G_logic_deleteaccount = {
        table = "_G.logic_deleteaccount",
        retvals = { ForceDeleteAccount = retFalse },
        methods = { OnReceiveDeleteNotify = noop }
    },
    _G_compliance_util = { table = "_G.compliance_util", methods = { CheckCompliance = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem"] = {
        methods = {
            OnInit = noop, _OnPlayerKilledOtherPlayer = noop, _RecordFatalDamager = noop,
            _OnDeathReplayDataWhenFatalDamaged = noop, _RecordMurdererFromDeathReplayData = noop,
            _RecordTeammatePlayerInfo = noop, _OnBattleResult = noop, _OnShowQuickReportMutualExclusiveUI = noop,
            GetFatalDamagerMap = retEmpty, GetCachedTeammateName2InfoMap = retEmpty,
            GetTeammateName2InfoMapDuringBattle = retEmpty, GetCurrentNotInTeamHistoricalTeammateMap = retEmpty,
            GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end,
            ReportSuspiciousPlayer = noop, SubmitReport = noop, ProcessReport = noop,
            ClientRPC_SyncFatalDamagerMap = noop,
        },
        custom = function(m)
            if m.__inner_impl then
                m.__inner_impl._OnSyncFatalDamage = noop
                m.__inner_impl._OnPlayerKilledOtherPlayer = noop
                m.__inner_impl._SyncBattleResult = noop
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Common.Security.DSReportPlayerSubsystem"] = {
        methods = {
            OnInit = noop, _OnNearDeathOrRescued = noop, _OnCharacterDied = noop, _OnTeammateDamage = noop,
            _OnPlayerSettlementStart = noop, _AddKnockDownerToBattleResult = noop, _AddKillerToBattleResult = noop,
            _AddTeammateMurderToBattleResult = noop, _AddFatalDamagerMapToBattleResult = noop,
            _AddMLKillerUIDToBattleResult = noop, _SaveHistoricalTeammateInfo = noop, _RecordFatalDamager = noop,
            _RecordTeammateMurderer = noop,
            _AddEnemyMapToBattleResult = noop, _AddTeammateMapToBattleResult = noop, _SubmitAbnormalData = noop,
            _tUID2InfoMap = retEmpty, ds2history = retEmpty,
        },
    },
    ["GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils"] = {
        retvals = { GetBotType = retZero, IsCharacterDeliverAI = retFalse },
        methods = { RecordFatalDamager = noop, IsUsingHistoricalTeammateInfo = retFalse },
    },
    ["GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"] = {
        methods = { ExtractPlayerBasicInfo = retEmpty, LogIf = retFalse },
        custom = function(m)
            if m.EStrategyTypeInReplay then
                m.EStrategyTypeInReplay.EspTotalSimTraceCnt = 0
                m.EStrategyTypeInReplay.EspTotalImeFocusCnt = 0
                m.EStrategyTypeInReplay.ClientGravityAnomalyCount = 0
                m.EStrategyTypeInReplay.FlyingErrorCnt = 0
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate"] = {
        methods = { OnShowMutualExclusiveUI = noop, OnHideMutualExclusiveUI = noop,
            MaliciousTeammateReceiveWarningTips = noop, MaliciousTeammateVictimReceiveTips = noop },
    },
    _G_ClientTlogHandler = { table = "_G.ClientTlogHandler", methods = { send_report_lobby_common_tlog = noop } },
    _G_LoginAndWinTlogHandler = { table = "_G.LoginAndWinTlogHandler", methods = { on_cloud_game_event_notify = noop } },
    _G_tlog_report_utils = { table = "_G.tlog_report_utils", methods = { ReportTLogEvent = noop, ReportImmediate = noop } },
    _G_BasicDataTLogReport = {
        table = "_G.BasicDataTLogReport",
        methods = { OnSendBatchReqMsg = noop, OnImmediateReqMsg = noop, OnMergeReqMsg = noop, send_report_event_duration_log = noop, SendTlog = noop, ReportEvent = noop },
        retvals = { _GetParamData = retEmpty }
    },
    _G_BasicDataClientReport = {
        table = "_G.BasicDataClientReport",
        methods = { ReportImmediate = noop, ReportDelay = noop, OnSendBatchReqMsg = noop, OnImmediateReqMsg = noop, OnMergeReqMsg = noop },
        retvals = { _IsCanReport = retFalse }
    },
    _G_BasicDataReport = {
        table = "_G.BasicDataReport",
        methods = { ReportImmediate = noop, ReportDelay = noop, OnMergeReqMsg = noop, OnImmediateReqMsg = noop, OnSendBatchReqMsg = noop, _BatchReqMsg = noop }
    },
    _G_puffer_tlog = { table = "_G.puffer_tlog", methods = { report_download_tlog = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.ICTLogSubsystem"] = { methods = { SendICExceptionTLog = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem"] = {
        methods = { ReportFightData = noop, ReportPlayerWeapon = noop },
        retvals = { GetSimpleFightData = retEmpty }
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem"] = {
        methods = {
            _OnReportServerJumpFlow = noop, _OnReportTeleportFlow = noop, _OnReportSpeedHackFlow = noop,
            ReportServerJumpFlow = noop, CollectJumpData = noop,
        },
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem"] = { methods = { HandleKillTlog = noop } },
    _G_ClientErrorReportHandler = {
        table = "_G.ClientErrorReportHandler",
        methods = { send_client_error_report = noop, send_client_crash_report = noop, send_client_tools_batch_report_req = noop }
    },
    _G_BattleReportHandler = {
        table = "_G.BattleReportHandler",
        methods = {
            send_battle_report = noop, send_battle_result = noop, send_vod_game_report_req = noop,
            send_batch_get_vod_info_req = noop, send_get_game_report_req = noop, send_batch_get_game_report_req = noop,
            send_get_game_report_by_uid_req = noop
        }
    },
    _G_BugHandler = { table = "_G.BugHandler", methods = { send_report_bug_info = noop, send_report_bug_feedback = noop } },
    _G_LobbyPingReportHandler = { table = "_G.LobbyPingReportHandler", methods = { send_lobby_ping_report = noop, send_ingame_ping_report = noop } },
    _G_WeekRportHandler = { table = "_G.WeekRportHandler", methods = { send_week_report = noop, send_week_detail = noop } },
    _G_logic_complaint = {
        table = "_G.logic_complaint",
        methods = { SendComplaintReq = noop, Submit = noop, ReportPlayer = noop, ShowComplaint = noop, ShowHandle = noop }
    },
    ["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.EscapeBattleResultShowOBResultLogic"] = {
        methods = { OnBattleResult = noop, OnResultProcessStart = noop }
    },
    ["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowOBResultLogic"] = {
        methods = { OnBattleResult = noop, OnResultProcessStart = noop }
    },
    ["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic"] = {
        methods = {
            OnBattleResult = noop, OnResultProcessStart = noop, OnResultProcessContinue = noop,
            ReceiveData = noop, SendEndFlow = noop, OnReport = noop, ShowResult = noop, ShowResultInternal = noop,
            StopResultProcess = noop
        }
    },
    _G_EmulatorHandler = { table = "_G.EmulatorHandler", methods = { send_emulator_info = noop } },
    _G_emulator_scanner = {
        table = "_G.emulator_scanner",
        methods = { StartScan = noop, ReportScanResult = noop },
        retvals = { GetScanResult = retFalse }
    },
    _G_LoginVerifyHandler = { table = "_G.LoginVerifyHandler", methods = { send_login_verify_req = noop, send_device_verify_req = noop } },
    _G_logic_ds_monitor = { table = "_G.logic_ds_monitor", methods = { OnRecordMsg = noop, OnReportMsg = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem"] = {
        methods = { StartToCheck = noop, OnReceiveRTT = noop, OnReceiveJitter = noop, ReportAbnormal = noop, ResetData = noop }
    },
    ["GameLua.Dev.Subsystem.ShootVerifySubSystemClient"] = { methods = { OnShootVerifyFailed = noop, SendVerifyData = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.HighlightMomentSubsystem_DSChecker"] = { methods = { CheckFuncUpgradedWeaponKill = noop } },
    _G_logic_chat_voice_report = { table = "_G.logic_chat_voice_report", methods = { ReportVoiceData = noop, ReportVoiceText = noop } },
    _G_logic_chat_voice_doctor = { table = "_G.logic_chat_voice_doctor", methods = { UploadVoiceLog = noop, UploadVoiceException = noop } },
    _G_logic_home_audit_state = { table = "_G.logic_home_audit_state", methods = { SendAuditState = noop, ReportAuditResult = noop } },
    _G_logic_home_report = { table = "_G.logic_home_report", methods = { ReportHomeData = noop, ReportHomeVisitor = noop, ShowInGameReportUI = noop, SendReport = noop } },
    _G_gem_report_utils = {
        table = "_G.gem_report_utils",
        methods = { ReportGemData = noop, ReportGemPurchase = noop, ReportEventImmediate = noop },
    },
    _G_ChatHandler = { table = "_G.ChatHandler", methods = { send_report_info = noop, send_report_info_mic = noop } },
    _G_ClientReplayDataReporter = { table = "_G.ClientReplayDataReporter", methods = { ReportIntArrayData = noop, ReportFloatArrayData = noop, ReportUInt8ArrayData = noop } },
    ["GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem"] = {
        custom = function(m)
            if m.uCompletePlayBack then
                m.uCompletePlayBack.AddRecordMLAIInfo = noop
                m.uCompletePlayBack.StopRecording = noop
            end
            if m.ReportAllPlayerInfo then m.ReportAllPlayerInfo = noop end
            if m.ReportFrameData then m.ReportFrameData = noop end
            if m.ReportPlayerInput then m.ReportPlayerInput = noop end
        end,
    },
    _G_GameSafeCallbacks = {
        table = "_G.GameSafeCallbacks",
        methods = {
            PostPlayerControllerLoginInit = noop, OnDSGlueHiaInit = noop, CharacterReceiveBeginPlay = noop,
            DoAttackFlowStrategy = noop, RecordStrategyTimestampInReplay = noop, EditorIncreaseTotalStatisticCnt = noop
        },
        retvals = { GetScriptReportContent = function() return "" end }
    },
    ["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"] = {
        methods = { ReportException = noop, ReplayReportData = noop, ReportGameException = noop },
        retvals = { BugglyPostExceptionFull = retFalse, CheckCanBugglyPostException = retFalse }
    },
    _G_NetUtil = { table = "_G.NetUtil", methods = { SendTss = noop, SendToServer = noop, SendToDS = noop } },
    ["UnrealNet"] = {
        global = true,
        custom = function(m)
            if not m then return end
            if m.FilterNetworkException then
                local o = m.FilterNetworkException
                m.FilterNetworkException = function(et, em)
                    if em and type(em) == "string" then
                        local le = em:lower()
                        if le:find("cheatdetected") or le:find("idipban") or le:find("dataerror") or le:find("datamismatch")
                           or le:find("security") or le:find("integrity") or le:find("hashfail") or le:find("flag") then
                            return false
                        end
                    end
                    return o(et, em)
                end
            end
            m.HandleNetworkExceptionReport = noop
            m.HandleNetworkConnectionClosed = noop
            m.HandleSpectateException = noop
        end
    },
    ["GameLua.Mod.BaseMod.Client.Security.Gokuba"] = {
        custom = function(m)
            if m.ForwardFeature then
                m.ForwardFeature = function() return {0, 0, 0, 0, 0} end
            end
            if m.TimerHandle then
                pcall(function()
                    local time_ticker = require("common.time_ticker")
                    time_ticker.RemoveTimer(m.TimerHandle)
                end)
                m.TimerHandle = nil
            end
        end
    },
    ["GameLua.Mod.BaseMod.Common.Security.CoronaUploader"] = { methods = { Upload = noop, Flush = noop } },
    ["GameLua.Mod.BaseMod.Client.Login.LoginLock"] = { methods = { Lock = noop, OnLoginBan = noop }, retvals = { CheckBan = retFalse } },
    ["GameLua.Mod.BaseMod.GamePlay.Battle.BattleResultUploader"] = { methods = { Upload = noop } },
    ["client.slua.logic.ClientAppStat"] = { methods = { Report = noop, Flush = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.DeviceFingerprint"] = {
        methods = { Collect = noop, Sync = noop, GetHash = function() return "unknown" end }
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSDeviceCheck"] = { methods = { VerifyClientDevice = retTrue, ReportMismatch = noop } },
    ["GameLua.Mod.BaseMod.Common.Security.IntegrityCheck"] = { methods = { Run = noop, Verify = retTrue } },
    ["GameLua.Mod.BaseMod.Common.Security.APKIntegrity"] = { methods = { CheckSignature = retTrue, CheckInstallSource = retTrue } },
    ["GameLua.Mod.BaseMod.Common.Security.LibCheck"] = {
        methods = { Verify = retTrue, Check = retTrue, Scan = noop, Report = noop },
        retvals = { IsLibValid = retTrue, GetTamperedLibs = retEmpty }
    },
    _G_TDataMaster = {
        table = "_G.TDataMaster",
        methods = { Report = noop, ReportDeviceInfo = noop, SendHardwareHash = noop, CollectTelemetry = noop, SendData = noop, Sync = noop, Flush = noop },
        custom = function(m)
            if m then for k, v in pairs(m) do if type(v) == "function" then m[k] = noop end end end
        end,
    },
    _G_DeviceInfo = {
        table = "_G.DeviceInfo",
        methods = { GetDeviceID = function() return "unknown" end, GetIMEI = function() return "000000000000000" end, CollectSysInfo = noop }
    },
    ["client.slua.logic.platform.platform_db"] = { methods = { Scan = noop, CheckIntegrity = retFalse, ReportCorruption = noop } },
    ["xunyou_cache_scan"] = { methods = { StartScan = noop, GetResult = retEmpty } },
    _G_SecurityTlogQueue = { table = "_G.SecurityTlogQueue", methods = { Flush = noop, Add = noop } },
    _G_PufferDownloadReport = { table = "_G.PufferDownloadReport", methods = { ReportDownload = noop, ReportError = noop } },
    _G_ReplayRecordSecurity = { table = "_G.ReplayRecordSecurity", methods = { InjectMeta = noop, Validate = noop } },
    _G_GameServerHeartbeat = { table = "_G.GameServerHeartbeat", methods = { ReportMissedBeat = noop, CheckAlive = retTrue } },
    ["GameLua.Mod.BaseMod.Common.Security.AntiDebug"] = { methods = { Check = retFalse, Report = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.SecureBootCheck"] = { methods = { VerifyBoot = retTrue } },
    ["GameLua.Mod.BaseMod.DS.Security.DSPlayerValidCheck"] = { methods = { Validate = retTrue, ReportSuspicious = noop } },
    ["client.slua.logic.common.logic_common_legal_msg"] = {
        custom = function(m)
            if m.ShowOnePopUI then
                local o = m.ShowOnePopUI
                m.ShowOnePopUI = function(self, params)
                    if params and params.title and params.title:find("SECURITY") then return end
                    return o(self, params)
                end
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem"] = {
        methods = {
            AskForInspector = noop, ReportEnemy = noop, KickOutOneTeam = noop,
            OnReceiveInspectCmd = noop, ClientReportData = noop, SendReportToInspector = noop,
            SendKickOutOneTeam = noop, ClientNotifyInspectorImplementation = noop, RecvNotifyInspector = noop,
        },
    },
    ["GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem"] = {
        methods = {
            ServerKickOutOneTeamByPlayerImplementation = noop, AddReportedCount = noop,
            AddInspectionRecord = noop, BanPlayerByInspection = noop,
            BroadCastToAllInspector = noop, ServerReportToInspectorImplementation = noop,
            InitPlayerInspectionInfo = noop,
        },
        fields = { MAX_ASK_FOR_INSPECTOR_TIME = 0, ASK_FOR_INSPECTOR_INTERVAL = 99999 },
        custom = function(m)
            if m.__inner_impl then
                m.__inner_impl.IsGameModeAllowed = retTrue
            end
        end,
    },
    ["client.slua.logic.CustomerService.LogicSafeStation"] = {
        methods = { UploadVideoEvidence = noop, ReportPlayerBehavior = noop },
    },
    ["client.slua.logic.CustomerService.LogicCustomerService"] = {
        methods = { SendComplaint = noop, SendFeedback = noop },
    },
    ["GameLua.GameCore.Module.Vehicle.VehicleFeatures.TLog.AmphibiousBoatTLogFeature"] = {
        methods = { RecordMovement = noop, StartRecordMovement = noop },
    },
    ["client.logic.data.profile_report_cfg"] = { methods = { SendReport = noop } },
    ["GameLua.Mod.BaseMod.Client.ClientInGameCreditLogic"] = {
        methods = {
            _SendUserReaction2ExitTeamBeforeBoardingReturnLobbyNotice = noop,
            ShowReturnLobbyIfFirstExitTeamBeforeBoarding = retFalse,
            OnReceiveCreditScoreChange = noop,
            _IsFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = retFalse,
            SetFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = noop,
        },
    },
    ["GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeDevDebugSubsystem"] = { methods = { IsDebugPanelEnalbedCli = noop } },
    ["GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeModeDeathRecordSubsystem"] = { methods = { OnPlayerKilled = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.AFKReportorSubsystem"] = {
        methods = {
            HandleEnterFighting = noop, InitializePlayerInputInfo = noop,
            AddOneAFKInfo = noop, SetPlayerAFKState = noop,
            ResetPlayerInputInfo = noop, PlayerHaveAction = noop, ReportAFK = noop,
            CheckAFK = retFalse,
        },
    },
    ["GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem"] = { methods = { SendAFKTips = noop, OnHandleLostConnection = noop } },
    ["GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem"] = {
        methods = {
            RealLogoutTimer = noop, AddToLogQue = noop, DoPrint = noop,
            OnAIPawnDied = noop, OnAIPawnReceiveDamage = noop, OnAIPawnEnemyChange = noop,
        },
        fields = { LogQueue = {} },
    },
    ["client.slua.logic.data.data_mgr"] = { retvals = { GetWeaponSkinSoundVolumeInfoByGroup = retZero } },
    ["TApmHelper"] = { methods = { postEvent = noop } },
    ["GameLua.Mod.BaseMod.Common.Security.LuaIntegrityCheck"] = { methods = { Run = noop, Verify = retTrue, Check = retTrue } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientDeviceCheckSubsystem"] = {
        methods = { StartCheck = noop, ReportResult = noop },
        retvals = { IsDeviceSafe = retTrue },
    },
    ["GameLua.Mod.BaseMod.Client.Security.SpectatorAndReplaySubsystem"] = { methods = { SendReport = noop } },
    ["client.slua.logic.login.logic_version_update"] = {
        methods = { CheckVersion = noop, CheckUpdate = noop, IsNeedUpdate = retFalse, GetVersion = function() return "4.4.0" end, ShowUpdateDialog = noop }
    },
    ["client.slua.logic.version.logic_update"] = { methods = { CheckUpdate = noop, ForceUpdate = noop, IsForceUpdate = retFalse } },
    ["client.slua.logic.ban.logic_ban"] = {
        methods = { GetBanEndTime = function() return 0 end, IsInBanTime = retFalse, CheckBanStatus = retFalse, GetBanReason = retEmpty, GetBanTime = retZero }
    },
    ["client.slua.logic.login.logic_login_ban"] = {
        methods = { CheckCanLogin = retTrue, GetBanInfo = function() return { end_time = 0 } end, IsBanned = retFalse, IsSecurityBan = retFalse }
    },
    ["GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem"] = { methods = { DelayKickOutPlayer = noop, ActiveKickNotify = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientFlagSubsystem"] = {
        methods = {
            EvaluateFlags = noop,
            GetFlagLevel = retZero,
            GetFlagBanDuration = retZero,
            IsFlagged = retFalse,
            ReportFlag = noop,
            SyncFlagStatus = noop,
            IncreaseFlagCount = noop,
            ResetFlags = noop,
        },
        retvals = { IsFlagged = retFalse },
        fields = { FlagCount = 0, FlagLevel = 0, FlagSeverity = 0 },
    },
    ["client.slua.logic.ban.logic_flag_ban"] = {
        methods = {
            GetFlagBanEndTime = function() return 0 end,
            IsFlagBanned = retFalse,
            GetFlagBanDuration = retZero,
            CheckFlagBan = retFalse,
        }
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSAITLogSubsystem"] = {
        methods = { _UpdateTTKRecords = noop, _UpdateOperatingFrequency = noop }
    },
    ["GameLua.Mod.Borderland.Gameplay.Subsystem.TLogSubsystem"] = { methods = { OnInit = noop } },
    _G_TLogSubsystem = { table = "_G.TLogSubsystem", methods = { OnInit = noop } },
    ["client.slua.logic.download.report.logic_mini_pak_gem"] = {
        methods = { StartReport = noop, ReportGemLog = noop, SetCurDownloadSize = noop }
    },
    ["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogManager"] = {
        methods = {
            OnReceiveBattleResults = noop,
            AddValTLog = noop,
            SetValTLog = noop,
            SendReportLobby = noop,
        },
        fields = { ClientTlogData = {} },
    },
    ["GameLua.Mod.SocialIsland.DS.Battle.RacingAntiCheatLogic"] = {
        methods = {
            StartDetectTimer = noop, StopDetectTimer = noop,
            DetectVehicleFloating = noop, HandleFloatingCheat = noop,
            HandleSpeedCheat = noop, HandlePlayerPassCheckBelt = noop,
        },
    },
    ["GameLua.Dev.ClientCloudGM"] = { methods = { HandleCloudGMCMDStr = noop } },
    ["GameLua.Mod.BaseMod.Client.Dev.ClientCloudGM"] = { methods = { HandleCloudGMCMDStr = noop } },
    ["GameLua.Mod.BaseMod.Common.RealTimeBan.RealTimeBan"] = {
        methods = {
            OnPlayerWithRealTimeBan = noop,
            ShowAlias = noop,
            HandleEnterGameModeFightingState = noop,
            GetTipsID = retZero,
        },
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeDistanceUI"] = {
        methods = { _RefreshUI = noop, _IsShouldShow = retFalse }
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeNextPatrolWindow"] = {
        methods = { OnShow = noop }
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeReportWindow"] = {
        methods = { _OnClickSubmit = noop, _RefreshWindow = noop, RegistEvents = noop }
    },
    ["GameLua.Mod.BaseMod.Client.Security.SecurityClientUtils"] = {
        methods = {
            HasOtherTeammateOffline = retFalse,
            HasOtherHealthyOnlineTeammate = retFalse,
            IsMyHealthStatusHealthy = retTrue,
            IsMyHealthStatusAlive = retTrue,
            GetMyHealthStatus = function() return 1 end,
        }
    },
    ["GameLua.Mod.BaseMod.Client.Ban.ClientBanLogic"] = {
        methods = {
            OnVoiceBanNotify = noop, OnRealTimeVoiceBanNotify = noop,
            OnSyncBanInfo = noop, OnNotifyWarningTips = noop,
            VoiceBanEndTime = 0, bEnableVoiceReport = false,
        },
    },
    ["GameLua.Mod.BaseMod.Client.Security.ClientBanLogic"] = {
        methods = {
            OnVoiceBanNotify = noop, OnRealTimeVoiceBanNotify = noop,
            OnSyncBanInfo = noop, OnNotifyWarningTips = noop,
        },
    },
    ["ScreenshotMaker"] = {
        custom = function(m)
            if not m then return end
            m.MakePicture = function() return "" end
            m.ReMakePicture = function() return "" end
            m.HasCaptured = function() return true end
        end,
    },
    ["client.slua.logic.ugc.UGCNewTLogReport"] = {
        methods = { SendExposeReq = noop, SendInteractionReq = noop, TLogReport = noop }
    },
    ["client.slua.logic.ugc.logic_ugc_tlog"] = {
        methods = { SendModTLog = noop, ReportStay = noop }
    },
    ["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil"] = {
        methods = { ReportGeneralCountByBRPhase = noop, ReportCommonTLogDataByBRPhase = noop }
    },
    ["ReportCrashKitFeature"] = {
        custom = function(m) if m and m.ReportCharacterAttachedOnVehicleException then m.ReportCharacterAttachedOnVehicleException = noop end end,
    },
    ["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportSubsystemReporter"] = {
        custom = function(m)
            if m then
                m.ReportIntArrayData = noop
                m.ReportUInt8ArrayData = noop
                m.ReportFloatArrayData = noop
            end
        end,
    },

    -- ===== New patches from TrnDravix =====
    ["SkillAction_GrenadeThrowReport"] = {
        methods = {
            ReportGrenadeThrow = noop,
            CheckGrenadeAnimationState = retTrue,
            ValidateThrow = retTrue,
            OnGrenadeThrow = noop,
        },
    },
    ["BanMacro"] = {
        methods = {
            DetectInputVariance = retTrue,
            CheckClickTiming = retFalse,
            AnalyzeClickPattern = retEmpty,
            ReportMacro = noop,
            CheckAllBanTypes = retTrue,
        },
    },
    ["NGActionBanSprint"] = {
        methods = {
            ValidateSprintSpeed = retTrue,
            CheckSpeedHack = retFalse,
            ReportSprintViolation = noop,
        },
    },
    ["ReportGrenadeThrow"] = {
        methods = {
            SendGrenadeReport = noop,
            ReportGrenadeData = noop,
        },
    },
    ["InputVarianceChecker"] = {
        methods = {
            CalculateVariance = retZero,
            IsHumanLike = retTrue,
        },
    },
    ["SpeedhackValidator"] = {
        methods = {
            ValidateSpeed = retTrue,
            IsSpeedhack = retFalse,
            ReportSpeedhack = noop,
        },
    },
    ["HawkEyeSpectatorState"] = {
        methods = {
            OnSpectatorStateChange = noop,
            TrackAimMovement = noop,
            ReportSuspiciousAim = noop,
        },
    },
    ["EmulatorSystem"] = {
        fields = { EmulatorTestMark = true },
        methods = { IsEmulator = retFalse, GetEmulatorName = function() return "NoEmulator" end },
    },
    ["logic_emulator"] = {
        methods = { find_emulator = retFalse, IsSpecialEmulator = retFalse },
    },
    ["VoiceReportSubsystem"] = {
        methods = {
            PLAYER_BAN_GLOBAL_MI = noop,
            ReportSuspicious = noop,
            PreFilterAI = noop,
        },
    },
    ["BugglyReportRecord"] = {
        methods = { Report = noop, Record = noop },
        retvals = { GetProbability = retZero },
    },
    ["PatrollerModule"] = {
        methods = { UpdateStats = noop, GetRank = retZero, AddInspectionRecord = noop },
    },
    ["DSQuickReportMaliciousTeammate"] = {
        methods = {
            _HandleCarrybackFallingDamage = noop,
            _HandleGrenadeDamage = noop,
            _HandleVehicleExplosionDamage = noop,
            ReportMaliciousTeammate = noop,
        },
    },
    ["ClientQuickReportMaliciousTeammate"] = {
        methods = {
            RPC_Client_MaliciousTeammateReceiveWarningTips = noop,
            ShowQuickReportDialog = noop,
            OnDeath = noop,
        },
    },
    ["InspectionSystemKickPlayerConfirm"] = {
        methods = {
            OnConfirmTyped = retTrue,
            CheckConfirmText = retTrue,
        },
    },
    ["RockBandActor"] = {
        custom = function(m)
            if m then
                m._G.IsEditor = false
                m._G.IsTesting = false
            end
        end,
    },
    ["ban_reddot_system"] = {
        methods = {
            EnterSafeStation = noop,
            UpdateRedDot = noop,
            OnBanUpdate = noop,
        },
    },
    ["ban_reddot_data"] = {
        methods = {
            LoadBanRedDotData = noop,
            UpdateBanRedDot = noop,
        },
    },
    ["DSPlayerDataReportSubsystem"] = {
        methods = {
            TrackRescue = noop,
            TrackDieWithoutRevive = noop,
            HandleBattleResult = noop,
            _HandleRescue = noop,
            _HandleDieWithoutRevive = noop,
        },
        custom = function(m)
            if m then
                m.DieWithoutReviveTime = 99999
                if m._OnGameEnd then m._OnGameEnd = noop end
            end
        end,
    },
    ["UGC_AiCopilot_Report"] = {
        methods = {
            ReportContent = noop,
            ReportLowQuality = noop,
            SendReport = noop,
        },
    },
    ["gem_report_utils"] = {
        methods = {
            ReportEventDelay = noop,
            ReportImmediate = noop,
        },
    },
    ["gem_report_config"] = {
        methods = {
            OnNetworkEvent = noop,
            OnBanEvent = noop,
        },
    },
    ["net"] = {
        global = true,
        custom = function(m)
            if m then
                m.DumpPropertySerializationStats = noop
            end
        end,
    },
}

-- Hook require/import
local originalRequire = require
local function hookedRequire(name)
    local mod = originalRequire(name)
    if modulePatches[name] then
        local cfg = modulePatches[name]
        if cfg.custom then pcall(cfg.custom, mod)
        elseif not cfg.global then
            if cfg.methods then for k, v in pairs(cfg.methods) do if type(mod[k]) == "function" then mod[k] = v end end end
            if cfg.retvals then for k, v in pairs(cfg.retvals) do if type(mod[k]) == "function" then mod[k] = v end end end
            if cfg.fields then for k, v in pairs(cfg.fields) do if mod[k] ~= nil then mod[k] = v end end end
        end
    end
    return mod
end
if require ~= hookedRequire then require = hookedRequire end

local originalImport = import
local function hookedImport(name)
    local mod = originalImport(name)
    if modulePatches[name] then
        local cfg = modulePatches[name]
        if cfg.custom then pcall(cfg.custom, mod)
        elseif not cfg.global then
            if cfg.methods then for k, v in pairs(cfg.methods) do if type(mod[k]) == "function" then mod[k] = v end end end
            if cfg.retvals then for k, v in pairs(cfg.retvals) do if type(mod[k]) == "function" then mod[k] = v end end end
            if cfg.fields then for k, v in pairs(cfg.fields) do if mod[k] ~= nil then mod[k] = v end end end
        end
    end
    return mod
end
if import ~= hookedImport then import = hookedImport end

-- ===== Additional bypass functions =====
local function TssSdkBypass()
    pcall(function()
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"] or package.loaded["client.slua.logic.tss_sdk"]
        if not TssSdk then
            local ok, mod = pcall(require, "TssSdk")
            if ok then TssSdk = mod end
        end
        if not TssSdk then return end
        local bypassFuncs = {
            "GetSdkAntiData", "GameScreenshot", "GameScreenshot2", "IsEmulator",
            "QueryOpts", "GetCommLibValueByKey", "GetShellDyMagicCode", "AddMTCJTask",
            "SetToken", "EnableDisableItem", "InvokeCrashFromShell", "ReInitMrpcs",
            "GetUserTag", "QueryTssLibcAddr", "RegistLibcSendListener", "RegistLibcRecvListener",
            "RegistLibcConnectListener", "RegistLibcCloseListener", "GetMrpcsData2Ptr",
            "GetTPChannelVer", "SetGameChannelIp", "SetValueByKey", "SetChannelHost",
            "SetChannelBuiltinIp", "RecvSecSignature", "PushAntiData3", "QueryRemainsAntiDataCount",
            "GetAntiData3", "DelAntiData3", "SetSecToken", "GetThreadsInfo", "AddTouchEvent",
            "InitSwitchStr", "SetCDNHost", "SetEnabledConnector", "QueryHookInfo", "SetCSLicense",
            "AddAnoTouchEvent", "GetObjVMFuncAddr", "ScanMemory", "ScanSo", "ScanFile",
            "GetRiskFlag", "VerifyFileHash", "CheckKernel", "VerifyBoot", "GetAntiDataQueue",
            "ReportAntiData", "SendAntiData", "ReportSdkData", "SendSdkData", "OnRecvData"
        }
        for _, funcName in ipairs(bypassFuncs) do
            if TssSdk[funcName] then
                TssSdk[funcName] = function(...) return true, "BYPASSED" end
            end
        end
        if TssSdk.antiDataQueue then
            TssSdk.antiDataQueue = {}
            TssSdk.antiDataQueue.push = function() end
            TssSdk.antiDataQueue.pop = function() return nil end
            TssSdk.antiDataQueue.size = function() return 0 end
            TssSdk.antiDataQueue.clear = function() end
        end
        if TssSdk.IsEmulator then TssSdk.IsEmulator = function() return false end end
        if TssSdk.InvokeCrashFromShell then TssSdk.InvokeCrashFromShell = function() return false end end
        if TssSdk.QueryHookInfo then TssSdk.QueryHookInfo = function() return {} end end
        if TssSdk.PushAntiData3 then TssSdk.PushAntiData3 = function() return true end end
        if TssSdk.QueryRemainsAntiDataCount then TssSdk.QueryRemainsAntiDataCount = function() return 0 end end
        if TssSdk.GetAntiData3 then TssSdk.GetAntiData3 = function() return nil end end
        if TssSdk.DelAntiData3 then TssSdk.DelAntiData3 = function() return true end end
        if TssSdk.AddTouchEvent then TssSdk.AddTouchEvent = function() return true end end
        if TssSdk.SetEnabledConnector then TssSdk.SetEnabledConnector = function() return true end end
        if TssSdk.SetCSLicense then TssSdk.SetCSLicense = function() return true end end
        if TssSdk.GetObjVMFuncAddr then TssSdk.GetObjVMFuncAddr = function() return 0 end end
    end)
end

local function EnhancedAntiCheatBypass()
    if _G.BYPASS_STATE and _G.BYPASS_STATE.ANTI_CHEAT_MANAGER_DISABLED then return end
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local AntiCheatMgr = nil
        if pc.PlayerAntiCheatManager then
            AntiCheatMgr = pc.PlayerAntiCheatManager
        elseif pc.AntiCheatManager then
            AntiCheatMgr = pc.AntiCheatManager
        end
        if not slua.isValid(AntiCheatMgr) then
            local PlayerAntiCheatManagerClass = import("PlayerAntiCheatManager")
            if PlayerAntiCheatManagerClass then
                local comps = pc:GetComponentsByClass(PlayerAntiCheatManagerClass)
                if comps and comps:Num() > 0 then
                    AntiCheatMgr = comps:Get(0)
                end
            end
        end
        if not slua.isValid(AntiCheatMgr) then return end
        local counterFields = {
            "AutoAimFailedCnt", "TrackingFailedCnt", "AreaDamageFailedCnt", "JumpHeightFailedCnt",
            "JumpFarFailedCnt", "VehicleFlyingFailedCnt", "ShootVerifyTimes", "SpeedUpValue",
            "ClientTimeTotalAcc", "ServerAccumulateErrors", "ServerAvgErrors", "ServerCorrectTimes",
            "PlayerBadPingTimes", "VehicleSpeedZDeltaTotal", "VehicleSpeedZDeltaOver10Times",
            "PVSInCityKillCount", "PVSNotInCityKillCount", "PVSCellHidePercent", "PVSTotalHidePercent",
            "ServerMoveParameterVerifyCount", "ServerMoveParameterVerifyFailedCount",
            "StuckGroundPunishCount", "ContinueMoveBurstCount", "RecordContinueMoveBurstCount",
            "TrialBaseDiffCount", "InclusiveBegin", "InclusiveEnd"
        }
        for _, field in ipairs(counterFields) do
            pcall(function()
                if type(AntiCheatMgr[field]) == "number" then AntiCheatMgr[field] = 0 end
            end)
        end
        local boolFields = {
            "bReportFeedBack","bOpenDetailDataCollect","bOpenBaseDiffCheck","bUploadStuckGroundCount",
            "bStuckGroundCapsule","bImpactOtherAfterBurst","bGiveupPickupWhenBrust",
            "bOpenPickupWhenBrustCheck","bMustStrictContinue"
        }
        for _, field in ipairs(boolFields) do
            pcall(function()
                if type(AntiCheatMgr[field]) == "boolean" then AntiCheatMgr[field] = false end
            end)
        end
        local maxFields = {
            "MaxShootPointPassWall", "MaxMuzzleHeightTime", "MaxLocusFailTime",
            "MaxBulletVictimClientPassWallTimes", "MaxGunPosErrorTimes",
            "MaxAllowVehicleTimeSpeedRawTime", "MaxAllowVehicleTimeSpeedConvTime",
            "MaxAllowVehicleAccTime", "MaxSingleShotDamage", "MaxFallingSustainTime",
            "MaxCustomMoveModeSustainTime", "MaxMoveDistance2DPerSecond",
            "MaxCharMoveDist2DPerSecond", "MaxDistanceToGround", "MaxContinueMoveBurstXY",
            "ContinueMoveBurstInterval", "BaseDiffRegion", "BaseDiffVel", "BaseDiffTime",
            "MinImpactOtherInterval", "MinBurstToPickupInterval", "MaxPlayerDisSquaredForPickup",
            "ContinueMoveBurstTolerant", "MultiStuckGroundScale", "StuckTypePunishSet",
            "StuckGroundPunishType"
        }
        for _, field in ipairs(maxFields) do
            pcall(function()
                if type(AntiCheatMgr[field]) == "number" then AntiCheatMgr[field] = 999999 end
            end)
        end
        local paraFields = {
            "ParachuteStartTime","ParachuteOpenTime","ParachuteCloseTime",
            "ParachuteStartHight","ParachuteOpenHight","ParachuteCloseHight"
        }
        for _, field in ipairs(paraFields) do
            pcall(function()
                if type(AntiCheatMgr[field]) == "number" then AntiCheatMgr[field] = 0 end
            end)
        end
        pcall(function() AntiCheatMgr.DSProperty = nil end)
        local verifySwitchFields = {
            "VsNoHitDetail","VsMuzzleRangeCircle","VsMuzzleRangeUp",
            "VsHitBoneNameNone","VsHitBoneHitMissMatch","VsBulletID",
            "VsVehicleTimeStampError","VsWatchTimeStampError",
            "VsShootRpgShootTimeVerify","VsShootLockShootTimeVerify",
            "VsShootRpgHitNewVerify","VsShootTimeConDelta",
            "VsServerNoOldShoot","VsClientNotConnectShoot",
            "VsShootRpgShootIntervalVerify","VsImpactPointAndBulletDisBig",
            "VsShootVerifyInvalid","VsImpactActorPosWithNoHisPos",
            "VsShootAngleInVaild","VsMuzzleAndTailPosInVaild",
            "VsMuzzleAndImpactPassWall","VsMuzzleAndTailPassWall",
            "VsImpactActorPosOffsetBig","VsImpactPointChangeSmall",
            "VsImpactBulletPosOffsetBig","VsTotalImactCharacterNum",
            "VsBoneInfo","VsJumpMaxHeight","VsJumpMaxHeight15","VsJumpMaxHeight2",
            "SpeedQuickCheck","BulletDirError","WalkSpeedFailedCnt",
            "DSSpeedOver10FailedCnt","DSSpeedOver15FailedCnt","DSSpeedOver20FailedCnt",
            "DSFallingSpeedFailCount","DSFallingHeightFailCount",
            "SwitchMuzzleLocusError","SwitchMuzzleLocusErrorX","SwitchMuzzleLocusErrorY","SwitchMuzzleLocusErrorZ",
            "Gun2ShooterPosError1","SwitchHeadLocusError3","SwitchMuzzleLocusErrorLength",
            "SwitchShootPosHistoryLocusError3","SwitchHitComponentUnvalid","SwitchHitNoRender",
            "SwitchHitOutCollisionBox","HeadOverShootPos","SwitchMuzzleImpactDirSkipPunish1",
            "SwitchInvalidBulletNumInBarrel","SwitchShooterMovementError2","GunTailPosError",
            "SwitchMuzzleImpactDirSkipPunish2","SwitchMuzzleImpactDirError1","SwitchMuzzleImpactDirError2",
            "ShooterHead2PosBlock","SwitchShootPosHistoryLocusError2","Head2GunTailPosError1",
            "SwitchShootDirExcepation1","SwitchShootDirExcepation2","SwitchCamerModeException",
            "SwitchShootPosHistoryLocusError4","SwitchMuzzleImpactDirError3",
            "CharacterMoveException1","CharacterMoveException2","CharacterMoveException3",
            "CharacterMoveException4","CharacterMoveException5","CharacterMoveException6",
            "VehicleSpeedZDeltaOver10TimesWhenNoXY","VehicleVelZCheck1","VehicleVelZCheck2",
            "VehicleMaxSpeedCheck","VehicleHitMuzzleCheck","VehicleHitImpactPointCheck",
            "VehicleHitBlockWall","VehicleSidesway1","VehicleSidesway2",
            "FarShootInMidAirVehicleExceedThreshold","FarShootInMidAirVehicleEnemyDistanceTrial",
            "FarShootInMidAirVehicleEnemyDistanceFurtherTrial","FarShootInMidAirVehicleHeightTrial",
            "FarShootInMidAirVehicleHeightFurtherTrial","FarShootInMidAirPawnExceedThreshold",
            "FarShootInMidAirPawnEnemyDistanceTrial","FarShootInMidAirPawnEnemyDistanceFurtherTrial",
            "FarShootInMidAirPawnHeightTrial","FarShootInMidAirPawnHeightFurtherTrial",
            "NonGunADSFarShootCount","NonGunADSFarShootFromClientBulletDataCount",
            "NonGunADSFarShootFromClientBulletDataEnemyDistanceTrialCount",
            "NonGunADSFarShootFromClientBulletDataEnemyDistanceFurtherTrialCount",
            "ClientUploadFuzzyObjectVerifyFail","ClientMoveTimeStampResetFrequencyExceedThreshold",
            "ShootBirdNonGunADSExceedThreshold","ShootBirdNonGunADSDistanceTrial",
            "ShootBirdNonGunADSDistanceFurtherTrial","FarShootInHighTangentMoveSpeedExceedThreshold",
            "FarShootInHighTangentMoveSpeedEnemyDistanceTrial","FarShootInHighTangentMoveSpeedEnemyDistanceFurtherTrial",
            "FarShootInHighTangentMoveSpeedSpeedTrial","FarShootInHighTangentMoveSpeedSpeedFurtherTrial",
            "IllegalTeamUpNearbyButNoFireAfterKill","IllegalTeamUpNearbyButNoFireAfterKillDistanceTrial",
            "IllegalTeamUpNearbyButNoFireAfterKillTimeTrial","IllegalTeamUpNearbyButNoFireAfterKillMaxTime",
            "IllegalTeamUpNearbyButNoFirePickUpItem","IllegalTeamUpNearbyButNoFirePickUpItemDistanceTrial",
            "IllegalTeamUpNearbyButNoFirePickUpItemTimeTrial","IllegalTeamUpNearbyButNoFirePickUpItemMaxTime",
            "IllegalTeamUpNearbyButNoFireNotKill","IllegalTeamUpNearbyButNoFireNotKillDistanceTrial",
            "IllegalTeamUpNearbyButNoFireNotKillTimeTrial","IllegalTeamUpNearbyButNoFireNotKillMaxTime",
            "IllegalTeamUpNearbyButNoFireOnVehicle","IllegalTeamUpNearbyButNoFireOnVehicleDistanceTrial",
            "IllegalTeamUpNearbyButNoFireOnVehicleTimeTrial","IllegalTeamUpNearbyButNoFireOnVehicleMaxTime",
            "IllegalTeamUpNearbyButNoFireSameVehicle","IllegalTeamUpNearbyButNoFireSameVehicleTimeTrial",
            "IllegalTeamUpNearbyButNoFireSameVehicleMaxTime","IllegalTeamUpUseObjectTogether",
            "IllegalTeamUpGetOnEnemyVehicleCount","IllegalTeamUpNearbyButNoFireOneSideHasWeaponOnFoot",
            "IllegalTeamUpNearbyButNoFireOneSideHasWeaponOnFootDistanceTrial","IllegalTeamUpStayOnEnemyVehicle",
            "KillBird","ShooterCapsuleCollided","ParachuteLandingSecondsExceedThreshold",
            "ParachuteObliqueLandingSecondsExceedThreshold","SmallActorTimeDilationCount",
            "LargeRotateLockShooting","SmallRotateLockShooting","OneClipShootCount","ClientWeaponFastReload",
            "UndergroundCount","MoveDistance2DPerSecondAnomaly","CharMoveDist2DPerSecondAnomaly",
            "CharMoveDist2DPerSecondCount","DistanceToGroundAnomaly","SingleShotDamageAnomaly","BandaCount",
            "DSCheckClientTimeMoveDistance2D","DSCheckClientTimeMoveDistance2DTrial",
            "DSCheckClientTimeMoveDistance2DFurther","DSCheckClientTimeMoveDistanceZ",
            "DSCheckClientTimeMoveDistanceZTrial","DSCheckClientTimeMoveDistanceZFurther",
            "ReplayMaxFallingSustainTime","ReplayMaxCustomMoveModeSustainTime","ReplayMaxSingleShotDamage",
            "CharMoveAccumDist2D_DS","CharMoveAccumDist3D_DS","CharMoveAccumDist2D_Client",
            "CharMoveAccumDist3D_Client","CharMoveAccumDist2D_ClientAll","CharMoveAccumDist3D_ClientAll",
            "MetroEnterRadiationTime","MetroEnterRadiationTimeTrial","MetroLeaveBornObstacle",
            "VsPetJumpHeightLimiter","VsPetMoveSpeedLimiter","VsBioVehicleMoveSpeedLimiter",
            "VsBioVehicleJumpHeightLimiter","VsPterosaurFlyVehicleSpeed","VsBioVehicleGravityLimiter",
            "ServerMoveCacheCountOver","ServerMoveCacheCountOver3d","ServerMoveBurst","ImpactOtherAfterBurst",
            "KillOtherAfterBurst","PickupAfterBurst","ContinueMoveBurst","ServerMoveTimeStamp",
            "ServerMoveAccel","ServerMoveClientLoc","ServerMoveCompressedMoveFlags","ServerMoveClientRoll",
            "ServerMoveView","ServerMoveClientMovementBase","ServerMoveClientBaseBoneName",
            "ServerMoveClientMovementMode","VerifySwitchCameraRotation","VerifySwitchPeekShootThroughWall",
            "VerifySwitchCameraLocation","VerifySwitchAutoAimByLockView","VerifySwitchControlRotation",
            "VerifySwitchRecoilFaildCount","VerifySwitchMarcoPolo","VerifySwitchMarcoPolo2",
            "VerifySwitchMarcoPolo3","VerifySwitchMeshScaleDiff","VerifySwitchOfflineMove",
            "VerifySwitchFastAimShootHit","VerifySwitchNoRecoilOnWeaponShoot","VerifySwitchLessRecoilOnWeaponShoot",
            "VerifySwitchNoRecoilOnKickBack","VerifySwitchLessRecoilOnKickBack","VerifySwitchDivingBoost",
            "VerifySwitchRecoilCurveFailed","PlayerQuickProne","BaseDiffSample",
            "VsTeammateRescue","VsTeammateRescueVictim","VsTeammateRecall","VsTeammateRecallVictim",
            "VsAutoClicker","VsAbnormalShootingRotation","PlayerInstantHeightDiff","Player2SecHeightDiff",
            "CheatStateData2TotalCheatTimes","MoveCheatAntiStrategy3TotalCheatTimes","ServerAccumulateErrorReplay"
        }
        for _, fieldName in ipairs(verifySwitchFields) do
            pcall(function()
                local vs = AntiCheatMgr[fieldName]
                if vs and type(vs) == "table" then
                    vs.bActive = false
                    vs.MaxCount = 99999
                    vs.CurrentCount = 0
                    vs.TrialCount = 0
                    vs.TrialMaxCount = 99999
                    vs.PunishType = 0
                end
            end)
        end
        local burstFields = {
            "ServerAccumulateErrorBurst","DSSpeedOver10BurstCount",
            "ParachuteSpeedBurst","ClientTimestampBurst","ClientTimestampBurstTrial"
        }
        for _, fieldName in ipairs(burstFields) do
            pcall(function()
                local bvs = AntiCheatMgr[fieldName]
                if bvs and type(bvs) == "table" then
                    bvs.bActive = false
                    bvs.MaxCount = 99999
                    bvs.CurrentCount = 0
                end
            end)
        end
        pcall(function()
            if AntiCheatMgr.ReportMiscMap then AntiCheatMgr.ReportMiscMap:Clear() end
        end)
        local methodFields = {
            "ReportAntiCheatDetailData","PushWeaponAntiData","OnRecoverOnServer",
            "OnPreReconnectOnServer","ExitParachute","EnterParachute","EnterJumping",
            "Cofey","Cofew","SetTrialRegion","GetSoftString","GetCheckMoveStr2",
            "GetCheckMoveStr1","GetAACString","GetAACCountByID"
        }
        for _, method in ipairs(methodFields) do
            pcall(function()
                if AntiCheatMgr[method] and type(AntiCheatMgr[method]) == "function" then
                    AntiCheatMgr[method] = function(...)
                        if method == "GetSoftString" then return 0 end
                        if method == "GetCheckMoveStr1" or method == "GetCheckMoveStr2" then return "" end
                        if method == "GetAACString" then return "" end
                        if method == "GetAACCountByID" then return 0 end
                        if method == "Cofey" then return 0 end
                        return true
                    end
                end
            end)
        end
        pcall(function()
            local catchData = AntiCheatMgr.CatchReportAntiCheatDetailData
            if catchData and type(catchData) == "table" then
                catchData.bActive = false
                catchData.CurrentCount = 0
                catchData.MaxCount = 99999
            end
        end)
        _G.BYPASS_STATE = _G.BYPASS_STATE or {}
        _G.BYPASS_STATE.ANTI_CHEAT_MANAGER_DISABLED = true
    end)
end

local function MemoryBypass()
    pcall(function()
        local funcs = {"__aeabi_memset","__strncpy_chk","memmove_chk","memset_chk","memcpy","malloc","calloc","realloc","free","close","dup2","listen"}
        for _, fn in ipairs(funcs) do if _G[fn] then _G[fn] = function() return true end end end
    end)
end

local function TimeBypass()
    pcall(function()
        if _G.gmtime then _G.gmtime = function() return os.date("!*t") end end
        if _G.gettimeofday then _G.gettimeofday = function() return os.time() end end
        if _G.mktime then _G.mktime = function(t) return os.time(t) end end
        if _G.imp_time then _G.imp_time = function() return os.time() end end
    end)
end

local function NetworkBypass()
    pcall(function()
        local funcs = {"sys_read","sys_open","nanosleep","imp_recv","imp_send","socket"}
        for _, fn in ipairs(funcs) do if _G[fn] then _G[fn] = function() return true end end end
    end)
end

local function ReportBypass()
    pcall(function()
        local funcs = {"report","COREREPORT","tdm_report","android_log_print","__android_log_print"}
        for _, fn in ipairs(funcs) do if _G[fn] then _G[fn] = function() return true end end end
    end)
end

local function StrBypass()
    pcall(function()
        if _G.strstr then _G.strstr = function() return "" end end
        if _G.strcpy then _G.strcpy = function() return "" end end
        if _G.strlen then _G.strlen = function() return 0 end end
        if _G.strncpy then _G.strncpy = function() return "" end end
    end)
end

local function ProcessBypass()
    pcall(function()
        if _G.getpid then _G.getpid = function() return 0 end end
        if _G.getppid then _G.getppid = function() return 0 end end
        if _G.gettid then _G.gettid = function() return 0 end end
    end)
end

local function AntiDebugBypass()
    pcall(function()
        if _G.ptrace then _G.ptrace = function() return 0 end end
        if _G.monitor then _G.monitor = function() return true end end
    end)
end

local function DLCmdBypass()
    pcall(function()
        if _G.dlopen then _G.dlopen = function() return 0 end end
        if _G.cmd then _G.cmd = function() return "" end end
        if _G.name then _G.name = function() return "" end end
    end)
end

local function AnoSDKBypass()
    pcall(function()
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            if TssSdk.AnoSDKDelReportData then TssSdk.AnoSDKDelReportData = function() return true end end
            if TssSdk.AnoSDKDelReportData3 then TssSdk.AnoSDKDelReportData3 = function() return true end end
            if TssSdk.AnoSDKDelReportData4 then TssSdk.AnoSDKDelReportData4 = function() return true end end
            if TssSdk.AnoSDKGetReportData then TssSdk.AnoSDKGetReportData = function() return nil end end
            if TssSdk.AnoSDKGetReportData2 then TssSdk.AnoSDKGetReportData2 = function() return nil end end
            if TssSdk.AnoSDKGetReportData3 then TssSdk.AnoSDKGetReportData3 = function() return nil end end
            if TssSdk.AnoSDKGetReportData4 then TssSdk.AnoSDKGetReportData4 = function() return nil end end
        end
    end)
end

local function MprotectBypass()
    pcall(function()
        if _G.mprotect then _G.mprotect = function() return 0 end end
        if _G.munmap then _G.munmap = function() return 0 end end
    end)
end

-- ===== Apply all bypass functions =====
local function ApplyAllBypasses()
    TssSdkBypass()
    EnhancedAntiCheatBypass()
    MemoryBypass()
    TimeBypass()
    NetworkBypass()
    ReportBypass()
    StrBypass()
    ProcessBypass()
    AntiDebugBypass()
    DLCmdBypass()
    AnoSDKBypass()
    MprotectBypass()
end

-- ================================================================
-- SERVER-SIDE & LOG BYPASS v2.0 — 7‑day behavior ban killer (full from original)
-- ================================================================
local function ApplyServerSideAndLogBypasses()
    -- Redefine helpers inside to avoid dependency on global definitions
    local function noop() end
    local function retTrue() return true end
    local function retFalse() return false end
    local function retZero() return 0 end
    local function retEmpty() return {} end
    local function retEmptyString() return "" end

    print("[SERVER-BYPASS] Initializing server-side and log protection...")

    -- ======================================================================
    -- SECTION A : Global TLog & Report Sinks (kill ALL reporting paths)
    -- ======================================================================
    pcall(function()
        -- BasicDataTLogReport / BasicDataClientReport / BasicDataReport
        local function killBasicReports(modName)
            pcall(function()
                local mod = package.loaded[modName] or require(modName)
                if mod then
                    if mod.ReportImmediate then mod.ReportImmediate = noop end
                    if mod.ReportDelay then mod.ReportDelay = noop end
                    if mod.OnSendBatchReqMsg then mod.OnSendBatchReqMsg = noop end
                    if mod.OnImmediateReqMsg then mod.OnImmediateReqMsg = noop end
                    if mod.OnMergeReqMsg then mod.OnMergeReqMsg = noop end
                    if mod.send_report_event_duration_log then mod.send_report_event_duration_log = noop end
                    if mod.SendTlog then mod.SendTlog = noop end
                    if mod.ReportEvent then mod.ReportEvent = noop end
                    if mod._GetParamData then mod._GetParamData = retEmpty end
                    if mod._IsCanReport then mod._IsCanReport = retFalse end
                    if mod._BatchReqMsg then mod._BatchReqMsg = noop end
                end
            end)
        end
        killBasicReports("_G.BasicDataTLogReport")
        killBasicReports("_G.BasicDataClientReport")
        killBasicReports("_G.BasicDataReport")

        -- ClientTlogHandler, LoginAndWinTlogHandler
        pcall(function()
            local tlogHandler = _G.ClientTlogHandler or package.loaded["client.slua.logic.ClientTlogHandler"]
            if tlogHandler then
                if tlogHandler.send_report_lobby_common_tlog then tlogHandler.send_report_lobby_common_tlog = noop end
            end
            local loginWin = _G.LoginAndWinTlogHandler or package.loaded["client.slua.logic.LoginAndWinTlogHandler"]
            if loginWin then
                if loginWin.on_cloud_game_event_notify then loginWin.on_cloud_game_event_notify = noop end
            end
        end)

        -- tlog_report_utils
        pcall(function()
            local utils = _G.tlog_report_utils or package.loaded["client.slua.config.tlog.tlog_report_utils"]
            if utils then
                if utils.ReportTLogEvent then utils.ReportTLogEvent = noop end
                if utils.ReportImmediate then utils.ReportImmediate = noop end
                if utils.FlushEvents then utils.FlushEvents = noop end
            end
        end)

        -- puffer_tlog (download/ODPAK reports)
        pcall(function()
            local puffer = _G.puffer_tlog or package.loaded["client.slua.logic.download.report.puffer_tlog"]
            if puffer then
                if puffer.report_download_tlog then puffer.report_download_tlog = noop end
                if puffer.ReportEvent then puffer.ReportEvent = noop end
                if puffer.ReportDownloadResult then puffer.ReportDownloadResult = noop end
                if puffer.ReportODPTDError then puffer.ReportODPTDError = noop end
                if puffer.ReportSkinError then puffer.ReportSkinError = noop end
            end
        end)

        -- gem_report_utils / gem_report_config
        pcall(function()
            local gem = _G.gem_report_utils or package.loaded["gem_report_utils"]
            if gem then
                if gem.ReportGemData then gem.ReportGemData = noop end
                if gem.ReportGemPurchase then gem.ReportGemPurchase = noop end
                if gem.ReportEventImmediate then gem.ReportEventImmediate = noop end
                if gem.ReportEventDelay then gem.ReportEventDelay = noop end
            end
            local gemCfg = _G.gem_report_config or package.loaded["gem_report_config"]
            if gemCfg then
                if gemCfg.OnNetworkEvent then gemCfg.OnNetworkEvent = noop end
                if gemCfg.OnBanEvent then gemCfg.OnBanEvent = noop end
            end
        end)

        -- WeekRportHandler
        pcall(function()
            local week = _G.WeekRportHandler or package.loaded["client.slua.logic.report.WeekRportHandler"]
            if week then
                if week.send_week_report then week.send_week_report = noop end
                if week.send_week_detail then week.send_week_detail = noop end
            end
        end)

        -- LobbyPingReportHandler
        pcall(function()
            local ping = _G.LobbyPingReportHandler or package.loaded["client.slua.logic.report.LobbyPingReportHandler"]
            if ping then
                if ping.send_lobby_ping_report then ping.send_lobby_ping_report = noop end
                if ping.send_ingame_ping_report then ping.send_ingame_ping_report = noop end
            end
        end)

        -- ClientTLogManager (main game log manager)
        pcall(function()
            local mgr = package.loaded["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogManager"]
            if mgr then
                if mgr.OnReceiveBattleResults then mgr.OnReceiveBattleResults = noop end
                if mgr.AddValTLog then mgr.AddValTLog = noop end
                if mgr.SetValTLog then mgr.SetValTLog = noop end
                if mgr.SendReportLobby then mgr.SendReportLobby = noop end
                if mgr.ClientTlogData then mgr.ClientTlogData = {} end
                if mgr.OnSendBatchReqMsg then mgr.OnSendBatchReqMsg = noop end
                if mgr.Flush then mgr.Flush = noop end
            end
        end)

        -- GameReportUtils (deep kill)
        pcall(function()
            local gr = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
            if gr then
                if gr.ReportException then gr.ReportException = noop end
                if gr.ReplayReportData then gr.ReplayReportData = noop end
                if gr.ReportGameException then gr.ReportGameException = noop end
                if gr.BugglyPostExceptionFull then gr.BugglyPostExceptionFull = retFalse end
                if gr.CheckCanBugglyPostException then gr.CheckCanBugglyPostException = retFalse end
                if gr.PostException then gr.PostException = noop end
            end
        end)

        -- TLogSubsystem (DS & Borderland)
        pcall(function()
            local tlog = _G.TLogSubsystem or package.loaded["_G.TLogSubsystem"]
            if tlog then
                if tlog.OnInit then tlog.OnInit = noop end
            end
            local borderTlog = package.loaded["GameLua.Mod.Borderland.Gameplay.Subsystem.TLogSubsystem"]
            if borderTlog then
                if borderTlog.OnInit then borderTlog.OnInit = noop end
            end
            local dsfight = package.loaded["GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem"]
            if dsfight then
                if dsfight.ReportFightData then dsfight.ReportFightData = noop end
                if dsfight.ReportPlayerWeapon then dsfight.ReportPlayerWeapon = noop end
                if dsfight.GetSimpleFightData then dsfight.GetSimpleFightData = retEmpty end
            end
            local dssecurity = package.loaded["GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem"]
            if dssecurity then
                if dssecurity._OnReportServerJumpFlow then dssecurity._OnReportServerJumpFlow = noop end
                if dssecurity._OnReportTeleportFlow then dssecurity._OnReportTeleportFlow = noop end
                if dssecurity._OnReportSpeedHackFlow then dssecurity._OnReportSpeedHackFlow = noop end
                if dssecurity.ReportServerJumpFlow then dssecurity.ReportServerJumpFlow = noop end
                if dssecurity.CollectJumpData then dssecurity.CollectJumpData = noop end
            end
            local dscommon = package.loaded["GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem"]
            if dscommon then
                if dscommon.HandleKillTlog then dscommon.HandleKillTlog = noop end
            end
            local ictlog = package.loaded["GameLua.Mod.BaseMod.DS.Security.ICTLogSubsystem"]
            if ictlog then
                if ictlog.SendICExceptionTLog then ictlog.SendICExceptionTLog = noop end
            end
        end)
    end)

    -- ======================================================================
    -- SECTION B : Replay & Spectator Deep Kill (prevent replay upload)
    -- ======================================================================
    pcall(function()
        -- AIReplaySubsystem
        local aireplay = package.loaded["GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem"]
        if aireplay then
            if aireplay.ReportAllPlayerInfo then aireplay.ReportAllPlayerInfo = noop end
            if aireplay.ReportFrameData then aireplay.ReportFrameData = noop end
            if aireplay.ReportPlayerInput then aireplay.ReportPlayerInput = noop end
            if aireplay.uCompletePlayBack then
                aireplay.uCompletePlayBack.AddRecordMLAIInfo = noop
                aireplay.uCompletePlayBack.StopRecording = noop
            end
        end

        -- ClientReplayDataReporter
        local reporter = _G.ClientReplayDataReporter or package.loaded["_G.ClientReplayDataReporter"]
        if reporter then
            if reporter.ReportIntArrayData then reporter.ReportIntArrayData = noop end
            if reporter.ReportFloatArrayData then reporter.ReportFloatArrayData = noop end
            if reporter.ReportUInt8ArrayData then reporter.ReportUInt8ArrayData = noop end
        end

        -- SpectatorAndReplaySubsystem
        local spec = package.loaded["GameLua.Mod.BaseMod.Client.Security.SpectatorAndReplaySubsystem"]
        if spec then
            if spec.SendReport then spec.SendReport = noop end
            if spec.OnSpectatorReplayChanged then spec.OnSpectatorReplayChanged = noop end
        end

        -- ReplayRecordSecurity (meta injection)
        local replaySec = _G.ReplayRecordSecurity or package.loaded["_G.ReplayRecordSecurity"]
        if replaySec then
            if replaySec.InjectMeta then replaySec.InjectMeta = noop end
            if replaySec.Validate then replaySec.Validate = noop end
        end

        -- GameReportSubsystemReporter
        local grr = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportSubsystemReporter"]
        if grr then
            if grr.ReportIntArrayData then grr.ReportIntArrayData = noop end
            if grr.ReportUInt8ArrayData then grr.ReportUInt8ArrayData = noop end
            if grr.ReportFloatArrayData then grr.ReportFloatArrayData = noop end
        end

        -- RescueBtnReplayTraceSubsystem
        local rescue = package.loaded["GameLua.Mod.BaseMod.Client.RescueBtnReplayTraceSubsystem"]
        if rescue then
            if rescue.ReportTrace then rescue.ReportTrace = noop end
            if rescue.StartTickMonitor then rescue.StartTickMonitor = noop end
            if rescue.TickMonitorCheck then rescue.TickMonitorCheck = noop end
            if rescue.ReportTickMonitorHeartbeat then rescue.ReportTickMonitorHeartbeat = noop end
        end
    end)

    -- ======================================================================
    -- SECTION C : Periodic Flag Scrubber (runs every 3 seconds)
    -- ======================================================================
    local function DeepScrubAllFlags()
        pcall(function()
            -- 1. Scrub PlayerController's AntiCheatManager
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) then
                local acm = pc.PlayerAntiCheatManager or pc.AntiCheatManager
                if slua.isValid(acm) then
                    for k, v in pairs(acm) do
                        local t = type(v)
                        if t == "number" then
                            pcall(function() acm[k] = 0 end)
                        elseif t == "boolean" then
                            pcall(function() acm[k] = false end)
                        elseif t == "table" and v.Clear then
                            pcall(function() v:Clear() end)
                        end
                    end
                end

                -- 2. Scrub ServerDataMgr (global)
                local sdm = _G.ServerDataMgr
                if sdm then
                    local keys = {
                        "SuspiciousHitCount", "EspTotalSimTraceCnt", "EspTotalImeFocusCnt",
                        "ClientGravityAnomalyCount", "FireCount", "SpeedCheatCount", "JumpCount",
                        "VehicleSpeedHackCount", "HeadshotCount", "KillCount", "Accuracy",
                        "FlagCount", "TotalFlags", "IsFlagged", "FlaggedByHawkEye",
                        "FlaggedByInspection", "FlagTimestamp", "FlagLevel", "FlagSeverity",
                        "MoveCheatAntiStrategy3TotalCheatTimes", "CheatStateData2TotalCheatTimes",
                        "ServerAccumulateErrorReplay", "ServerMoveCacheCountOver",
                        "ServerMoveCacheCountOver3d", "ServerMoveBurst", "ImpactOtherAfterBurst",
                        "KillOtherAfterBurst", "PickupAfterBurst", "ContinueMoveBurst"
                    }
                    for _, k in ipairs(keys) do
                        if sdm[k] ~= nil then
                            local t = type(sdm[k])
                            if t == "number" then sdm[k] = 0
                            elseif t == "boolean" then sdm[k] = false
                            elseif t == "table" and sdm[k].Clear then pcall(sdm[k].Clear, sdm[k]) end
                        end
                    end
                end

                -- 3. Scrub ClientTLogManager data
                local ctm = package.loaded["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogManager"]
                if ctm and ctm.ClientTlogData then
                    for k, v in pairs(ctm.ClientTlogData) do
                        if type(v) == "number" then ctm.ClientTlogData[k] = 0 end
                        if type(v) == "boolean" then ctm.ClientTlogData[k] = false end
                    end
                    pcall(function() ctm.ClientTlogData = {} end)
                end

                -- 4. Scrub SecurityTlogQueue
                local stq = _G.SecurityTlogQueue or package.loaded["_G.SecurityTlogQueue"]
                if stq then
                    if stq.Flush then stq.Flush = noop end
                    if stq.Add then stq.Add = noop end
                    if stq.Queue then stq.Queue = {} end
                end

                -- 5. Scrub Behavioral counters in PlayerState
                local ps = pc:GetPlayerStateSafety()
                if slua.isValid(ps) then
                    for k, v in pairs(ps) do
                        local t = type(v)
                        if t == "number" and (k:find("Flag") or k:find("Score") or k:find("Count") or k:find("Cheat") or k:find("Suspicious")) then
                            pcall(function() ps[k] = 0 end)
                        end
                    end
                end

                -- 6. Clear _G.AK_Active_Marks_Cache if any (map marker cache)
                if _G.AK_Active_Marks_Cache then
                    for key, entry in pairs(_G.AK_Active_Marks_Cache) do
                        if entry.distMark then
                            pcall(function()
                                if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
                                    InGameMarkTools.ClientRemoveMapMark(entry.distMark)
                                end
                            end)
                        end
                    end
                    _G.AK_Active_Marks_Cache = {}
                end

                -- 7. Reset global flag indicators
                if _G.IsBeingWatched ~= nil then _G.IsBeingWatched = false end
                if _G.IsBeingRecorded ~= nil then _G.IsBeingRecorded = false end
            end
        end)
    end

    -- Set up the scrubber timer (with retry)
    local function InitScrubberTimer()
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) and pc.AddGameTimer then
                pc:AddGameTimer(3.0, true, function()
                    pcall(DeepScrubAllFlags)
                end)
                print("[SERVER-BYPASS] Periodic scrubber active (every 3s).")
            else
                local fb = slua_GameFrontendHUD or Game
                if fb and fb.AddGameTimer then
                    fb:AddGameTimer(2.0, false, InitScrubberTimer)
                end
            end
        end)
    end
    InitScrubberTimer()

    -- ======================================================================
    -- SECTION D : Offline Ban & Storage Interception
    -- ======================================================================
    pcall(function()
        -- logic_ban
        local ban = package.loaded["client.slua.logic.ban.logic_ban"] or require("client.slua.logic.ban.logic_ban")
        if ban then
            if ban.GetBanEndTime then ban.GetBanEndTime = function() return 0 end end
            if ban.IsInBanTime then ban.IsInBanTime = retFalse end
            if ban.CheckBanStatus then ban.CheckBanStatus = retFalse end
            if ban.GetBanReason then ban.GetBanReason = retEmpty end
            if ban.GetBanTime then ban.GetBanTime = retZero end
        end
    end)
    pcall(function()
        -- logic_login_ban
        local loginBan = package.loaded["client.slua.logic.login.logic_login_ban"] or require("client.slua.logic.login.logic_login_ban")
        if loginBan then
            if loginBan.CheckCanLogin then loginBan.CheckCanLogin = retTrue end
            if loginBan.GetBanInfo then loginBan.GetBanInfo = function() return { end_time = 0 } end end
            if loginBan.IsBanned then loginBan.IsBanned = retFalse end
            if loginBan.IsSecurityBan then loginBan.IsSecurityBan = retFalse end
        end
    end)
    pcall(function()
        -- logic_flag_ban
        local flagBan = package.loaded["client.slua.logic.ban.logic_flag_ban"] or require("client.slua.logic.ban.logic_flag_ban")
        if flagBan then
            if flagBan.GetFlagBanEndTime then flagBan.GetFlagBanEndTime = function() return 0 end end
            if flagBan.IsFlagBanned then flagBan.IsFlagBanned = retFalse end
            if flagBan.GetFlagBanDuration then flagBan.GetFlagBanDuration = retZero end
            if flagBan.CheckFlagBan then flagBan.CheckFlagBan = retFalse end
        end
    end)
    pcall(function()
        -- ClientBanLogic
        local cbl = package.loaded["GameLua.Mod.BaseMod.Client.Ban.ClientBanLogic"] or require("GameLua.Mod.BaseMod.Client.Ban.ClientBanLogic")
        if cbl then
            if cbl.OnVoiceBanNotify then cbl.OnVoiceBanNotify = noop end
            if cbl.OnRealTimeVoiceBanNotify then cbl.OnRealTimeVoiceBanNotify = noop end
            if cbl.OnSyncBanInfo then cbl.OnSyncBanInfo = noop end
            if cbl.OnNotifyWarningTips then cbl.OnNotifyWarningTips = noop end
            if cbl.ReqBanInfo then cbl.ReqBanInfo = noop end
            cbl.VoiceBanEndTime = 0
            cbl.bEnableVoiceReport = false
        end
    end)
    pcall(function()
        -- RealTimeBan subsystem
        local rtb = package.loaded["GameLua.Mod.BaseMod.Common.RealTimeBan.RealTimeBan"]
        if rtb then
            if rtb.OnPlayerWithRealTimeBan then rtb.OnPlayerWithRealTimeBan = noop end
            if rtb.ShowAlias then rtb.ShowAlias = noop end
            if rtb.HandleEnterGameModeFightingState then rtb.HandleEnterGameModeFightingState = noop end
            if rtb.GetTipsID then rtb.GetTipsID = retZero end
        end
    end)
    pcall(function()
        -- ban_util
        local bu = _G.ban_util or package.loaded["client.common.ban_util"]
        if bu then
            if bu.CheckBanStatus then bu.CheckBanStatus = retFalse end
            if bu.GetBanTime then bu.GetBanTime = retZero end
            if bu.IsBanForever then bu.IsBanForever = retFalse end
        end
    end)

    -- ======================================================================
    -- SECTION E : Post-Match Data Sanitizer (scrub on match end)
    -- ======================================================================
    pcall(function()
        -- Hook into match end via GameplayCallbacks
        local gc = _G.GameplayCallbacks
        if gc then
            local oldFinished = gc.OnDSPlayerStateChanged
            gc.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
                if InPlayerState and string.find(string.lower(tostring(InPlayerState)), "finished") then
                    pcall(DeepScrubAllFlags)
                    pcall(function()
                        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                        if slua.isValid(pc) then
                            local ps = pc:GetPlayerStateSafety()
                            if slua.isValid(ps) then
                                for k, v in pairs(ps) do
                                    if type(v) == "number" and (k:find("Score") or k:find("Count") or k:find("Kill") or k:find("Accuracy") or k:find("Flag")) then
                                        pcall(function() ps[k] = 0 end)
                                    end
                                end
                            end
                            if pc.BattleResultUploader then pc.BattleResultUploader.Upload = noop end
                        end
                    end)
                    print("[SERVER-BYPASS] Post-match scrub executed.")
                end
                if oldFinished then oldFinished(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
            end
        end
    end)

    -- ======================================================================
    -- SECTION F : Redundant Security System Kills (belt & suspenders)
    -- ======================================================================
    pcall(function()
        -- TssSdk – kill every possible method
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            local funcs = {
                "GetSdkAntiData", "GameScreenshot", "GameScreenshot2", "IsEmulator",
                "QueryOpts", "GetCommLibValueByKey", "GetShellDyMagicCode", "AddMTCJTask",
                "SetToken", "EnableDisableItem", "InvokeCrashFromShell", "ReInitMrpcs",
                "GetUserTag", "QueryTssLibcAddr", "RegistLibcSendListener", "RegistLibcRecvListener",
                "RegistLibcConnectListener", "RegistLibcCloseListener", "GetMrpcsData2Ptr",
                "GetTPChannelVer", "SetGameChannelIp", "SetValueByKey", "SetChannelHost",
                "SetChannelBuiltinIp", "RecvSecSignature", "PushAntiData3", "QueryRemainsAntiDataCount",
                "GetAntiData3", "DelAntiData3", "SetSecToken", "GetThreadsInfo", "AddTouchEvent",
                "InitSwitchStr", "SetCDNHost", "SetEnabledConnector", "QueryHookInfo", "SetCSLicense",
                "AddAnoTouchEvent", "GetObjVMFuncAddr", "ScanMemory", "ScanSo", "ScanFile",
                "GetRiskFlag", "VerifyFileHash", "CheckKernel", "VerifyBoot", "GetAntiDataQueue",
                "ReportAntiData", "SendAntiData", "ReportSdkData", "SendSdkData", "OnRecvData",
                "Init", "Start", "Verify", "CheckIntegrity", "Check", "SendReportInfo", "ScanMemory",
                "IsEmulator", "GetTssSdkReportInfo", "CheckEnvironment", "VerifyProcess"
            }
            for _, fn in ipairs(funcs) do
                if TssSdk[fn] then pcall(function() TssSdk[fn] = noop end) end
            end
            if TssSdk.antiDataQueue then
                TssSdk.antiDataQueue = {}
                TssSdk.antiDataQueue.push = noop
                TssSdk.antiDataQueue.pop = function() return nil end
                TssSdk.antiDataQueue.size = retZero
                TssSdk.antiDataQueue.clear = noop
            end
        end
    end)

    pcall(function()
        -- HiggsBosonComponent – wipe internal queues
        local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
        if Higgs then
            local methods = {
                "ControlMHActive", "Tick", "OnTick", "MHActiveLogic", "TriggerAvatarCheck",
                "StartAvatarCheck", "ReportItemID", "ReceiveAnyDamage", "OnWeaponHitRecord",
                "ShowSecurityAlert", "ServerReportAvatar", "ClientReportNetAvatar", "SendHisarData",
                "ValidateSecurityData", "StaticShowSecurityAlertInDev", "RPC_Client_ShootVertifyRes",
                "RPC_Server_ReportSimulateCharacterLocation", "DisableHiggsBoson", "CheckMHActive",
                "ReportViolation", "ProcessSecurityEvent", "ValidatePlayer", "CheckIntegrity"
            }
            for _, m in ipairs(methods) do
                if Higgs[m] then pcall(function() Higgs[m] = noop end) end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty
            Higgs.GetCurWeaponSkinID = retZero
            Higgs.IsMHActive = retFalse
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
            if Higgs.BlackList then for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end end
        end
    end)

    pcall(function()
        -- GameSafeCallbacks – kill all
        local gsc = _G.GameSafeCallbacks or package.loaded["_G.GameSafeCallbacks"]
        if gsc then
            local methods = {
                "PostPlayerControllerLoginInit", "OnDSGlueHiaInit", "CharacterReceiveBeginPlay",
                "DoAttackFlowStrategy", "RecordStrategyTimestampInReplay", "EditorIncreaseTotalStatisticCnt"
            }
            for _, m in ipairs(methods) do
                if gsc[m] then pcall(function() gsc[m] = noop end) end
            end
            if gsc.GetScriptReportContent then gsc.GetScriptReportContent = retEmptyString end
        end
    end)

    pcall(function()
        -- SecurityCommonUtils – zero strategy counters
        local scu = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"]
        if scu and scu.EStrategyTypeInReplay then
            scu.EStrategyTypeInReplay.EspTotalSimTraceCnt = 0
            scu.EStrategyTypeInReplay.EspTotalImeFocusCnt = 0
            scu.EStrategyTypeInReplay.ClientGravityAnomalyCount = 0
            scu.EStrategyTypeInReplay.FlyingErrorCnt = 0
        end
    end)

    -- ======================================================================
    -- SECTION G : Network & RPC Filters (block security packets)
    -- ======================================================================
    pcall(function()
        local net = _G.NetUtil or package.loaded["_G.NetUtil"]
        if net and net.SendPacket then
            local origSendPacket = net.SendPacket
            local blockedPackets = {
                -- Report flows
                "ReportAttackFlow", "ReportSecAttackFlow", "ReportHurtFlow",
                "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow",
                "ReportPlayerBehavior", "ReportTeammatHurt", "ReportPlayerMoveRoute",
                "ReportPlayerPosition", "ReportSecVehicleMoveFlow", "report_parachute_data",
                "on_tss_sdk_anti_data", "ReportAimFlow", "ReportHitFlow",
                "ReportCircleFlow", "report_players_ping", "report_player_ip",
                "report_net_saturate", "report_speed_hack", "report_wall_hack",
                "report_aim_bot", "report_esp_usage", "report_modded_files",
                "detect_cheat", "ban_player", "client_anti_cheat_report",
                "ReportPlayerKillFlow", "ClientSecPlayerKillFlow",
                "ReportMrpcsFlow", "ClientSecMrpcsFlow", "MrpcsData",
                "CheckReportSecAttackFlow", "CheckReportSecAttackFlowWithAttackFlow",
                "RPC_ClientCoronaLab", "CoronaLabReport", "CoronaLabData",
                "PlayerSecurityInfo", "ReportSecurityInfo", "SendSecurityData",
                "ClientCircleFlow", "IsEnableReportPlayerKillFlow",
                "IsEnableReportMrpcsInCircleFlow", "IsEnableReportMrpcsInPartCircleFlow",
                "bReportedModifierException", "ReportModifierException",
                "RPC_Server_ReportSimulateCharacterLocation", "ReportSimulateCharacterLocation",
                "RPC_Client_ShootVertifyRes", "BulletHitInfoUploadData",
                "ShootVerifyFailed", "report_unrealnet_exception", "tss_sdk_report",
                "Heartbeat", "ClientHeartbeat", "ServerHeartbeat",
                "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams",
                "SwiftHawkReport", "SwiftHawkData",
                "AntiCheatReport", "CheatDetection", "ViolationReport",
                "SecurityViolation", "IntegrityCheck", "SignatureVerify",
                "inspection_system_report_to_inspector",
                "ingame_voice_ban_notify",
                "inspection_system_notify_inspector"
            }
            net.SendPacket = function(packetName, ...)
                for _, blocked in ipairs(blockedPackets) do
                    if packetName == blocked then return nil end
                end
                return origSendPacket(packetName, ...)
            end
        end
    end)

    pcall(function()
        -- Block specific RPCs
        if _G.SendRPC then
            local origSendRPC = _G.SendRPC
            local blockedRPCs = {
                "RPC_Server_ReportPlayerKillFlow", "RPC_Server_ClientSecMrpcsFlow",
                "RPC_Server_Heartbeat", "RPC_Server_SwiftHawk", "RPC_Server_ClientSwiftHawkWithParams",
                "RPC_Server_ReportSimulateCharacterLocation", "RPC_Client_ShootVertifyRes",
                "RPC_ClientCoronaLab", "RPC_Server_HawkReportCheat"
            }
            _G.SendRPC = function(rpcName, ...)
                for _, blocked in ipairs(blockedRPCs) do
                    if rpcName == blocked then return nil end
                end
                return origSendRPC(rpcName, ...)
            end
        end
    end)

    -- ======================================================================
    -- SECTION H : Device Fingerprint Spoofing
    -- ======================================================================
    pcall(function()
        local DeviceInfo = _G.DeviceInfo or package.loaded["_G.DeviceInfo"]
        if DeviceInfo then
            if DeviceInfo.GetDeviceID then DeviceInfo.GetDeviceID = function() return "unknown_" .. tostring(os.time()) end end
            if DeviceInfo.GetIMEI then DeviceInfo.GetIMEI = function() return "000000000000000" end end
            if DeviceInfo.CollectSysInfo then DeviceInfo.CollectSysInfo = noop end
        end
    end)
    pcall(function()
        local DeviceFingerprint = package.loaded["GameLua.Mod.BaseMod.Client.Security.DeviceFingerprint"]
        if DeviceFingerprint then
            if DeviceFingerprint.Collect then DeviceFingerprint.Collect = noop end
            if DeviceFingerprint.Sync then DeviceFingerprint.Sync = noop end
            if DeviceFingerprint.GetHash then DeviceFingerprint.GetHash = function() return "unknown_" .. tostring(os.time()) end end
        end
    end)
    pcall(function()
        local TDataMaster = _G.TDataMaster or package.loaded["_G.TDataMaster"]
        if TDataMaster then
            if TDataMaster.Report then TDataMaster.Report = noop end
            if TDataMaster.ReportDeviceInfo then TDataMaster.ReportDeviceInfo = noop end
            if TDataMaster.SendHardwareHash then TDataMaster.SendHardwareHash = noop end
            if TDataMaster.CollectTelemetry then TDataMaster.CollectTelemetry = noop end
            if TDataMaster.SendData then TDataMaster.SendData = noop end
            if TDataMaster.Sync then TDataMaster.Sync = noop end
            if TDataMaster.Flush then TDataMaster.Flush = noop end
            for k, v in pairs(TDataMaster) do
                if type(v) == "function" then pcall(function() TDataMaster[k] = noop end) end
            end
        end
    end)

    -- ======================================================================
    -- SECTION I : Nuclear Sweep for Unknown / Newer Modules
    -- ======================================================================
    pcall(function()
        -- Iterate over _G and kill any security/report/tlog/ban modules
        local targets = {}
        for k, v in pairs(_G) do
            if type(v) == "table" and type(k) == "string" then
                local lk = k:lower()
                if lk:find("anticheat") or lk:find("security") or lk:find("report") or
                   lk:find("tlog") or lk:find("ban") or lk:find("flag") or
                   lk:find("punish") or lk:find("cheat") or lk:find("detect") or
                   lk:find("hawk") or lk:find("inspector") then
                    table.insert(targets, {name = k, table = v})
                end
            end
        end
        for _, entry in ipairs(targets) do
            local t = entry.table
            for fk, fv in pairs(t) do
                if type(fv) == "function" and type(fk) == "string" then
                    local lfk = fk:lower()
                    if lfk:find("report") or lfk:find("send") or lfk:find("sync") or
                       lfk:find("upload") or lfk:find("verify") or lfk:find("check") or
                       lfk:find("collect") or lfk:find("record") or lfk:find("flush") or
                       lfk:find("notify") or lfk:find("ban") or lfk:find("flag") or
                       lfk:find("punish") then
                        pcall(function() t[fk] = noop end)
                    end
                end
            end
        end
    end)

    -- ======================================================================
    -- SECTION J : Popup / Message Box Ban Suppression
    -- ======================================================================
    pcall(function()
        local msgBox = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
        if msgBox and msgBox.Show then
            local oldShow = msgBox.Show
            msgBox.Show = function(self, msgType, title, content, callback)
                local titleStr = type(title) == "string" and title:lower() or ""
                local contentStr = type(content) == "string" and content:lower() or ""
                if titleStr:find("ban") or titleStr:find("punish") or titleStr:find("suspend") or
                   titleStr:find("security") or titleStr:find("account") or
                   contentStr:find("ban") or contentStr:find("punish") or contentStr:find("suspend") or
                   contentStr:find("cheat detected") or contentStr:find("account restricted") then
                    print("[SERVER-BYPASS] Blocked ban popup: " .. tostring(title))
                    return
                end
                return oldShow(self, msgType, title, content, callback)
            end
        end
    end)
    pcall(function()
        local legal = package.loaded["client.slua.logic.common.logic_common_legal_msg"] or require("client.slua.logic.common.logic_common_legal_msg")
        if legal and legal.ShowOnePopUI then
            local old = legal.ShowOnePopUI
            legal.ShowOnePopUI = function(self, params)
                if params and params.title then
                    local t = params.title:lower()
                    if t:find("ban") or t:find("punish") or t:find("suspend") or t:find("account") then
                        print("[SERVER-BYPASS] Blocked legal popup: " .. params.title)
                        return
                    end
                end
                return old(self, params)
            end
        end
    end)

    -- ======================================================================
    -- SECTION K : libanlogs String Blocking (specific patterns)
    -- ======================================================================
    pcall(function()
        -- These are known strings that trigger detection in libanlogs.so
        local blockedStrings = {
            "TssSdk", "HawkEye", "ReportAttackFlow", "ReportSecAttackFlow",
            "SecurityTlogQueue", "AntiCheatSubsystem", "HiggsBosonComponent",
            "ClientHawkEyePatrol", "CoronaLab", "PlayerSecurityInfo",
            "InspectionSystem", "RealTimeBan", "BanLogic", "FlagSubsystem",
            "SwiftHawk", "BehaviorScore", "ShootVerify", "MrpcsFlow",
            "ClientBanLogic", "DSReportPlayer", "ClientReportPlayer",
            "Gokuba", "HostedProto", "DeviceFingerprint", "TDataMaster",
            "ServerDataMgr", "DSSecurity", "DSAITLog", "AFKReportor",
            "RacingAntiCheat", "HighlightMoment", "VoiceReport",
            "BugglyReportRecord", "PatrollerModule", "EmulatorSystem",
            "BanMacro", "NGActionBan", "InputVariance", "SpeedhackValidator",
            "InspectionSystemKickPlayer", "ban_reddot", "gem_report",
            "UGCNewTLogReport", "logic_ugc_tlog", "ClientTLogUtil",
            "ReportCrashKitFeature", "GameReportSubsystemReporter",
            "GameReportUtils", "PakIntegrityChecker", "LuaIntegrityCheck",
            "APKIntegrity", "SecureBootCheck", "DeviceCheckSubsystem",
            "SpectatorAndReplay", "ReplayRecordSecurity", "PufferDownloadReport",
            "ClientAppStat", "LoginVerify", "DSDeviceCheck", "AntiDebug",
            "LibCheck", "CoronaUploader", "SecurityNotifyPCFeature"
        }
        -- Global function scanner: if any function name contains blockedString, kill it
        for _, pattern in ipairs(blockedStrings) do
            for k, v in pairs(_G) do
                if type(k) == "string" and k:find(pattern) and type(v) == "function" then
                    pcall(function() _G[k] = noop end)
                end
                if type(v) == "table" then
                    for fk, fv in pairs(v) do
                        if type(fk) == "string" and fk:find(pattern) and type(fv) == "function" then
                            pcall(function() v[fk] = noop end)
                        end
                    end
                end
            end
        end
        -- Also scan package.loaded
        for name, mod in pairs(package.loaded) do
            if type(mod) == "table" then
                for fk, fv in pairs(mod) do
                    if type(fk) == "string" and type(fv) == "function" then
                        for _, pattern in ipairs(blockedStrings) do
                            if fk:find(pattern) then
                                pcall(function() mod[fk] = noop end)
                            end
                        end
                    end
                end
            end
        end
    end)

    -- ======================================================================
    -- SECTION L : Retroactive Patch for Already-Loaded Modules (from modulePatches)
    -- ======================================================================
    pcall(function()
        -- If modulePatches exists in the global scope, apply it to already-loaded modules
        if _G.modulePatches then
            for name, cfg in pairs(_G.modulePatches) do
                local mod = package.loaded[name]
                if mod then
                    if cfg.custom then pcall(cfg.custom, mod)
                    elseif not cfg.global then
                        if cfg.methods then for k, v in pairs(cfg.methods) do if type(mod[k]) == "function" then mod[k] = v end end end
                        if cfg.retvals then for k, v in pairs(cfg.retvals) do if type(mod[k]) == "function" then mod[k] = v end end end
                        if cfg.fields then for k, v in pairs(cfg.fields) do if mod[k] ~= nil then mod[k] = v end end end
                    end
                end
            end
        end
    end)

    -- Mark as initialized
    _G._SERVER_BYPASS_INIT = true
    print("[SERVER-BYPASS] Server-side and log protection fully active.")
end

-- ================================================================
--  GLOBAL HACK FUNCTIONS (defined before timers)
-- ================================================================

-- ================================================================
--  ESP / WALLHACK / MAP MARKERS
-- ================================================================
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
local cachedPawns = {}
local lastPawnRefresh = 0

local function IsPawnAlive(p)
    if not isValid(p) then return false end
    if p.HealthStatus then return SecurityCommonUtils.IsHealthStatusAlive(p.HealthStatus) end
    if p.IsAlive then return p:IsAlive() end
    return p.GetHealth and (p:GetHealth() or 0) > 0 or false
end

local function TextScale(distM)
    local t = math.min(distM / 400, 1)
    return 0.35 - t * 0.2
end

local function HPBar(pct)
    local n = math.floor((pct * 4) + 0.5)
    local s = ""
    for i = 1, 4 do s = s .. (i <= n and "▁" or " ") end
    return s
end

_G.AK_Active_Marks_Cache = _G.AK_Active_Marks_Cache or {}

local function AddMapMark(actor)
    if not slua.isValid(actor) then return end
    pcall(function()
        if not InGameMarkTools then return end
        if not InGameMarkTools.ClientAddMapMark then return end
        local loc = actor:K2_GetActorLocation() or FVector(0,0,0)
        local markType = 9999
        local markId = InGameMarkTools.ClientAddMapMark(markType, loc, 0, "", 4, actor)
        if markId then
            actor.NativeDistMark = markId
            actor._AK_MarkLastLoc = loc
            _G.AK_Active_Marks_Cache[tostring(actor)] = { actor = actor, distMark = markId, lastLoc = loc }
        end
    end)
end

local function RemoveMapMark(actor)
    if not slua.isValid(actor) then return end
    pcall(function()
        if not InGameMarkTools then return end
        if InGameMarkTools.ClientRemoveMapMark and actor.NativeDistMark then
            InGameMarkTools.ClientRemoveMapMark(actor.NativeDistMark)
        elseif InGameMarkTools.HideMapMark and actor.NativeDistMark then
            InGameMarkTools.HideMapMark(actor.NativeDistMark)
        end
        actor.NativeDistMark = nil
        actor._AK_MarkLastLoc = nil
        actor.bHasAKNativeMapMarker = false
        _G.AK_Active_Marks_Cache[tostring(actor)] = nil
    end)
end

local function UpdateMarkLocation(actor)
    if not slua.isValid(actor) then return end
    if not actor.NativeDistMark then return end
    if not InGameMarkTools then return end
    pcall(function()
        local newLoc = actor:K2_GetActorLocation()
        if not newLoc then return end
        local lastLoc = actor._AK_MarkLastLoc
        if lastLoc then
            local dx = newLoc.X - lastLoc.X
            local dy = newLoc.Y - lastLoc.Y
            local dz = newLoc.Z - lastLoc.Z
            local moved = math.sqrt(dx*dx + dy*dy + dz*dz)
            if moved < 100 then return end
        end
        if InGameMarkTools.ClientUpdateMapMark then
            InGameMarkTools.ClientUpdateMapMark(actor.NativeDistMark, newLoc)
            actor._AK_MarkLastLoc = newLoc
            return
        end
        if InGameMarkTools.ClientRemoveMapMark then
            InGameMarkTools.ClientRemoveMapMark(actor.NativeDistMark)
            local markId = InGameMarkTools.ClientAddMapMark(9999, newLoc, 0, "", 4, actor)
            if markId then
                actor.NativeDistMark = markId
                actor._AK_MarkLastLoc = newLoc
                local cache = _G.AK_Active_Marks_Cache[tostring(actor)]
                if cache then cache.distMark = markId end
            end
        end
    end)
end

local function CleanupDeadMarks()
    for key, entry in pairs(_G.AK_Active_Marks_Cache) do
        local actor = entry.actor
        if not slua.isValid(actor) then
            pcall(function()
                if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark and entry.distMark then
                    InGameMarkTools.ClientRemoveMapMark(entry.distMark)
                end
            end)
            _G.AK_Active_Marks_Cache[key] = nil
            goto continue
        end
        local isDead = false
        pcall(function()
            if actor.bHidden or (actor.Mesh and actor.Mesh.bHidden) then
                isDead = true
            elseif type(actor.IsDead) == "function" and actor:IsDead() then
                isDead = true
            elseif actor.bIsDead == true or actor.bIsDeadFlag == true then
                isDead = true
            elseif actor.Health and actor.Health <= 0 then
                isDead = true
            end
        end)
        if isDead then
            pcall(function()
                if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark and entry.distMark then
                    InGameMarkTools.ClientRemoveMapMark(entry.distMark)
                end
            end)
            actor.NativeDistMark = nil
            actor._AK_MarkLastLoc = nil
            actor.bHasAKNativeMapMarker = false
            _G.AK_Active_Marks_Cache[key] = nil
        end
        ::continue::
    end
end

local function UpdateEnemyMapMark(enemy, localPlayer, enable)
    if not slua.isValid(enemy) then return end
    if enemy == localPlayer then return end
    if enemy.TeamID == localPlayer.TeamID then return end
    local isDead = false
    pcall(function()
        if type(enemy.IsDead) == "function" then isDead = enemy:IsDead()
        elseif enemy.bIsDead then isDead = true end
        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end
        if enemy.Health and enemy.Health <= 0 then isDead = true end
    end)
    if isDead then
        if enemy.bHasAKNativeMapMarker then RemoveMapMark(enemy) end
        return
    end
    if enable == 1 then
        if not enemy.bHasAKNativeMapMarker then
            AddMapMark(enemy)
            enemy.bHasAKNativeMapMarker = true
        else
            UpdateMarkLocation(enemy)
        end
    else
        if enemy.bHasAKNativeMapMarker then RemoveMapMark(enemy) end
    end
end

_G.ESPTick = function()
    if not _G.CheatsEnabled then return end
    if not _G.Mod_ESP_Enabled then return end
    local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not (isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
    local currentPawn = uCon:GetCurPawn()
    if not isValid(currentPawn) then return end
    local myTeamId = 0
    pcall(function()
        local char = uCon:GetPlayerCharacterSafety()
        if isValid(char) and char.TeamID then myTeamId = char.TeamID
        elseif currentPawn.TeamID then myTeamId = currentPawn.TeamID end
    end)
    local myPos = nil
    pcall(function() myPos = currentPawn:K2_GetActorLocation() end)
    if not myPos then return end
    local myEyePos = myPos
    pcall(function()
        if currentPawn.GetHeadLocation then myEyePos = currentPawn:GetHeadLocation(false) or myPos end
    end)
    local HUD = uCon:GetHUD()
    local now = os.time()
    if now - lastPawnRefresh > 1.0 then
        lastPawnRefresh = now
        cachedPawns = Game:GetAllPlayerPawns() or {}
    end
    local botCount = 0
    local playerCount = 0
    for _, tPawn in pairs(cachedPawns) do
        if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
            if IsPawnAlive(tPawn) then
                UpdateEnemyMapMark(tPawn, currentPawn, 1)
                local enemyPos = tPawn:K2_GetActorLocation()
                local dx = enemyPos.X - myPos.X
                local dy = enemyPos.Y - myPos.Y
                local dz = enemyPos.Z - myPos.Z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                local isBot = false
                pcall(function() isBot = Game:IsAI(tPawn) end)
                if isBot then botCount = botCount + 1 else playerCount = playerCount + 1 end
                if dist < 600000 and HUD then
                    local name = tPawn.PlayerName or "UNKNOWN"
                    local distM = dist / 100
                    local hp = tPawn.Health
                    local maxHp = tPawn.HealthMax
                    local isKnock = false
                    local hpPercent = 0
                    if not hp or not maxHp or maxHp <= 0 then
                        isKnock = true
                    elseif hp <= 0 then
                        isKnock = true
                    else
                        hpPercent = hp / maxHp
                    end
                    local hpColor = {R=0,G=255,B=0,A=255}
                    if hpPercent < 0.3 then
                        hpColor = {R=255,G=0,B=0,A=255}
                    elseif hpPercent < 0.7 then
                        hpColor = {R=255,G=255,B=0,A=255}
                    end
                    if isKnock then
                        hpColor = {R=255,G=0,B=0,A=255}
                    end
                    local mesh = tPawn.Mesh
                    local headPos = nil
                    if isValid(mesh) then
                        headPos = mesh:GetSocketLocation("head")
                    end
                    local origin = enemyPos
                    local oz = origin.Z
                    if not headPos then
                        headPos = FVector(enemyPos.X, enemyPos.Y, enemyPos.Z + 90)
                    end
                    local headZ = headPos and (headPos.Z - oz) or 90
                    local hpOffset = headZ + 70 + 50 + math.min(distM, 60) * 3 + math.max(0, distM - 60) * 0.5
                    local nameOffset = -80 - 50 - math.min(distM, 60) * 0.33 - math.max(0, distM - 60) * 0.1
                    local hpText = isKnock and "DOWN" or HPBar(hpPercent)
                    HUD:AddDebugText(hpText, tPawn, TextScale(distM), {X=0,Y=0,Z=hpOffset}, {X=0,Y=0,Z=hpOffset}, hpColor, true, false, true, nil, 1.0, true)
                    local nameColor = {R=255,G=255,B=0,A=255}
                    local targetPos = headPos or tPawn:K2_GetActorLocation()
                    pcall(function()
                        if Game:IsTargetPosVisible(myEyePos, targetPos, {currentPawn}) then
                            nameColor = {R=255,G=255,B=0,A=255}
                        else
                            nameColor = {R=255,G=0,B=0,A=255}
                        end
                    end)
                    HUD:AddDebugText(string.format("[%.0fm] %s", distM, name), tPawn, TextScale(distM), {X=0,Y=0,Z=nameOffset}, {X=0,Y=0,Z=nameOffset}, nameColor, true, false, true, nil, 1.0, true)
                end
            else
                UpdateEnemyMapMark(tPawn, currentPawn, 0)
            end
        end
    end
    CleanupDeadMarks()
    -- Vehicle ESP
    pcall(function()
        if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
        if not _G.CachedActorClass_ForVehicle then _G.CachedActorClass_ForVehicle = import("STExtraVehicleBase") end
        if not _G.CachedVehicleArray then _G.CachedVehicleArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForVehicle) end
        
        local ui_util = require("client.common.ui_util")
        local gameInstance = ui_util and ui_util.GetGameInstance()
        
        if gameInstance and _G.CachedGameplayStatics then
            local curTime = os.clock()
            if not _G.LastVehicleScanTime or (curTime - _G.LastVehicleScanTime) > 1.0 then
                _G.LastVehicleScanTime = curTime
                local allVehicles = _G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance, _G.CachedActorClass_ForVehicle, _G.CachedVehicleArray)
                local activeVehicles = {}
                if allVehicles then
                    for _, veh in pairs(allVehicles) do
                        if slua.isValid(veh) and not veh.bHidden and not veh.bTearOff then
                            local isPendingKill = false
                            pcall(function() if type(veh.IsPendingKill) == "function" then isPendingKill = veh:IsPendingKill() end end)
                            if not isPendingKill then
                                local vehName = "Vehicle"
                                local hasDriver = false
                                local hpStr = ""
                                pcall(function()
                                    if type(veh.GetVehicleName) == "function" then vehName = veh:GetVehicleName() elseif veh.VehicleName then vehName = veh.VehicleName end
                                    local driver = type(veh.GetDriver) == "function" and veh:GetDriver() or nil
                                    if slua.isValid(driver) then hasDriver = true end
                                    local hp = veh.HP or (type(veh.GetHP) == "function" and veh:GetHP()) or 100
                                    local maxHp = veh.HPMax or (type(veh.GetHPMax) == "function" and veh:GetHPMax()) or 100
                                    if maxHp > 0 then hpStr = string.format(" [%d%%]", math.floor((hp/maxHp)*100)) end
                                end)
                                local nameLower = string.lower(tostring(vehName) .. tostring(veh))
                                local displayName = "Vehicle"
                                if string.find(nameLower, "uaz") then displayName = "UAZ"
                                elseif string.find(nameLower, "dacia") then displayName = "Dacia"
                                elseif string.find(nameLower, "buggy") then displayName = "Buggy"
                                elseif string.find(nameLower, "mirado") then displayName = "Mirado"
                                elseif string.find(nameLower, "bike") or string.find(nameLower, "motor") then displayName = "Motor"
                                elseif string.find(nameLower, "scooter") then displayName = "Scooter"
                                elseif string.find(nameLower, "coupe") then displayName = "Coupe RB"
                                elseif string.find(nameLower, "brdm") then displayName = "BRDM"
                                elseif string.find(nameLower, "boat") or string.find(nameLower, "aquarail") then displayName = "Boat"
                                elseif string.find(nameLower, "glider") then displayName = "Glider"
                                else displayName = "Vehicle (" .. string.sub(vehName, 1, 8) .. ")" end
                                table.insert(activeVehicles, {act = veh, name = displayName, hasDriver = hasDriver, hpStr = hpStr})
                            end
                        end
                    end
                end
                _G.CachedVehicles = activeVehicles
            end

            if _G.CachedVehicles then
                for _, item in ipairs(_G.CachedVehicles) do
                    local veh = item.act
                    if slua.isValid(veh) and not veh.bHidden then
                        local distM = 0
                        pcall(function() distM = currentPawn:GetDistanceTo(veh) / 100 end)
                        if distM > 0 and distM <= 300 then
                            local text = string.format("%s%s [%dm]", item.name, item.hpStr, math.floor(distM))
                            local vehColor = item.hasDriver and {R=255, G=50, B=50, A=255} or {R=0, G=255, B=150, A=255}
                            local dynamicScale = math.max(0.6, 1.1 - (distM / 500))
                            HUD:AddDebugText(text, veh, 0.06, {X=0, Y=0, Z=50}, {X=0, Y=0, Z=50}, vehColor, true, false, true, nil, dynamicScale, true)
                        end
                    end
                end
            end
        end
    end)

    if HUD and currentPawn then
        HUD:AddDebugText(string.format("BOT : %d     PLAYER : %d", botCount, playerCount), currentPawn, 1, {X=0,Y=0,Z=60}, {X=0,Y=0,Z=60}, {R=255,G=255,B=255,A=255}, true, false, true, nil, 1.0, true)
        HUD:AddDebugText("AnuragXcat", currentPawn, 1, {X=0,Y=0,Z=55}, {X=0,Y=0,Z=55}, {R=255,G=200,B=0,A=255}, true, false, true, nil, 1.0, true)
    end
end

-- ================================================================

-- ================================================================
--  STANDALONE MAP MARKER (Independent of ESP)
-- ================================================================
_G.MapMarkerTick = function()
    if not _G.CheatsEnabled then return end
    if not _G.Mod_MapMarker_Enabled then return end

    local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not (isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
    local currentPawn = uCon:GetCurPawn()
    if not isValid(currentPawn) then return end

    local myTeamId = 0
    pcall(function()
        local char = uCon:GetPlayerCharacterSafety()
        if isValid(char) and char.TeamID then myTeamId = char.TeamID
        elseif currentPawn.TeamID then myTeamId = currentPawn.TeamID end
    end)

    local cachedPawns = Game:GetAllPlayerPawns() or {}
    for _, tPawn in pairs(cachedPawns) do
        if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
            local isDead = false
            pcall(function()
                if type(tPawn.IsDead) == "function" then isDead = tPawn:IsDead()
                elseif tPawn.bIsDead then isDead = true end
                if tPawn.bHidden or (tPawn.Mesh and tPawn.Mesh.bHidden) then isDead = true end
                if tPawn.Health and tPawn.Health <= 0 then isDead = true end
            end)
            if not isDead then
                UpdateEnemyMapMark(tPawn, currentPawn, 1)
            else
                UpdateEnemyMapMark(tPawn, currentPawn, 0)
            end
        end
    end
    CleanupDeadMarks()
end


--  BRUTAL BULLET TRACK (global)
-- ================================================================
_G.BrutalTrack = {
    Enabled = true,
    BodyPart = 0,
    Distance = 99999999,
    FOV = 100,
    MinDistance = 50,
    TrackBots = true,
    TrackDowned = true,
}

local BONE_MAP = {
    [0] = "Head",
    [1] = "neck_01",
    [2] = "spine_03",
}

local cachedEnemies = {}
local lastEnemyRefresh = 0

local function GetEnemyTargets(radius, forceRefresh)
    local now = os.clock()
    if not forceRefresh and now - lastEnemyRefresh < 0.1 then
        local validCache = {}
        for _, e in ipairs(cachedEnemies) do
            if slua.isValid(e) then table.insert(validCache, e) end
        end
        cachedEnemies = validCache
        return cachedEnemies
    end
    local result = {}
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return result end
    local uPlayerController = player:GetPlayerControllerSafety()
    if not slua.isValid(uPlayerController) then return result end
    local ASTExtraPlayerCharacter = import("STExtraPlayerCharacter")
    if not ASTExtraPlayerCharacter then return result end
    local Actors = nil
    pcall(function() Actors = Game:GetActorsByClass(ASTExtraPlayerCharacter) end)
    if not Actors then return result end
    local count = 0
    pcall(function() count = Actors:Num() or 0 end)
    local myTeam = 0
    pcall(function() myTeam = player:GetTeamID() end)
    for i = 0, count - 1 do
        local actor = nil
        pcall(function() actor = Actors:Get(i) end)
        if slua.isValid(actor) and actor ~= player then
            local isEnemy = false
            pcall(function()
                if actor.GetTeamID and actor:GetTeamID() ~= myTeam and actor:IsAlive() then
                    isEnemy = true
                end
            end)
            if isEnemy then
                local dist = radius + 1
                pcall(function() dist = player:GetDistanceTo(actor) end)
                if dist <= radius then
                    table.insert(result, actor)
                end
            end
        end
    end
    cachedEnemies = result
    lastEnemyRefresh = now
    return result
end

_G._LastTrackedWeapon = _G._LastTrackedWeapon or {}
_G._LastTrackedShootId = _G._LastTrackedShootId or {}

_G.BrutalBulletTrack = function()
    if not _G.BrutalTrack.Enabled then return end
    if not _G.Mod_BulletTrack_Enabled then return end

    -- Auto-reset caches every 5 minutes to prevent stale-data death
    local now = os.clock()
    if not _G._LastTrackResetTime then _G._LastTrackResetTime = now end
    if now < _G._LastTrackResetTime then _G._LastTrackResetTime = now end
    if now - _G._LastTrackResetTime > 300 then
        _G._LastTrackedWeapon = {}
        cachedEnemies = {}
        lastEnemyRefresh = 0
        _G._LastTrackResetTime = now
    end

    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    local pc = player:GetPlayerControllerSafety()
    if not slua.isValid(pc) then return end
    local wm = player.WeaponManagerComponent
    if not wm then return end
    local currentWeapon = wm.CurrentWeaponReplicated
    if not slua.isValid(currentWeapon) then return end

    local shootComp = currentWeapon.ShootWeaponComponent
    if not slua.isValid(shootComp) then
        shootComp = currentWeapon.ShootWeaponEntityComp
    end
    if not slua.isValid(shootComp) then
        shootComp = currentWeapon.ShootWeaponEntityComponent
    end
    if not slua.isValid(shootComp) then return end

    local shootId = 0
    pcall(function()
        shootId = shootComp.CurShootID or shootComp.CurShootId or 0
    end)
    if shootId == 0 then return end

    local weaponKey = tostring(currentWeapon)

    -- Migrate old number-format cache to table format
    local lastEntry = _G._LastTrackedWeapon[weaponKey]
    if type(lastEntry) == "number" then
        lastEntry = {id = lastEntry, time = now}
        _G._LastTrackedWeapon[weaponKey] = lastEntry
    end
    if lastEntry and lastEntry.id == shootId then
        return
    end

    local maxDistCm = _G.Mod_BulletTrack_MaxDistance or 99999999
    if maxDistCm < 1000 then maxDistCm = 1000 end
    local minDistCm = (_G.Mod_BulletTrack_MinDistance or 50) * 100

    local enemies = GetEnemyTargets(maxDistCm)
    if not enemies or #enemies == 0 then
        _G._LastTrackedWeapon[weaponKey] = {id = shootId, time = now}
        return
    end

    local filtered = {}
    for _, target in ipairs(enemies) do
        if slua.isValid(target) then
            local dist = 99999999
            pcall(function() dist = player:GetDistanceTo(target) end)
            if dist >= minDistCm then
                local skip = false
                if not _G.BrutalTrack.TrackBots then
                    pcall(function()
                        local teamId = target.TeamID or 0
                        if teamId > 100 then skip = true end
                    end)
                end
                if not skip and not _G.BrutalTrack.TrackDowned then
                    pcall(function()
                        if target:IsNearDeath() then skip = true end
                    end)
                end
                if not skip then
                    table.insert(filtered, target)
                end
            end
        end
    end
    if #filtered == 0 then
        _G._LastTrackedWeapon[weaponKey] = {id = shootId, time = now}
        return
    end

    local camManager = nil
    pcall(function()
        camManager = import("GameplayStatics").GetPlayerCameraManager(pc, 0)
    end)
    if not slua.isValid(camManager) then
        _G._LastTrackedWeapon[weaponKey] = {id = shootId, time = now}
        return
    end
    local camLoc = nil
    pcall(function() camLoc = camManager:GetCameraLocation() end)
    if not camLoc then
        _G._LastTrackedWeapon[weaponKey] = {id = shootId, time = now}
        return
    end

    local ui_util = require("client.common.ui_util")
    if not ui_util then
        _G._LastTrackedWeapon[weaponKey] = {id = shootId, time = now}
        return
    end
    local viewportSize = nil
    pcall(function() viewportSize = ui_util.GetViewportSize() end)
    if not viewportSize then
        _G._LastTrackedWeapon[weaponKey] = {id = shootId, time = now}
        return
    end

    local centerX = viewportSize.X * 0.5
    local centerY = viewportSize.Y * 0.5
    local trackRange = _G.BrutalTrack.FOV or 100

    local closest = nil
    local closestDist = trackRange
    local boneName = BONE_MAP[_G.Mod_BulletTrack_BodyPart or 0] or "Head"

    for _, target in ipairs(filtered) do
        if slua.isValid(target) then
            local aimPos = nil
            pcall(function()
                aimPos = target:GetBonePos(boneName, {X = 0, Y = 0, Z = 0})
            end)
            if aimPos then
                local visible = false
                pcall(function()
                    visible = pc:LineOfSightTo(target, camLoc, true)
                end)
                if visible then
                    local screen = import("Vector2D")()
                    local success = false
                    pcall(function()
                        success = pc:ProjectWorldLocationToScreen(aimPos, screen, false)
                    end)
                    if success and screen.X > 0 and screen.Y > 0 then
                        local dx = screen.X - centerX
                        local dy = screen.Y - centerY
                        local dist = math.sqrt(dx * dx + dy * dy)
                        if dist < trackRange and dist < closestDist then
                            closestDist = dist
                            closest = target
                        end
                    end
                end
            end
        end
    end

    if not slua.isValid(closest) then
        _G._LastTrackedWeapon[weaponKey] = {id = shootId, time = now}
        return
    end

    local aimPos = nil
    pcall(function()
        aimPos = closest:GetBonePos(boneName, {X = 0, Y = 0, Z = 0})
    end)
    if not aimPos then
        _G._LastTrackedWeapon[weaponKey] = {id = shootId, time = now}
        return
    end

    local rot = nil
    pcall(function()
        local kml = import("KismetMathLibrary")
        if kml then
            rot = kml.FindLookAtRotation(camLoc, aimPos)
        end
    end)
    if not rot then
        _G._LastTrackedWeapon[weaponKey] = {id = shootId, time = now}
        return
    end

    pcall(function()
        if shootComp.SetAimDirection then
            shootComp:SetAimDirection(rot)
        end
    end)
    pcall(function()
        if shootComp.ShootBulletInner then
            shootComp:ShootBulletInner(aimPos, rot, shootId)
        end
    end)

    _G._LastTrackedWeapon[weaponKey] = {id = shootId, time = now}
end

-- ================================================================
--  AIMBOT (global)
-- ================================================================
_G._AimbotCurrentPC = nil

_G.ApplyHardAimbot = function()
    if not _G.CheatsEnabled then return end
    if not _G.Mod_Aimbot_Enabled then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) then return end
        local wm = char.WeaponManagerComponent
        if not isValid(wm) then return end
        local weapon = wm.CurrentWeaponReplicated
        if not isValid(weapon) then return end
        local entity = weapon.ShootWeaponEntityComp
        if not isValid(entity) then return end
        if entity.AutoAimingConfig then
            local speed = _G.Mod_Aimbot_Speed or 8
            local dist = _G.Mod_Aimbot_Distance or 450
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    cfg.Speed = speed
                    cfg.RangeRate = speed * 0.3
                    cfg.SpeedRate = speed * 0.3
                    cfg.RangeRateSight = speed * 0.3
                    cfg.SpeedRateSight = speed * 0.3
                    cfg.CrouchRate = speed * 0.3
                    cfg.ProneRate = speed * 0.3
                    cfg.DyingRate = 0
                    cfg.adsorbMaxRange = dist
                    cfg.adsorbMinRange = 20
                    cfg.adsorbMinAttenuationDis = 100
                    cfg.adsorbMaxAttenuationDis = 8000
                    cfg.adsorbActiveMinRange = 20
                end
            end
            entity.AutoAimingConfig = entity.AutoAimingConfig
        end
        pcall(function()
            local aimComp = char.BP_AutoAimingComponent_C
                         or char.BP_AutoAimingComponent
                         or char.AutoAimingComponent
            if isValid(aimComp) and aimComp.Bones then
                pcall(function() aimComp.Bones[0] = "head" end)
                pcall(function() aimComp.Bones[1] = "head" end)
                pcall(function() aimComp.Bones[2] = "head" end)
            end
        end)
    end)
end

-- ================================================================
--  NO SPREAD (global)
-- ================================================================
_G.ApplyNoSpread = function()
    if not _G.CheatsEnabled then return end
    if not _G.Mod_NoSpread_Enabled then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) then return end
        local wm = char.WeaponManagerComponent
        if not isValid(wm) then return end
        local weapon = wm.CurrentWeaponReplicated
        if not isValid(weapon) then return end
        local entity = weapon.ShootWeaponEntityComp
        if not isValid(entity) then return end
        entity.GameDeviationFactor = 0.0
        entity.ShotGunHorizontalSpread = 0.0
        entity.ShotGunVerticalSpread = 0.0
    end)
end

-- ================================================================
--  FOV MOD (global)
-- ================================================================
_G.ApplyFOV = function()
    if not _G.CheatsEnabled then return end
    if not _G.Mod_FOV_Enabled then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) then return end
        local tpCam = char.ThirdPersonCameraComponent
        if slua.isValid(tpCam) then
            local fov = _G.Mod_FOV_Value or 115
            if tpCam.FieldOfView ~= fov then
                tpCam.FieldOfView = fov
            end
        end
    end)
end

-- ================================================================
--  MAGIC BULLET (global) – Fixed 290% hitbox scaling, Head+Body+Limbs
-- ================================================================
_G._MBones = _G._MBones or {}
_G._MagicBulletApplied = false

_G.ApplyMagicBullet = function()
    if not _G.CheatsEnabled then return end
    if not _G.Mod_MagicBullet_Enabled then
        -- Wipe cache when turned off so next enable is fresh
        if _G._MagicBulletApplied then
            _G._MBones = {}
            _G._MagicBulletApplied = false
        end
        return
    end

    -- Fixed 290% multiplier
    local sizePct = 290

    -- Base bone multipliers (HRModster style) – apply to all bones with varying multipliers
    local mb = {
        ["head"] = 290, ["neck_01"] = 290,
        ["spine_01"] = 290, ["spine_02"] = 290, ["spine_03"] = 290,
        ["pelvis"] = 290,
        ["upperarm_l"] = 290, ["upperarm_r"] = 290,
        ["lowerarm_l"] = 290, ["lowerarm_r"] = 290,
        ["hand_l"] = 290, ["hand_r"] = 290,
        ["thigh_l"] = 290, ["thigh_r"] = 290,
        ["calf_l"] = 290, ["calf_r"] = 290,
        ["foot_l"] = 290, ["foot_r"] = 290,
    }

    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) then return end

        local allChars = Game:GetAllPlayerPawns() or {}
        local myTeam = char.TeamID or 0
        local scaledCount = 0

        for _, c in pairs(allChars) do
            if slua.isValid(c) and c ~= char and (c.TeamID or 0) ~= myTeam then
                local mesh = c.Mesh
                if not slua.isValid(mesh) then goto skip_char end

                local physAsset = mesh.PhysicsAssetOverride
                if not slua.isValid(physAsset) and slua.isValid(mesh.SkeletalMesh) then
                    physAsset = mesh.SkeletalMesh.PhysicsAsset
                end

                if not slua.isValid(physAsset) then goto skip_char end

                local assetName = (physAsset.GetName and physAsset:GetName()) or tostring(physAsset)

                if _G._MBones[assetName] then goto skip_char end

                local setups = physAsset.SkeletalBodySetups
                if not setups then goto skip_char end

                -- Determine array length safely
                local setupCount = 0
                pcall(function()
                    if type(setups.Num) == "function" then
                        setupCount = setups:Num()
                    elseif type(setups.Length) == "number" then
                        setupCount = setups.Length
                    elseif type(setups) == "table" then
                        setupCount = #setups
                    end
                end)
                local maxIter = math.min(setupCount > 0 and setupCount or 80, 80)

                for i = 1, maxIter do
                    local bs = nil
                    pcall(function()
                        if type(setups.Get) == "function" then
                            bs = setups:Get(i - 1)
                        elseif setups[i] then
                            bs = setups[i]
                        end
                    end)

                    if not bs or not slua.isValid(bs) then goto next_bone end

                    local bn = tostring(bs.BoneName or ""):lower()
                    local pct = nil
                    for pat, val in pairs(mb) do
                        if string.find(bn, pat, 1, true) then
                            pct = val
                            break
                        end
                    end

                    if not pct then goto next_bone end

                    -- Scale ALL bones (head, body, limbs) — no target filter, always full coverage
                    local effectivePct = pct * (sizePct / 100.0)
                    local sc = 1.0 + (effectivePct / 100.0)
                    local ag = bs.AggGeom

                    -- BoxElems
                    pcall(function()
                        local bx = (ag and ag.BoxElems) or bs.BoxElems
                        if bx then
                            local b = nil
                            if type(bx.Get) == "function" then
                                b = bx:Get(0)
                            elseif bx[1] then
                                b = bx[1]
                            end
                            if b then
                                b.X = (b.X or 30) * sc
                                b.Y = (b.Y or 30) * sc
                                b.Z = (b.Z or 60) * sc
                                if type(bx.Set) == "function" then bx:Set(0, b) else bx[1] = b end
                                if ag then bs.AggGeom = ag else bs.BoxElems = bx end
                            end
                        end
                    end)

                    -- SphylElems (capsules)
                    pcall(function()
                        local sp = (ag and ag.SphylElems) or bs.SphylElems
                        if sp then
                            local s = nil
                            if type(sp.Get) == "function" then
                                s = sp:Get(0)
                            elseif sp[1] then
                                s = sp[1]
                            end
                            if s then
                                if s.Radius then s.Radius = s.Radius * sc end
                                if s.Length then s.Length = s.Length * sc end
                                if type(sp.Set) == "function" then sp:Set(0, s) else sp[1] = s end
                                if ag then bs.AggGeom = ag else bs.SphylElems = sp end
                            end
                        end
                    end)

                    -- SphereElems
                    pcall(function()
                        local sr = (ag and ag.SphereElems) or bs.SphereElems
                        if sr then
                            local r = nil
                            if type(sr.Get) == "function" then
                                r = sr:Get(0)
                            elseif sr[1] then
                                r = sr[1]
                            end
                            if r and r.Radius then
                                r.Radius = r.Radius * sc
                                if type(sr.Set) == "function" then sr:Set(0, r) else sr[1] = r end
                                if ag then bs.AggGeom = ag else bs.SphereElems = sr end
                            end
                        end
                    end)

                    scaledCount = scaledCount + 1
                    ::next_bone::
                end

                _G._MBones[assetName] = true
                if mesh.RecreatePhysicsState then
                    pcall(function() mesh:RecreatePhysicsState() end)
                end

                ::skip_char::
            end
        end

        if scaledCount > 0 then
            _G._MagicBulletApplied = true
        end
    end)
end

-- ================================================================
--  MEMORY FEATURES (From 1.lua)
-- ================================================================
-- Helper functions for sliders
local function Norm(val, min, max) return (val - min) / (max - min) end
local function DeNorm(norm, min, max) return min + (norm * (max - min)) end

-- Memory Config
_G.MemoryConfig = _G.MemoryConfig or {
    SpeedBoost = false,
    SpeedPercent = 250,
    AntiGravity = false,
    GravityScale = 1.0,
    WallClimb = false,
    CharRotation = false,
    CharRotSpeed = 360,
    CharScale = 1.0,
    EnemyScale = 1.0,
    SuperBullet = 1,
    SuperFireRate = false,
    SuperFireRateVal = 0.008,
    InfiniteAmmo = false,
    MagicBullet = false,  -- We keep this, but our Magic Bullet is separate (ApplyMagicBullet)
}

-- Speed Boost
_G.SpeedBoostState = _G.SpeedBoostState or {active = false, timer = nil, modifyId = nil, currentChar = nil}
local function RemoveSpeedModify(char)
    if not slua.isValid(char) or not char.AttrModifyComp then return end
    if _G.SpeedBoostState.modifyId then
        pcall(function() char.AttrModifyComp:RemoveModifyItemFromCache(_G.SpeedBoostState.modifyId) end)
        _G.SpeedBoostState.modifyId = nil
    end
end
local function ApplySpeedModify(char)
    if not slua.isValid(char) or not char.AttrModifyComp then return end
    RemoveSpeedModify(char)
    local rate = (_G.MemoryConfig.SpeedPercent / 100.0) - 1.0
    pcall(function()
        _G.SpeedBoostState.modifyId = char.AttrModifyComp:AddModifyItemAndCache("SpeedRate", 0, rate, true, char, false)
    end)
end
local function UpdateSpeedBoost()
    if not _G.MemoryConfig.SpeedBoost then return end
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(pc) then return end
    local char = pc:GetPlayerCharacterSafety()
    if not slua.isValid(char) then return end
    if _G.SpeedBoostState.currentChar ~= char then
        if _G.SpeedBoostState.currentChar then RemoveSpeedModify(_G.SpeedBoostState.currentChar) end
        _G.SpeedBoostState.currentChar = char
    end
    ApplySpeedModify(char)
end
function SetMemorySpeedBoost(enabled)
    _G.MemoryConfig.SpeedBoost = enabled
    if enabled then
        if _G.SpeedBoostState.timer then return end
        _G.SpeedBoostState.active = true
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) and pc.AddGameTimer then
            _G.SpeedBoostState.timer = pc:AddGameTimer(0.3, true, UpdateSpeedBoost)
        end
    else
        _G.SpeedBoostState.active = false
        if _G.SpeedBoostState.timer then
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) and pc.RemoveGameTimer then pc:RemoveGameTimer(_G.SpeedBoostState.timer) end
            _G.SpeedBoostState.timer = nil
        end
        if _G.SpeedBoostState.currentChar then
            RemoveSpeedModify(_G.SpeedBoostState.currentChar)
            _G.SpeedBoostState.currentChar = nil
        end
    end
end
function SetMemorySpeedPercent(val)
    _G.MemoryConfig.SpeedPercent = val
    if _G.MemoryConfig.SpeedBoost and _G.SpeedBoostState.currentChar then
        ApplySpeedModify(_G.SpeedBoostState.currentChar)
    end
end

-- Anti-Gravity
function SetMemoryAntiGravity(enabled)
    _G.MemoryConfig.AntiGravity = enabled
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(pc) then return end
    local char = pc:GetPlayerCharacterSafety()
    if slua.isValid(char) then
        local move = char.CharacterMovement or char.CharMoveComp
        if move then
            move.GravityScale = enabled and _G.MemoryConfig.GravityScale or 1.0
        end
    end
end
function SetMemoryGravityScale(val)
    _G.MemoryConfig.GravityScale = val
    if _G.MemoryConfig.AntiGravity then SetMemoryAntiGravity(true) end
end

-- Wall Climb
function SetMemoryWallClimb(enabled)
    _G.MemoryConfig.WallClimb = enabled
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(pc) then return end
    local char = pc:GetPlayerCharacterSafety()
    if slua.isValid(char) then
        local move = char.CharacterMovement or char.CharMoveComp
        if move then
            if enabled then
                move.WalkableFloorAngle = 199.0
                move.MaxStepHeight = 999.0
            else
                move.WalkableFloorAngle = 45.0
                move.MaxStepHeight = 45.0
            end
        end
    end
end

-- Character Rotation
_G.CharRotState = _G.CharRotState or {timer = nil, yaw = 0}
local function UpdateCharRot()
    if not _G.MemoryConfig.CharRotation then return end
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(pc) then return end
    local char = pc:GetPlayerCharacterSafety()
    if not slua.isValid(char) or not slua.isValid(char.Mesh) then return end
    _G.CharRotState.yaw = (_G.CharRotState.yaw + _G.MemoryConfig.CharRotSpeed * 0.016) % 360
    local rot = char.Mesh:K2_GetComponentRotation()
    rot.Yaw = _G.CharRotState.yaw
    char.Mesh:K2_SetWorldRotation(rot, false, nil, false)
end
function SetMemoryCharRotation(enabled)
    _G.MemoryConfig.CharRotation = enabled
    if enabled then
        if _G.CharRotState.timer then return end
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) and pc.AddGameTimer then
            local char = pc:GetPlayerCharacterSafety()
            if slua.isValid(char) and slua.isValid(char.Mesh) then
                _G.CharRotState.yaw = char.Mesh:K2_GetComponentRotation().Yaw
            end
            _G.CharRotState.timer = pc:AddGameTimer(0.016, true, UpdateCharRot)
        end
    else
        if _G.CharRotState.timer then
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) and pc.RemoveGameTimer then pc:RemoveGameTimer(_G.CharRotState.timer) end
            _G.CharRotState.timer = nil
        end
    end
end
function SetMemoryCharRotSpeed(val) _G.MemoryConfig.CharRotSpeed = val end

-- Character / Enemy Scale
function SetMemoryCharScale(val)
    _G.MemoryConfig.CharScale = val
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) then
        local char = pc:GetPlayerCharacterSafety()
        if slua.isValid(char) then char:SetActorScale3D(FVector(val, val, val)) end
    end
end
function SetMemoryEnemyScale(val)
    _G.MemoryConfig.EnemyScale = val
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(pc) then return end
    local myChar = pc:GetPlayerCharacterSafety()
    if not slua.isValid(myChar) then return end
    local myTeam = myChar.TeamID or 0
    local all = Game:GetAllPlayerPawns()
    if not all then return end
    for _, p in pairs(all) do
        if slua.isValid(p) and p ~= myChar and (p.TeamID or 0) ~= myTeam then
            p:SetActorScale3D(FVector(val, val, val))
        end
    end
end

-- Super Bullet
function ApplyMemorySuperBullet(count)
    _G.MemoryConfig.SuperBullet = count or 1
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(pc) then return end
    local char = pc:GetPlayerCharacterSafety()
    if not slua.isValid(char) then return end
    local wm = char.WeaponManagerComponent
    if not slua.isValid(wm) then return end
    local wep = wm.CurrentWeaponReplicated
    if not slua.isValid(wep) then return end
    local shoot = wep.ShootWeaponEntityComp
    if slua.isValid(shoot) then
        shoot.BulletNumSingleShot = count
    end
end

-- Super Fire Rate
function ApplyMemorySuperFireRate(enabled)
    _G.MemoryConfig.SuperFireRate = enabled
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(pc) then return end
    local char = pc:GetPlayerCharacterSafety()
    if not slua.isValid(char) then return end
    local wm = char.WeaponManagerComponent
    if not slua.isValid(wm) then return end
    local wep = wm.CurrentWeaponReplicated
    if not slua.isValid(wep) then return end
    local shoot = wep.ShootWeaponEntityComp
    if slua.isValid(shoot) then
        shoot.ShootInterval = enabled and _G.MemoryConfig.SuperFireRateVal or 0.1
    end
end
function SetMemorySuperFireRateVal(val) _G.MemoryConfig.SuperFireRateVal = val end

-- Infinite Ammo
function ApplyMemoryInfiniteAmmo(enabled)
    _G.MemoryConfig.InfiniteAmmo = enabled
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(pc) then return end
    local char = pc:GetPlayerCharacterSafety()
    if not slua.isValid(char) then return end
    local wm = char.WeaponManagerComponent
    if not slua.isValid(wm) then return end
    local wep = wm.CurrentWeaponReplicated
    if not slua.isValid(wep) then return end
    local shoot = wep.ShootWeaponEntityComp
    if slua.isValid(shoot) then
        shoot.bClipHasInfiniteBullets = enabled
        shoot.bHasInfiniteBullets = enabled
    end
end

-- ================================================================
--  RESET CONFIG FUNCTION (extended with memory)
-- ================================================================
_G.ResetConfig = function()
    _G.Mod_Aimbot_Speed = 8
    _G.Mod_Aimbot_Distance = 450
    _G.Mod_BulletTrack_MaxDistance = 99999999
    _G.Mod_BulletTrack_MinDistance = 50
    _G.Mod_BulletTrack_BodyPart = 0
    _G.Mod_FOV_Value = 115
    _G.Mod_MagicBullet_Enabled = false
    _G._MBones = {}
    _G._MagicBulletApplied = false
    _G.Mod_MapMarker_Enabled = false
    -- Reset memory features
    _G.MemoryConfig.SpeedBoost = false
    _G.MemoryConfig.SpeedPercent = 250
    _G.MemoryConfig.AntiGravity = false
    _G.MemoryConfig.GravityScale = 1.0
    _G.MemoryConfig.WallClimb = false
    _G.MemoryConfig.CharRotation = false
    _G.MemoryConfig.CharRotSpeed = 360
    _G.MemoryConfig.CharScale = 1.0
    _G.MemoryConfig.EnemyScale = 1.0
    _G.MemoryConfig.SuperBullet = 1
    _G.MemoryConfig.SuperFireRate = false
    _G.MemoryConfig.SuperFireRateVal = 0.008
    _G.MemoryConfig.InfiniteAmmo = false
    -- Ensure timers stopped
    SetMemorySpeedBoost(false)
    SetMemoryCharRotation(false)
    print("[RESET] All config values reset to defaults.")
end

-- ================================================================
--  MAIN TIMER (single loop – 0.1s interval, uses Game:SetTimer)
-- ================================================================
local function HackLoop()
    pcall(function()
        -- ESP
        if _G.Mod_ESP_Enabled then
            _G.ESPTick()
        end
        -- Aimbot
        if _G.Mod_Aimbot_Enabled then
            _G.ApplyHardAimbot()
        end
        -- Map Marker
        -- Bullet Track
        if _G.Mod_BulletTrack_Enabled then
            _G.BrutalBulletTrack()
        end
        -- No Spread
        if _G.Mod_NoSpread_Enabled then
            _G.ApplyNoSpread()
        end
        -- FOV
        if _G.Mod_FOV_Enabled then
            _G.ApplyFOV()
        end
        -- Magic Bullet
        if _G.Mod_MagicBullet_Enabled then
            _G.ApplyMagicBullet()
        end
        -- Memory features are timer-driven, but we can optionally apply some on each tick
        -- We'll keep them separate for efficiency.
    end)
end

local function StartMainTimer()
    local success, handle = pcall(function()
        return Game:SetTimer(0.1, true, HackLoop)
    end)
    if success and handle then
        _G._MainTimerHandle = handle
        print("[MAIN-TIMER] Started via Game:SetTimer.")
    else
        local function attachTimer()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) and pc.AddGameTimer then
                _G._MainTimerHandle = pc:AddGameTimer(0.1, true, HackLoop)
                print("[MAIN-TIMER] Started via PlayerController timer.")
            else
                local fb = slua_GameFrontendHUD or Game
                if fb and fb.AddGameTimer then
                    fb:AddGameTimer(1.0, false, attachTimer)
                end
            end
        end
        attachTimer()
    end
end

-- ================================================================
--  UI MENU (Extended with Memory Features)
-- ================================================================
local ModMenu = {}
local MENU_BP = "/Game/UMG/UI_BP/Common/Common_Legal_01_UIBP.Common_Legal_01_UIBP"
local BTN_BP = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"
local Z_TRIGGER = 9300
local Z_MENU = 9600

ModMenu.menuWidget = nil
ModMenu.triggerWidget = nil
ModMenu.currentPage = 1
ModMenu.loadedButtons = {}

local function valid(obj) return obj and (not slua.isValid or slua.isValid(obj)) end

local function later(sec, fn)
    if _G.SetTimer then pcall(_G.SetTimer, sec, fn) return end
    local tk = _G.Mytimer_ticker
    if not tk then pcall(function() tk = require("common.time_ticker"); _G.Mytimer_ticker = tk end) end
    if tk and tk.AddTimer then pcall(tk.AddTimer, sec, fn); return end
    local GameThread = import("GameThread")
    if GameThread and GameThread.Delay then pcall(GameThread.Delay, sec, fn); return end
end

local function ToggleStr(v) return v and "[ON]" or "[OFF]" end
local function ValStr(v) return "< " .. tostring(v) .. " >" end

-- Toggle functions (extended)
local function doToggle(id)
    if id == "ESP" then
        _G.Mod_ESP_Enabled = not _G.Mod_ESP_Enabled
        _G.Mod_MapMarker_Enabled = _G.Mod_ESP_Enabled  -- LINKED: marker follows ESP state
        print("[MENU] ESP: " .. ToggleStr(_G.Mod_ESP_Enabled) .. " | MapMarker: " .. ToggleStr(_G.Mod_MapMarker_Enabled))
    elseif id == "AIMBOT" then
        _G.Mod_Aimbot_Enabled = not _G.Mod_Aimbot_Enabled
        print("[MENU] AIMBOT: " .. ToggleStr(_G.Mod_Aimbot_Enabled))
    elseif id == "BULLET_TRACK" then
        _G.Mod_BulletTrack_Enabled = not _G.Mod_BulletTrack_Enabled
        print("[MENU] BULLET TRACK: " .. ToggleStr(_G.Mod_BulletTrack_Enabled))
    elseif id == "NO_SPREAD" then
        _G.Mod_NoSpread_Enabled = not _G.Mod_NoSpread_Enabled
        print("[MENU] NO SPREAD: " .. ToggleStr(_G.Mod_NoSpread_Enabled))
    elseif id == "FOV" then
        _G.Mod_FOV_Enabled = not _G.Mod_FOV_Enabled
        print("[MENU] FOV: " .. ToggleStr(_G.Mod_FOV_Enabled))
    elseif id == "MAGIC_BULLET" then
        _G.Mod_MagicBullet_Enabled = not _G.Mod_MagicBullet_Enabled
        print("[MENU] MAGIC BULLET: " .. ToggleStr(_G.Mod_MagicBullet_Enabled))
    -- Memory features
    elseif id == "MEM_SPEED" then
        SetMemorySpeedBoost(not _G.MemoryConfig.SpeedBoost)
        print("[MENU] SPEED BOOST: " .. ToggleStr(_G.MemoryConfig.SpeedBoost))
    elseif id == "MEM_ANTIGRAVITY" then
        SetMemoryAntiGravity(not _G.MemoryConfig.AntiGravity)
        print("[MENU] ANTI-GRAVITY: " .. ToggleStr(_G.MemoryConfig.AntiGravity))
    elseif id == "MEM_WALLCLIMB" then
        SetMemoryWallClimb(not _G.MemoryConfig.WallClimb)
        print("[MENU] WALL CLIMB: " .. ToggleStr(_G.MemoryConfig.WallClimb))
    elseif id == "MEM_CHARROT" then
        SetMemoryCharRotation(not _G.MemoryConfig.CharRotation)
        print("[MENU] CHAR ROTATION: " .. ToggleStr(_G.MemoryConfig.CharRotation))
    elseif id == "MEM_SUPERFIRERATE" then
        ApplyMemorySuperFireRate(not _G.MemoryConfig.SuperFireRate)
        print("[MENU] SUPER FIRE RATE: " .. ToggleStr(_G.MemoryConfig.SuperFireRate))
    elseif id == "MEM_INFINITEAMMO" then
        ApplyMemoryInfiniteAmmo(not _G.MemoryConfig.InfiniteAmmo)
        print("[MENU] INFINITE AMMO: " .. ToggleStr(_G.MemoryConfig.InfiniteAmmo))
    end
end

-- Config value cycling (extended)
local function cycleValue(id, min, max, step)
    if id == "AIMBOT_SPEED" then
        local cur = _G.Mod_Aimbot_Speed or 8
        cur = cur + step
        if cur > max then cur = min end
        _G.Mod_Aimbot_Speed = cur
        print("[CONFIG] Aimbot Speed: " .. cur)
    elseif id == "AIMBOT_DIST" then
        local cur = _G.Mod_Aimbot_Distance or 450
        cur = cur + step
        if cur > max then cur = min end
        _G.Mod_Aimbot_Distance = cur
        print("[CONFIG] Aimbot Distance: " .. cur)
    elseif id == "BT_BODYPART" then
        local cur = _G.Mod_BulletTrack_BodyPart or 0
        cur = cur + step
        if cur > max then cur = min end
        _G.Mod_BulletTrack_BodyPart = cur
        local names = {"Head", "Neck", "Chest"}
        print("[CONFIG] Bullet Track Body: " .. (names[cur+1] or "Head"))
    elseif id == "BT_MAXDIST" then
        local cur = _G.Mod_BulletTrack_MaxDistance or 99999999
        cur = cur + step
        if cur > max then cur = min end
        _G.Mod_BulletTrack_MaxDistance = cur
        print("[CONFIG] Bullet Track Max Dist: " .. cur/100 .. "m")
    elseif id == "BT_MINDIST" then
        local cur = _G.Mod_BulletTrack_MinDistance or 50
        cur = cur + step
        if cur > max then cur = min end
        _G.Mod_BulletTrack_MinDistance = cur
        print("[CONFIG] Bullet Track Min Dist: " .. cur .. "m")
    elseif id == "FOV_VALUE" then
        local cur = _G.Mod_FOV_Value or 115
        cur = cur + step
        if cur > max then cur = min end
        _G.Mod_FOV_Value = cur
        print("[CONFIG] FOV Value: " .. cur)
    -- Memory configs
    elseif id == "MEM_SPEED_PCT" then
        local cur = _G.MemoryConfig.SpeedPercent or 100
        cur = cur + step
        if cur > max then cur = min end
        SetMemorySpeedPercent(cur)
        print("[CONFIG] Speed %: " .. cur)
    elseif id == "MEM_GRAVITY" then
        local cur = _G.MemoryConfig.GravityScale or 1.0
        cur = cur + step
        if cur > max then cur = min end
        SetMemoryGravityScale(cur)
        print("[CONFIG] Gravity Scale: " .. cur)
    elseif id == "MEM_CHARROTSPEED" then
        local cur = _G.MemoryConfig.CharRotSpeed or 360
        cur = cur + step
        if cur > max then cur = min end
        SetMemoryCharRotSpeed(cur)
        print("[CONFIG] Char Rot Speed: " .. cur)
    elseif id == "MEM_CHARSCALE" then
        local cur = _G.MemoryConfig.CharScale or 1.0
        cur = cur + step
        if cur > max then cur = min end
        SetMemoryCharScale(cur)
        print("[CONFIG] Char Scale: " .. cur)
    elseif id == "MEM_ENEMYSCALE" then
        local cur = _G.MemoryConfig.EnemyScale or 1.0
        cur = cur + step
        if cur > max then cur = min end
        SetMemoryEnemyScale(cur)
        print("[CONFIG] Enemy Scale: " .. cur)
    elseif id == "MEM_SUPERBULLET" then
        local cur = _G.MemoryConfig.SuperBullet or 1
        cur = cur + step
        if cur > max then cur = min end
        ApplyMemorySuperBullet(cur)
        print("[CONFIG] Super Bullet Count: " .. cur)
    elseif id == "MEM_FIRERATEVAL" then
        local cur = _G.MemoryConfig.SuperFireRateVal or 0.008
        cur = cur + step
        if cur > max then cur = min end
        SetMemorySuperFireRateVal(cur)
        if _G.MemoryConfig.SuperFireRate then ApplyMemorySuperFireRate(true) end
        print("[CONFIG] Fire Rate Interval: " .. cur)
    end
end

local function GetLabel(id)
    if id == "ESP" then return "ESP " .. ToggleStr(_G.Mod_ESP_Enabled)
    elseif id == "AIMBOT" then return "AIMBOT " .. ToggleStr(_G.Mod_Aimbot_Enabled)
    elseif id == "BULLET_TRACK" then return "BULLET TRACK " .. ToggleStr(_G.Mod_BulletTrack_Enabled)
    elseif id == "NO_SPREAD" then return "NO SPREAD " .. ToggleStr(_G.Mod_NoSpread_Enabled)
    elseif id == "FOV" then return "FOV " .. ToggleStr(_G.Mod_FOV_Enabled)
    elseif id == "MAGIC_BULLET" then return "MAGIC BULLET " .. ToggleStr(_G.Mod_MagicBullet_Enabled)
    elseif id == "AIMBOT_SPEED" then return "Aim Speed: " .. ValStr(_G.Mod_Aimbot_Speed)
    elseif id == "AIMBOT_DIST" then return "Aim Dist: " .. ValStr(_G.Mod_Aimbot_Distance)
    elseif id == "BT_BODYPART" then
        local names = {"Head", "Neck", "Chest"}
        return "BT Body: " .. ValStr(names[_G.Mod_BulletTrack_BodyPart+1] or "Head")
    elseif id == "BT_MAXDIST" then
        local val = (_G.Mod_BulletTrack_MaxDistance or 99999999) / 100
        return "BT Max Dist: " .. ValStr(val .. "m")
    elseif id == "BT_MINDIST" then
        return "BT Min Dist: " .. ValStr(_G.Mod_BulletTrack_MinDistance .. "m")
    elseif id == "FOV_VALUE" then
        return "FOV Value: " .. ValStr(_G.Mod_FOV_Value)
    elseif id == "MAP_MARKER" then return "MAP MARKER " .. ToggleStr(_G.Mod_MapMarker_Enabled)
    -- Memory labels
    elseif id == "MEM_SPEED" then return "SPEED BOOST " .. ToggleStr(_G.MemoryConfig.SpeedBoost)
    elseif id == "MEM_SPEED_PCT" then return "Speed %: " .. ValStr(_G.MemoryConfig.SpeedPercent)
    elseif id == "MEM_ANTIGRAVITY" then return "ANTI-GRAV " .. ToggleStr(_G.MemoryConfig.AntiGravity)
    elseif id == "MEM_GRAVITY" then return "Gravity: " .. ValStr(string.format("%.2f", _G.MemoryConfig.GravityScale))
    elseif id == "MEM_WALLCLIMB" then return "WALL CLIMB " .. ToggleStr(_G.MemoryConfig.WallClimb)
    elseif id == "MEM_CHARROT" then return "CHAR ROT " .. ToggleStr(_G.MemoryConfig.CharRotation)
    elseif id == "MEM_CHARROTSPEED" then return "Rot Speed: " .. ValStr(_G.MemoryConfig.CharRotSpeed)
    elseif id == "MEM_CHARSCALE" then return "Char Scale: " .. ValStr(string.format("%.1f", _G.MemoryConfig.CharScale))
    elseif id == "MEM_ENEMYSCALE" then return "Enemy Scale: " .. ValStr(string.format("%.1f", _G.MemoryConfig.EnemyScale))
    elseif id == "MEM_SUPERBULLET" then return "Super Bullet: " .. ValStr(_G.MemoryConfig.SuperBullet)
    elseif id == "MEM_SUPERFIRERATE" then return "SUPER FIRERATE " .. ToggleStr(_G.MemoryConfig.SuperFireRate)
    elseif id == "MEM_FIRERATEVAL" then return "Fire Interval: " .. ValStr(string.format("%.3f", _G.MemoryConfig.SuperFireRateVal))
    elseif id == "MEM_INFINITEAMMO" then return "INFINITE AMMO " .. ToggleStr(_G.MemoryConfig.InfiniteAmmo)
    elseif id == "RESET" then
        return "═══ RESET ALL ═══"
    end
    return "UNKNOWN"
end

local pages = {
    { title = "MAIN", features = {
        { label = function() return GetLabel("ESP") end, toggle = function() doToggle("ESP") end },
        { label = function() return GetLabel("AIMBOT") end, toggle = function() doToggle("AIMBOT") end },
        { label = function() return GetLabel("BULLET_TRACK") end, toggle = function() doToggle("BULLET_TRACK") end },
        { label = function() return GetLabel("NO_SPREAD") end, toggle = function() doToggle("NO_SPREAD") end },
        { label = function() return GetLabel("FOV") end, toggle = function() doToggle("FOV") end },
        { label = function() return GetLabel("MAGIC_BULLET") end, toggle = function() doToggle("MAGIC_BULLET") end },
        { label = function() return GetLabel("MAP_MARKER") end, toggle = function() doToggle("MAP_MARKER") end },
    }},
    { title = "CONFIG", features = {
        { label = function() return GetLabel("AIMBOT_SPEED") end, toggle = function() cycleValue("AIMBOT_SPEED", 1, 10, 1) end },
        { label = function() return GetLabel("AIMBOT_DIST") end, toggle = function() cycleValue("AIMBOT_DIST", 20, 800, 10) end },
        { label = function() return GetLabel("BT_BODYPART") end, toggle = function() cycleValue("BT_BODYPART", 0, 2, 1) end },
        { label = function() return GetLabel("BT_MAXDIST") end, toggle = function() cycleValue("BT_MAXDIST", 1000, 100000, 1000) end },
        { label = function() return GetLabel("BT_MINDIST") end, toggle = function() cycleValue("BT_MINDIST", 0, 500, 5) end },
        { label = function() return GetLabel("FOV_VALUE") end, toggle = function() cycleValue("FOV_VALUE", 80, 130, 1) end },
        { label = function() return GetLabel("RESET") end, toggle = function() _G.ResetConfig() end },
    }},
    { title = "MEMORY", features = {
        { label = function() return GetLabel("MEM_SPEED") end, toggle = function() doToggle("MEM_SPEED") end },
        { label = function() return GetLabel("MEM_SPEED_PCT") end, toggle = function() cycleValue("MEM_SPEED_PCT", 100, 500, 10) end },
        { label = function() return GetLabel("MEM_ANTIGRAVITY") end, toggle = function() doToggle("MEM_ANTIGRAVITY") end },
        { label = function() return GetLabel("MEM_GRAVITY") end, toggle = function() cycleValue("MEM_GRAVITY", -0.45, 1.0, 0.05) end },
        { label = function() return GetLabel("MEM_WALLCLIMB") end, toggle = function() doToggle("MEM_WALLCLIMB") end },
        { label = function() return GetLabel("MEM_CHARROT") end, toggle = function() doToggle("MEM_CHARROT") end },
        { label = function() return GetLabel("MEM_CHARROTSPEED") end, toggle = function() cycleValue("MEM_CHARROTSPEED", 180, 1080, 30) end },
        { label = function() return GetLabel("MEM_CHARSCALE") end, toggle = function() cycleValue("MEM_CHARSCALE", 1.0, 10.0, 0.1) end },
        { label = function() return GetLabel("MEM_ENEMYSCALE") end, toggle = function() cycleValue("MEM_ENEMYSCALE", 1.0, 10.0, 0.1) end },
        { label = function() return GetLabel("MEM_SUPERBULLET") end, toggle = function() cycleValue("MEM_SUPERBULLET", 1, 20, 1) end },
        { label = function() return GetLabel("MEM_SUPERFIRERATE") end, toggle = function() doToggle("MEM_SUPERFIRERATE") end },
        { label = function() return GetLabel("MEM_FIRERATEVAL") end, toggle = function() cycleValue("MEM_FIRERATEVAL", 0.001, 0.05, 0.001) end },
        { label = function() return GetLabel("MEM_INFINITEAMMO") end, toggle = function() doToggle("MEM_INFINITEAMMO") end },
        { label = function() return GetLabel("RESET") end, toggle = function() _G.ResetConfig() end },
    }},
}

function ModMenu:ClearButtons()
    for _, b in ipairs(self.loadedButtons) do pcall(function() if valid(b) then b:RemoveFromParent() end end) end
    self.loadedButtons = {}
end

function ModMenu:BuildUI(w)
    self:ClearButtons()
    local tabStartX = -350
    local tabStartY = -140
    local tabW, tabH = 150, 48
    local tabGap = 12
    for i, page in ipairs(pages) do
        pcall(function()
            local btn = slua.loadUI(BTN_BP)
            if not btn or not valid(btn) then return end
            btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
            if btn.RichText_Content then
                local prefix = (i == self.currentPage) and "> " or "  "
                btn.RichText_Content:SetText(prefix .. page.title)
            end
            if btn.Button_Temp and btn.Button_Temp.OnClicked then
                btn.Button_Temp.OnClicked:Add(function()
                    self.currentPage = i
                    self:BuildUI(w)
                end)
            end
            pcall(function() require("game_frontend_hud").AddToContainer(UIContainers.Top, btn, Z_MENU + i) end)
            pcall(function()
                local slot = import("WidgetLayoutLibrary").SlotAsCanvasSlot(btn)
                if slot then
                    slot:SetAnchors(FAnchors(0.5, 0.5, 0.5, 0.5))
                    slot:SetAlignment(FVector2D(0.5, 0.5))
                    slot:SetPosition(FVector2D(tabStartX, tabStartY + (i - 1) * (tabH + tabGap)))
                    slot:SetSize(FVector2D(tabW, tabH))
                end
            end)
            table.insert(self.loadedButtons, btn)
        end)
    end
    local page = pages[self.currentPage]
    if not page then return end
    local featStartX = -100
    local featStartY = -140
    local featW, featH = 260, 42
    local featGapX = 280
    local featGapY = 45
    for i, feat in ipairs(page.features) do
        pcall(function()
            local btn = slua.loadUI(BTN_BP)
            if not btn or not valid(btn) then return end
            btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
            if btn.RichText_Content then
                local txt = type(feat.label) == "function" and feat.label() or feat.label
                btn.RichText_Content:SetText(txt)
            end
            if btn.Button_Temp and btn.Button_Temp.OnClicked then
                btn.Button_Temp.OnClicked:Add(function()
                    if feat.action then feat.action() elseif feat.toggle then feat.toggle() end
                    later(0.05, function() self:BuildUI(w) end)
                end)
            end
            pcall(function() require("game_frontend_hud").AddToContainer(UIContainers.Top, btn, Z_MENU + 20 + i) end)
            pcall(function()
                local slot = import("WidgetLayoutLibrary").SlotAsCanvasSlot(btn)
                if slot then
                    local col = (i - 1) % 2
                    local row = math.floor((i - 1) / 2)
                    local posX = featStartX + (col * featGapX)
                    local posY = featStartY + (row * featGapY)
                    slot:SetAnchors(FAnchors(0.5, 0.5, 0.5, 0.5))
                    slot:SetAlignment(FVector2D(0.5, 0.5))
                    slot:SetPosition(FVector2D(posX, posY))
                    slot:SetSize(FVector2D(featW, featH))
                end
            end)
            table.insert(self.loadedButtons, btn)
        end)
    end
end

function ModMenu:Close()
    self:ClearButtons()
    if self.menuWidget and valid(self.menuWidget) then pcall(function() self.menuWidget:RemoveFromParent() end) end
    self.menuWidget = nil
end

function ModMenu:Open()
    if self.menuWidget and valid(self.menuWidget) then return end
    local w = nil; pcall(function() w = slua.loadUI(MENU_BP) end); if not w or not valid(w) then return end
    pcall(function() require("game_frontend_hud").AddToContainer(UIContainers.Top, w, Z_MENU) end)
    pcall(function() if w.HBox_Button then w.HBox_Button:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
    pcall(function() if w.TextBlock_tips then w.TextBlock_tips:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
    pcall(function() if w.Button_OK then w.Button_OK:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
    pcall(function() if w.Button_Cancel then w.Button_Cancel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
    pcall(function() if w.Button_1 then w.Button_1:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
    pcall(function() if w.Background_Btn then w.Background_Btn:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end)
    pcall(function() if w.UTRichText_Content then w.UTRichText_Content:SetText("AnuragXcat - MENU") end end)
    for i = 1, 8 do pcall(function() if w["CanvasPanel_Tab_" .. i] then w["CanvasPanel_Tab_" .. i]:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end end) end
    pcall(function()
        local popup = w.Common_Popup_Large_UIBP
        if popup and valid(popup) and popup.close and valid(popup.close) then
            if popup.close.OnClicked then popup.close.OnClicked:Clear(); popup.close.OnClicked:Add(function() self:Close() end) end
        end
    end)
    self:BuildUI(w)
    self.menuWidget = w
end

function ModMenu:Toggle() if self.menuWidget and valid(self.menuWidget) then self:Close() else self:Open() end end

function ModMenu:EnsureTrigger()
    if self.triggerWidget and valid(self.triggerWidget) then return end
    local tw = nil; pcall(function() tw = slua.loadUI(BTN_BP) end)
    if tw and valid(tw) then
        pcall(function() require("game_frontend_hud").AddToContainer(UIContainers.Top, tw, Z_TRIGGER) end)
        pcall(function() if tw.RichText_Content then local f = tw.RichText_Content.Font; f.Size = 14; tw.RichText_Content:SetFont(f); tw.RichText_Content:SetText("MENU") end end)
        pcall(function() if tw.Button_Temp and tw.Button_Temp.OnClicked then tw.Button_Temp.OnClicked:Add(function() self:Toggle() end) end end)
        pcall(function()
            local slot = import("WidgetLayoutLibrary").SlotAsCanvasSlot(tw)
            if slot then slot:SetAnchors(FAnchors(1, 0, 1, 0)); slot:SetAlignment(FVector2D(1, 0)); slot:SetPosition(FVector2D(-16, 72)); slot:SetSize(FVector2D(72, 44)) end
            tw:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        self.triggerWidget = tw
    end
end

-- Auto-init trigger button
pcall(function()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(3.0, false, function()
            pcall(function() ModMenu:EnsureTrigger() end)
        end)
    else
        pcall(function() ModMenu:EnsureTrigger() end)
    end
end)

print("[MOD] Standalone UI loaded — tap MENU button to open")

-- ================================================================
--  POPUP MESSAGES
-- ================================================================
pcall(function()
    local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
    if not Msg then Msg = require("client.slua.logic.common.logic_common_msg_box") end
    if Msg and Msg.Show then
        Msg.Show(4, "AnuragXcat", "COMPLETE BYPASS ACTIVE\n ANTICHEAT KI MKC\nPlay Safe")
    end
end)

pcall(function()
    local function showSecondMsg()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        if not Msg then Msg = require("client.slua.logic.common.logic_common_msg_box") end
        if Msg and Msg.Show then
            Msg.Show(4, "AnuragXcat", "Use the MENU button to toggle hacks.\nIf Aimbot does not work, check if\nAimbot Assist is enabled in game settings.\nMemory features: Speed Boost, Anti-Gravity,\nWall Climb, Char Rotation, Scale,\nSuper Bullet, Super Fire Rate, Infinite Ammo.")
        end
    end
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(2.0, false, showSecondMsg)
    else
        later(2.0, showSecondMsg)
    end
end)


-- ================================================================
--  BRPLAYERCHARACTERBASE CLASS METHODS (unchanged)
-- ================================================================

function BRPlayerCharacterBase:ctor()
end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
  self:InitAddSpecialMoveInfo()
  self.bCanNearDeathGiveup = true
  print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
  self:StartAdvancedSystems()
end

function BRPlayerCharacterBase:StartAdvancedSystems()
    if not Client then return end
    if not _G._ULTIMATE_BYPASS_INIT then
        ApplyAllBypasses()
        ApplyServerSideAndLogBypasses()
        _G._ULTIMATE_BYPASS_INIT = true
        print("[BYPASS] All security systems disabled.")
    end
    -- Start the main timer (if not already)
    if not _G._MainTimerHandle then
        StartMainTimer()
    end
    print("[HACKS] All features OFF by default. Use MENU to enable/configure.")
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
  if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
    local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
    if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
      print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
      Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
    end
  end
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bPositiveBlowUp = true
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
      AttrName = {
        "bCanSelfRescue"
      }
    }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
    printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", self.PlayerKey)
    GameplayData.AddCharacter(self.Object)
    self:AddControlEvent(self, "OnAttachedToVehicle", self.HandleOnAttachedToVehicle, self)
    self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleOnDetachedFromVehicle, self)
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
      [1] = "FinishedState"
    }, self.HandleFinishedState, self)
  end
end

-- ================================================================
--  REMAINING ORIGINAL METHODS (truncated for brevity)
--  All original methods from the decompiled file are kept intact.
-- ================================================================

function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle)
  if not slua.isValid(uVehicle) then
    return
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:HandleOnAttachedToVehicle", Game:GetObjName(uVehicle)))
  if self.Role == ENetRole.ROLE_SimulatedProxy then
    self:ClearAttachToVehicleTimer()
    self.nUpdatePlayerAttachToVehicleCount = 0
    self.nUpdatePlayerAttachToVehicleTimer = self:AddGameTimer(5, true, function()
      if slua.isValid(self.Object) and slua.isValid(uVehicle) then
        self:UpdatePlayerAttachToVehicle(uVehicle)
      end
    end)
    self.nFixMeshContainerTimer = self:AddGameTimer(3, true, function()
      if slua.isValid(self.Object) and slua.isValid(uVehicle) then
        self:FixMeshContainerOffsetIfNeeded(uVehicle)
      end
    end)
  end
end

function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle)
  if not slua.isValid(uLastVehicle) then
    return
  end
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnDetachedFromVehicle", uLastVehicle)
  if self.Role == ENetRole.ROLE_SimulatedProxy then
    self:ClearAttachToVehicleTimer()
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
end

function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle(uVehicle)
  if not slua.isValid(self.Object) or not slua.isValid(uVehicle) then
    return
  end
  if not (slua.isValid(self.CapsuleComponent) and slua.isValid(self.Mesh)) or not slua.isValid(self.MeshContainer) then
    return
  end
  if not slua.isValid(self:GetCurrentVehicle()) then
    return
  end
  if Game:IsDriver(self.Object) then
    return
  end
  if not self.nUpdatePlayerAttachToVehicleCount then
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
  local ESTEPoseState = import("ESTEPoseState")
  local bStand = self.PoseState == ESTEPoseState.Stand
  local uActorRelativeLocation = self.CapsuleComponent:GetRelativeTransform():GetLocation()
  local uMeshRelativeLocation = self.Mesh:GetRelativeTransform():GetLocation()
  local uMeshContainerRelativeLocationZ = self.MeshContainer:GetRelativeTransform():GetLocation().Z
  local nCapsuleRadius = self.CapsuleComponent:GetScaledCapsuleRadius()
  local nCapsuleHalfHeight = self.CapsuleComponent:GetScaledCapsuleHalfHeight()
  local uMeshContainerExpectedZ = -1 * self.StandHalfHeight
  local nExpectedCapsuleRadius = self.StandRadius
  local nExpectedCapsuleHalfHeight = self.StandHalfHeight
  local uMeshExpectedRL = FVector(0, 0, 0)
  local uActorExpectedRL = FVector(0, 0, self.StandHalfHeight)
  local nTolerance = 1.0
  local bCapsuleRLCorrect = uActorRelativeLocation:Equals(uActorExpectedRL, nTolerance)
  local bMeshRLCorrect = uMeshRelativeLocation:Equals(uMeshExpectedRL, nTolerance)
  local bMeshContainerRLCorrect = nTolerance > math.abs(uMeshContainerRelativeLocationZ - uMeshContainerExpectedZ)
  local bCapsuleRadiusCorrect = nTolerance > math.abs(nCapsuleRadius - nExpectedCapsuleRadius)
  local bCapsuleHalfHeightCorrect = nTolerance > math.abs(nCapsuleHalfHeight - nExpectedCapsuleHalfHeight)
  local bAllCorrect = bStand and bCapsuleRLCorrect and bMeshRLCorrect and bMeshContainerRLCorrect and bCapsuleRadiusCorrect and bCapsuleHalfHeightCorrect
  if not bAllCorrect then
    self.nUpdatePlayerAttachToVehicleCount = self.nUpdatePlayerAttachToVehicleCount + 1
  else
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:UpdatePlayerAttachToVehicle PlayerKey:%s. bAllCorrect=%s Check Result:%d %d %d %d %d %d, Count:%d", tostring(self.PlayerKey), tostring(bAllCorrect), bStand and 1 or 0, bCapsuleRLCorrect and 1 or 0, bMeshRLCorrect and 1 or 0, bMeshContainerRLCorrect and 1 or 0, bCapsuleRadiusCorrect and 1 or 0, bCapsuleHalfHeightCorrect and 1 or 0, self.nUpdatePlayerAttachToVehicleCount))
  if self.nUpdatePlayerAttachToVehicleCount >= 3 and not bAllCorrect then
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local uPlayerController = GameplayData.GetPlayerController()
    if uPlayerController.ReportCrashKitFeature and uPlayerController.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException then
      local sReportInfo = string.format("VehicleShapeType:%s PlayerKey:%s. Check Result:%d %d %d %d %d %d. Capsule.RelativeLoc:%s Capsule.Radius:%s Capsule.HalfHeight:%s Mesh.RelativeLoc:%s MeshContainer.RelativeLocZ:%s", tostring(uVehicle.VehicleShapeType), tostring(self.PlayerKey), bStand and 1 or 0, bCapsuleRLCorrect and 1 or 0, bMeshRLCorrect and 1 or 0, bMeshContainerRLCorrect and 1 or 0, bCapsuleRadiusCorrect and 1 or 0, bCapsuleHalfHeightCorrect and 1 or 0, uActorRelativeLocation:ToString(), tostring(nCapsuleRadius), tostring(nCapsuleHalfHeight), uMeshRelativeLocation:ToString(), tostring(uMeshContainerRelativeLocationZ))
      uPlayerController.ReportCrashKitFeature:ReportCharacterAttachedOnVehicleException(sReportInfo)
    end
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
end

function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded(uVehicle)
  if not slua.isValid(self.Object) or not slua.isValid(uVehicle) then
    return
  end
  if not slua.isValid(self.MeshContainer) then
    return
  end
  if not slua.isValid(self:GetCurrentVehicle()) then
    return
  end
  if Game:IsDriver(self.Object) then
    return
  end
  local nTolerance = 1.0
  local uMeshContainerExpectedZ = -1 * self.StandHalfHeight
  local uMeshContainerRelativeLocationZ = self.MeshContainer:GetRelativeTransform():GetLocation().Z
  if nTolerance <= math.abs(uMeshContainerRelativeLocationZ - uMeshContainerExpectedZ) then
    print(bWriteLog and string.format("BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded PlayerKey:%s. SetMeshContainerOffsetZ from:%s to:%s", tostring(self.PlayerKey), tostring(uMeshContainerRelativeLocationZ), tostring(uMeshContainerExpectedZ)))
    self:SetMeshContainerOffsetZ(uMeshContainerExpectedZ)
  end
end

function BRPlayerCharacterBase:ClearAttachToVehicleTimer()
  if self.nUpdatePlayerAttachToVehicleTimer then
    self:RemoveGameTimer(self.nUpdatePlayerAttachToVehicleTimer)
    self.nUpdatePlayerAttachToVehicleTimer = nil
  end
  if self.nFixMeshContainerTimer then
    self:RemoveGameTimer(self.nFixMeshContainerTimer)
    self.nFixMeshContainerTimer = nil
  end
end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
  if self.Object ~= uPawn then
    return
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  print("BRPlayerCharacterBase:OnPawnStateChange:", PawnState)
  local EPawnState = import("EPawnState")
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  print(bWriteLog and "BRPlayerCharacterBase:HandleFinishedState", self.STCharacterMovement)
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfig then
    self.STCharacterMovement:SetDynamicSimpleQueryConfig(false)
  end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local EGameModeType = import("EGameModeType")
    local MatchModeIds = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")
    local GameModeType = CGameMode.GameModeType
    local GameModeID = tonumber(CGameState.GameModeID)
    local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
    local bModeIDSatisfy = not MatchModeIds[GameModeID]
    print(bWriteLog and bWriteLog and "BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent:", GameModeType, GameModeID, bModeTypeSatisfy, bModeIDSatisfy)
    return bModeTypeSatisfy and bModeIDSatisfy
  end
  return false
end

function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
  local EParachuteState = import("EParachuteState")
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if NewParachuteState == EParachuteState.PS_Opening then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
          uCurrentPlayerControl.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
        end
      elseif NewParachuteState == EParachuteState.PS_None then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
          uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
        end
        if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
          uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
        end
      end
    end
  end
end

function BRPlayerCharacterBase:OnLanded()
  printf("BRPlayerCharacterBase:OnLanded PlayerKey:%d", self.PlayerKey)
  if self.HandleOnLanded then
    self:HandleOnLanded(-1)
  end
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
      end
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI()
      end
    end
  end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:IsWarGameMode()
  local GameplayData = require("GameLua.GameCore.Data.GameplayData")
  local uGameState = GameplayData:GetGameState()
  local STExtraGameStateBase = import("STExtraGameStateBase")
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
    local EGameModeType = import("EGameModeType")
    return uGameState.GameModeType == EGameModeType.EWarGameMode
  else
    return false
  end
end

function BRPlayerCharacterBase:BPOnRecycled()
  print(bWriteLog and string.format("%s BPOnRecycled()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:BPOnRespawned()
  print(bWriteLog and string.format("%s BPOnRespawned()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.AddCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
  if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
    local uDefaultMeshRot = FRotator(0, -90, 0)
    local uDefaultMeshRelativeLoc = FVector(0, 0, 0)
    if self.Mesh.K2_SetRelativeRotation then
      self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false)
    end
    self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
    local vRelativeRot = self.Mesh.RelativeRotation
    local vBaseRotationOffset = self.BaseRotationOffset
    local vBaseRotation = Game:QuatToRotator(vBaseRotationOffset)
    print(bWriteLog and bWriteLog and string.format("%s ResetMeshRelativeLocationAndRotation() Mesh.RelativeRotation: %s %s %s   Pawn.BaseRotationOffset:%s %s %s ", Game:GetPlainName(self.Object), tostring(vRelativeRot.Pitch), tostring(vRelativeRot.Yaw), tostring(vRelativeRot.Roll), tostring(vBaseRotation.Pitch), tostring(vBaseRotation.Yaw), tostring(vBaseRotation.Roll)))
  end
end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
  local EMovementMode = import("EMovementMode")
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end

function BRPlayerCharacterBase:PreAttachedToVehicle()
  local UKismetSystemLibrary = import("KismetSystemLibrary")
  local IsDS = UKismetSystemLibrary.IsDedicatedServer(self)
  if not IsDS then
    return
  end
  local MainPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(MainPlayerController) then
    return
  end
  local CharacterAvatarComp2_BP = self.CharacterAvatarComp2_BP
  if not slua.isValid(CharacterAvatarComp2_BP) then
    return
  end
  local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
  local changedVehicleId = CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
  local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
  if changedVehicleId then
    local UAvatarUtils = import("AvatarUtils")
    if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId) == ESTExtraVehicleShapeType.VST_Horse then
      local uCurPlayerState = self:GetPlayerStateSafety()
      if slua.isValid(uCurPlayerState) then
        print(bWriteLog and "  BRPlayerCharacterBase:PreAttachedToVehicle. changedVehicleId: " .. tostring(changedVehicleId))
        uCurPlayerState:AddGeneralCount(468, 1, false)
      end
    end
  end
end

BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.UInt32,
    UEnums.EPropertyClass.UInt32
  }
}

function BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment(Type, Param)
  print(bWriteLog and string.format("BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment Type = %d, Param = %s", Type, Param))
  EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_TRIGGER_HIGHLIGHT_MOMENT, Type, Param)
end

function BRPlayerCharacterBase:ParachuteJump()
  local uPlayerController = self:GetControllerSafety()
  if slua.isValid(uPlayerController) then
    if not self:GetEnsure() then
      local EStateType = import("EStateType")
      if uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
        local ESTEPoseState = import("ESTEPoseState")
        self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
        uPlayerController:ReInitParachuteItem()
        uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
      end
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump over")
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump AI JUMP over, Loc=", tostring(self:K2_GetActorLocation():ToString()))
    end
  end
end

function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
  if uCharacter ~= self.Object then
    return
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:OnMovementBaseChangedEvent %s, Base: %s -> %s", uCharacter, uOldMovementBase, uNewMovementBase))
  local MedievalCrane = self:GetMedievalCraneFromBase(uNewMovementBase)
  if MedievalCrane and MedievalCrane.AddCharacter then
    MedievalCrane:AddCharacter(self.Object)
  else
    MedievalCrane = self:GetMedievalCraneFromBase(uOldMovementBase)
    if MedievalCrane and MedievalCrane.RemoveCharacter then
      MedievalCrane:RemoveCharacter(self.Object)
    end
  end
end

function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
  if not slua.isValid(Base) or not Base.GetOwner then
    return
  end
  local Lifter = Base:GetOwner()
  if not slua.isValid(Lifter) then
    return
  end
  if not Lifter.AddCharacter then
    return
  end
  return Lifter
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
  local uPlayerState = self:GetPlayerStateSafety()
  if not slua.isValid(uPlayerState) then
    return false
  end
  if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:DisplayGameTipWithMsgID(48532)
    end
  end
  return not uPlayerState.CanUseFlaregun
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
  self:HandleNearDeathGiveupRescue()
end

function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
  local uNearDeathComp = self.NearDeatchComponent
  if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
    local uPlayerState = self:GetPlayerStateSafety()
    if slua.isValid(uPlayerState) then
      uPlayerState:AddGeneralCount(1613, 1, false)
    end
    uNearDeathComp:TriggerGotoDieExplictly(self.Object)
  end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
  log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction.  actionId: " .. tostring(actionId))
  local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
    log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction. IsDevelopment actionId: " .. tostring(actionId))
    self:MulticastRPC_GmPlayAction(actionId)
  end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then
    return
  end
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction.  actionId: " .. tostring(actionId))
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then
    return
  end
  local LogFilter = require("common.log_filter")
  LogFilter.SetLogTreeEnable(true)
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then
    return
  end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction. assetsArray:Num(): " .. tostring(assetsArray:Num()))
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")
  
  function loadLater()
    uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
  end
  
  asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
  print(bWriteLog and "BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall " .. tostring(bServerSyncShouldCheckPassWall))
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerEnterCarryBoxState Role:%s PlayerKey:%s Name:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
  end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState Role:%s PlayerKey:%s Name:%s bInIsInterrupt:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName), tostring(bInIsInterrupt)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
  if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
  end
end

function BRPlayerCharacterBase:SetAreaID(AreaID)
  self:SetAttrValue("AreaID", AreaID, -1)
end

function BRPlayerCharacterBase:GetAreaID()
  return math.floor(self:GetAttrValue("AreaID") + 0.5)
end

function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
  print(bWriteLog and "BRPlayerCharacterBase:CannotChangeIntoPetSpectator")
  return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
  print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s", tostring(self.PlayerKey)))
  if self:HasState(EPawnState.SpecialSuit) then
    self:TriggerEntrySkillWithID(4301101, true)
    print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s, HasState(EPawnState.SpecialSuit)", tostring(self.PlayerKey)))
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening")
  self.Super:SwitchCameraToParachuteOpening()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling")
  self.Super:SwitchCameraToParachuteFalling()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToNormal")
  self.Super:SwitchCameraToNormal()
  if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
    self.ParachuteFormation:OnLandingClearFormationCamera()
  end
end

function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
  if self:HasState(EPawnState.AttachToOther) then
    local Weapon = self:GetWeaponBySlot(Slot)
    if slua.isValid(Weapon) then
      local WeaponID = Weapon:GetWeaponID()
      local AttachToOtherConfig = GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
      if AttachToOtherConfig and AttachToOtherConfig.CheckIsWeaponInBlackList and AttachToOtherConfig.CheckIsWeaponInBlackList(WeaponID) then
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck not allow switch weapon in AttachToOther, WeaponID: " .. tostring(WeaponID))
        local uPlayerController = self:GetPlayerControllerSafety()
        if Client and slua.isValid(uPlayerController) and uPlayerController.Role == ENetRole.ROLE_AutonomousProxy then
          uPlayerController:DisplayGameTipWithMsgID(47306)
        end
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

-- ================================================================
--  CLASS DECLARATION (must be at the end)
-- ================================================================
local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
  { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
  { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
  { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
  { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
  { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
  { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
  { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
  { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" }
}, "BRPlayerCharacterBase")