local defaultSpawn = require 'config.shared'.defaultSpawn
local characterDataTables = require 'config.server'.characterDataTables

local function createUsersTable()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `users` (
            `userId` int UNSIGNED NOT NULL AUTO_INCREMENT,
            `username` varchar(255) DEFAULT NULL,
            `license` varchar(50) DEFAULT NULL,
            `license2` varchar(50) DEFAULT NULL,
            `fivem` varchar(20) DEFAULT NULL,
            `discord` varchar(30) DEFAULT NULL,
            PRIMARY KEY (`userId`)
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end

---@param identifiers table<PlayerIdentifier, string>
---@return number?
local function createUser(identifiers)
    return MySQL.insert.await('INSERT INTO users (username, license, license2, fivem, discord) VALUES (?, ?, ?, ?, ?)', {
        identifiers.username,
        identifiers.license,
        identifiers.license2,
        identifiers.fivem,
        identifiers.discord,
    })
end

---@param identifier string
---@return number?
local function fetchUserByIdentifier(identifier)
    local idType = identifier:match('([^:]+)')
    local select = ('SELECT `userId` FROM `users` WHERE `%s` = ? LIMIT 1'):format(idType)

    return MySQL.scalar.await(select, { identifier })
end

---@param request InsertBanRequest
---@return boolean success
---@return ErrorResult? errorResult
local function insertBan(request)
    if not request.discordId and not request.ip and not request.license then
        return false, {
            code = 'no_identifier',
            message = 'discordId, ip, or license required in the ban request'
        }
    end

    MySQL.insert.await('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        request.name,
        request.license,
        request.discordId,
        request.ip,
        request.reason,
        request.expiration,
        request.bannedBy,
    })
    return true
end

---@param request GetBanRequest
---@return string column in storage
---@return string value of the id
local function getBanId(request)
    if request.license then
        return 'license', request.license
    elseif request.discordId then
        return 'discord', request.discordId
    elseif request.ip then
        return 'ip', request.ip
    else
        error('no identifier provided', 2)
    end
end

---@param request GetBanRequest
---@return BanEntity?
local function fetchBan(request)
    local column, value = getBanId(request)
    local result = MySQL.single.await('SELECT expire, reason FROM bans WHERE ' ..column.. ' = ?', { value })
    return result and {
        expire = result.expire,
        reason = result.reason,
    } or nil
end

---@param request GetBanRequest
local function deleteBan(request)
    local column, value = getBanId(request)
    MySQL.query.await('DELETE FROM bans WHERE ' ..column.. ' = ?', { value })
end

---@param request UpsertPlayerRequest
local function upsertPlayerEntity(request)
    MySQL.insert.await('INSERT INTO players (citizenid, cid, license, name, money, charinfo, job, gang, position, metadata, last_logged_out) VALUES (:citizenid, :cid, :license, :name, :money, :charinfo, :job, :gang, :position, :metadata, :last_logged_out) ON DUPLICATE KEY UPDATE name = :name, money = :money, charinfo = :charinfo, job = :job, gang = :gang, position = :position, metadata = :metadata, last_logged_out = :last_logged_out', {
        citizenid = request.playerEntity.citizenid,
        cid = request.playerEntity.charinfo.cid,
        license = request.playerEntity.license,
        name = request.playerEntity.name,
        money = json.encode(request.playerEntity.money),
        charinfo = json.encode(request.playerEntity.charinfo),
        job = json.encode(request.playerEntity.job),
        gang = json.encode(request.playerEntity.gang),
        position = json.encode(request.position),
        metadata = json.encode(request.playerEntity.metadata),
        last_logged_out = os.date('%Y-%m-%d %H:%M:%S', request.playerEntity.lastLoggedOut)
    })
end

---@param citizenId string
---@return PlayerSkin?
local function fetchPlayerSkin(citizenId)
    return MySQL.single.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = 1', {citizenId})
end

local function convertPosition(position)
    local pos = json.decode(position)
    local actualPos = (not pos.x or not pos.y or not pos.z) and defaultSpawn or pos
    return vec4(actualPos.x, actualPos.y, actualPos.z, actualPos.w or defaultSpawn.w)
end

---@param license2 string
---@param license? string
---@return PlayerEntity[]
local function fetchAllPlayerEntities(license2, license)
    ---@type PlayerEntity[]
    local chars = {}
    ---@type PlayerEntityDatabase[]
    local result = MySQL.query.await('SELECT citizenid, charinfo, money, job, gang, position, metadata, UNIX_TIMESTAMP(last_logged_out) AS lastLoggedOutUnix FROM players WHERE license = ? OR license = ? ORDER BY cid', {license, license2})
    for i = 1, #result do
        chars[i] = result[i]
        chars[i].charinfo = json.decode(result[i].charinfo)
        chars[i].money = json.decode(result[i].money)
        chars[i].job = result[i].job and json.decode(result[i].job)
        chars[i].gang = result[i].gang and json.decode(result[i].gang)
        chars[i].position = convertPosition(result[i].position)
        chars[i].metadata = json.decode(result[i].metadata)
        chars[i].lastLoggedOut = result[i].lastLoggedOutUnix
    end

    return chars
end

