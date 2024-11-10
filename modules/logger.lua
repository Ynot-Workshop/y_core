local isServer = IsDuplicityVersion()
if not isServer then
    lib.print.error('cannot use the logger on the client')
    return
end

local useFMSDK = require 'config.server'.logging.useFMSDK
local logQueue, isProcessingQueue = {}, false
local lastRequestTime, requestDelay = 0, 500

---Log Queue
local function applyRequestDelay()
    local currentTime = GetGameTimer()
    local timeDiff = currentTime - lastRequestTime

    if timeDiff < requestDelay then
        local remainingDelay = requestDelay - timeDiff

        Wait(remainingDelay)
    end

    lastRequestTime = GetGameTimer()
end

---Log Queue
---@param payload Log Queue
local function logPayload(payload)
    if useFMSDK then
        exports.fmsdk:LogMessage(payload.level or 'info', payload.message, payload.metadata or {playerSource = payload.source})
        return
    end
    lib.logger(payload.source, payload.event, payload.message, payload.oxLibTags) -- support for ox_lib: datadog, grafana loki logging, fivemanage
end

---Log Queue to avoid spam
local function processLogQueue()
    if #logQueue > 0 then
        local payload = table.remove(logQueue, 1)

        logPayload(payload)

        applyRequestDelay()
        processLogQueue()
    else
        isProcessingQueue = false
    end
end

---@class Log
---@field source string source of the log. Usually a playerId or name of a resource.
---@field event string the action or 'event' being logged. Usually a verb describing what the name is doing. Example: SpawnVehicle
---@field message string the message attached to the log
---@field oxLibTags? string -- Tags for ox_lib logger
---@field level? string -- log Level for fivemanage
---@field metadata? table<string, any> metadata for the log (Fivemanage only)

---Logs using ox_lib, if ox_lib logging is configured. Additionally logs to discord if a web hook is passed.
---@param log Log
local function createLog(log)
    logQueue[#logQueue + 1] = log

    if not isProcessingQueue then
        isProcessingQueue = true
        CreateThread(processLogQueue)
    end
end

return {
    log = createLog
}