---@param citizenId string
---@return PlayerEntity?
local function fetchPlayerEntity(citizenId)
    ---@type PlayerEntityDatabase
    local player = MySQL.single.await('SELECT citizenid, license, name, charinfo, money, job, gang, position, metadata, UNIX_TIMESTAMP(last_logged_out) AS lastLoggedOutUnix FROM players WHERE citizenid = ?', { citizenId })
    local charinfo = player and json.decode(player.charinfo)
    return player and {
        citizenid = player.citizenid,
        license = player.license,
        name = player.name,
        money = json.decode(player.money),
        charinfo = charinfo,
        cid = charinfo.cid,
        job = player.job and json.decode(player.job),
        gang = player.gang and json.decode(player.gang),
        position = convertPosition(player.position),
        metadata = json.decode(player.metadata),
        lastLoggedOut = player.lastLoggedOutUnix
    } or nil
end

--- TODO: remove?
---@param filters table<string, any>
local function handleSearchFilters(filters)
    if not (filters) then return '', {} end
    local holders = {}
    local clauses = {}
    if filters.license then
        clauses[#clauses + 1] = 'license = ?'
        holders[#holders + 1] = filters.license
    end
    if filters.job then
        clauses[#clauses + 1] = 'JSON_EXTRACT(job, "$.name") = ?'
        holders[#holders + 1] = filters.job
    end
    if filters.gang then
        clauses[#clauses + 1] = 'JSON_EXTRACT(gang, "$.name") = ?'
        holders[#holders + 1] = filters.gang
    end
    if filters.metadata then
        local strict = filters.metadata.strict
        for key, value in pairs(filters.metadata) do
            if key ~= "strict" then
                if type(value) == "number" then
                    if strict then
                        clauses[#clauses + 1] = 'JSON_EXTRACT(metadata, "$.' .. key .. '") = ?'
                    else
                        clauses[#clauses + 1] = 'JSON_EXTRACT(metadata, "$.' .. key .. '") >= ?'
                    end
                    holders[#holders + 1] = value
                elseif type(value) == "boolean" then
                    clauses[#clauses + 1] = 'JSON_EXTRACT(metadata, "$.' .. key .. '") = ?'
                    holders[#holders + 1] = tostring(value)
                elseif type(value) == "string" then
                    clauses[#clauses + 1] = 'JSON_UNQUOTE(JSON_EXTRACT(metadata, "$.' .. key .. '")) = ?'
                    holders[#holders + 1] = value
                end
            end
        end
    end
    return (' WHERE %s'):format(table.concat(clauses, ' AND ')), holders
end

---@param filters table <string, any>
---@return PlayerEntityDatabase[]
local function searchPlayerEntities(filters)
    local query = "SELECT citizenid FROM players"
    local where, holders = handleSearchFilters(filters)
    lib.print.debug(query .. where)
    ---@type PlayerEntityDatabase[]
    local response = MySQL.query.await(query .. where, holders)
    return response
end

---Checks if a table exists in the database
---@param tableName string
---@return boolean
local function doesTableExist(tableName)
    local tbl = MySQL.single.await(('SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_NAME = \'%s\' AND TABLE_SCHEMA in (SELECT DATABASE())'):format(tableName))
    return tbl['COUNT(*)'] > 0
end

---deletes character data using the characterDataTables object in the config file
---@param citizenId string
---@return boolean success if operation is successful.
local function deletePlayer(citizenId)
    local query = 'DELETE FROM %s WHERE %s = ?'
    local queries = {}

    for i = 1, #characterDataTables do
        local data = characterDataTables[i]
        local tableName = data[1]
        local columnName = data[2]
        if doesTableExist(tableName) then
            queries[#queries + 1] = {
                query = query:format(tableName, columnName),
                values = {
                    citizenId,
                }
            }
        else
            warn(('Table %s does not exist in database, please remove it from qbx_core/config/server.lua or create the table'):format(tableName))
        end
    end

    local success = MySQL.transaction.await(queries)
    return not not success
end

---checks the storage for uniqueness of the given value
---@param type UniqueIdType
---@param value string|number
---@return boolean isUnique if the value does not already exist in storage for the given type
local function fetchIsUnique(type, value)
    local typeToColumn = {
        citizenid = 'citizenid',
        AccountNumber = "JSON_VALUE(charinfo, '$.account')",
        PhoneNumber = "JSON_VALUE(charinfo, '$.phone')",
        FingerId = "JSON_VALUE(metadata, '$.fingerprint')",
        SerialNumber = "JSON_VALUE(metadata, '$.phonedata.SerialNumber')",
    }

    local result = MySQL.single.await('SELECT COUNT(*) as count FROM players WHERE ' .. typeToColumn[type] .. ' = ?', { value })
    return result.count == 0
end

return {
    createUsersTable = createUsersTable,
    createUser = createUser,
    fetchUserByIdentifier = fetchUserByIdentifier,
    insertBan = insertBan,
    fetchBan = fetchBan,
    deleteBan = deleteBan,
    upsertPlayerEntity = upsertPlayerEntity,
    fetchPlayerSkin = fetchPlayerSkin,
    fetchPlayerEntity = fetchPlayerEntity,
    fetchAllPlayerEntities = fetchAllPlayerEntities,
    deletePlayer = deletePlayer,
    fetchIsUnique = fetchIsUnique,
    searchPlayerEntities = searchPlayerEntities,
}