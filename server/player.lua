local config = require 'config.server'
local defaultSpawn = require 'config.shared'.defaultSpawn
local logger = require 'modules.logger'
local storage = require 'server.storage.main'
local accounts = json.decode(GetConvar('inventory:accounts', '["money"]'))
local accountsAsItems = table.create(0, #accounts)

for i = 1, #accounts do
    accountsAsItems[accounts[i]] = 0
end

---@param source Source
---@param citizenid? string
---@param newData? PlayerEntity
---@return boolean success
function Login(source, citizenid, newData)
    if not source or source == '' then
        lib.print.error('No source given at login stage')
        return false
    end

    if citizenid then
        local license, license2 = GetPlayerIdentifierByType(source --[[@as string]], 'license'), GetPlayerIdentifierByType(source --[[@as string]], 'license2')
        local playerData = storage.fetchPlayerEntity(citizenid)
        if playerData and (license2 == playerData.license or license == playerData.license) then
            return not not CheckPlayerData(source, playerData)
        else
            DropPlayer(tostring(source), locale('info.exploit_dropped'))
            logger.log({
                source = citizenid,
                event = 'Anti-Cheat',
                message = ('%s has been dropped for character joining exploit'):format(GetPlayerName(source)),
                metadata = {
                    citizenid = citizenid
                }
            })
        end
    else
        local player = CheckPlayerData(source, newData)
        Save(player.PlayerData.source)
        return true
    end

    return false
end

exports('Login', Login)

---@param citizenid string
---@return Player? player if found in storage
function GetOfflinePlayer(citizenid)
    if not citizenid then return end
    local playerData = storage.fetchPlayerEntity(citizenid)
    if not playerData then return end
    return CheckPlayerData(nil, playerData)
end

exports('GetOfflinePlayer', GetOfflinePlayer)

---@param source? integer if player is online
---@param playerData? PlayerEntity|PlayerData
---@return Player player
function CheckPlayerData(source, playerData)
    playerData = playerData or {}
    ---@diagnostic disable-next-line: param-type-mismatch
    local playerState = Player(source)?.state
    local Offline = true
    if source then
        playerData.source = source
        playerData.license = playerData.license or GetPlayerIdentifierByType(source --[[@as string]], 'license2') or GetPlayerIdentifierByType(source --[[@as string]], 'license')
        playerData.name = GetPlayerName(source)
        Offline = false
    end

    playerData.citizenid = playerData.citizenid or GenerateUniqueIdentifier('citizenid')
    playerData.money = playerData.money or {}
    playerData.optin = playerData.optin or true
    ---TODO: make money stuff better (only cash in core?)
    for moneytype, startamount in pairs(config.money.moneyTypes) do
        playerData.money[moneytype] = playerData.money[moneytype] or startamount
    end

    -- Charinfo
    playerData.charinfo = playerData.charinfo or {}
    playerData.charinfo.firstname = playerData.charinfo.firstname or 'Firstname'
    playerData.charinfo.lastname = playerData.charinfo.lastname or 'Lastname'
    playerData.charinfo.birthdate = playerData.charinfo.birthdate or '00-00-0000'
    playerData.charinfo.gender = playerData.charinfo.gender or 0
    playerData.charinfo.nationality = playerData.charinfo.nationality or 'USA'

    -- Metadata
    playerData.metadata = playerData.metadata or {}
    playerData.metadata.health = playerData.metadata.health or 200
    playerData.metadata.hunger = playerData.metadata.hunger or 100
    playerData.metadata.thirst = playerData.metadata.thirst or 100
    playerData.metadata.stress = playerData.metadata.stress or 0

    if playerState then
        playerState:set('hunger', playerData.metadata.hunger, true)
        playerState:set('thirst', playerData.metadata.thirst, true)
        playerState:set('stress', playerData.metadata.stress, true)
    end

    playerData.metadata.isdead = playerData.metadata.isdead or false
    playerData.metadata.inlaststand = playerData.metadata.inlaststand or false
    playerData.metadata.armor = playerData.metadata.armor or 0
    playerData.metadata.ishandcuffed = playerData.metadata.ishandcuffed or false
    playerData.metadata.tracker = playerData.metadata.tracker or false
    playerData.metadata.status = playerData.metadata.status or {}
    playerData.metadata.bloodtype = playerData.metadata.bloodtype or config.player.bloodTypes[math.random(1, #config.player.bloodTypes)]
    playerData.metadata.dealerrep = playerData.metadata.dealerrep or 0
    playerData.metadata.attachmentcraftingrep = playerData.metadata.attachmentcraftingrep or 0

    playerData.metadata.craftingrep = playerData.metadata.craftingrep or 0
    playerData.metadata.jobrep = playerData.metadata.jobrep or {}
    playerData.metadata.jobrep.tow = playerData.metadata.jobrep.tow or 0
    playerData.metadata.jobrep.trucker = playerData.metadata.jobrep.trucker or 0
    playerData.metadata.jobrep.taxi = playerData.metadata.jobrep.taxi or 0
    playerData.metadata.jobrep.hotdog = playerData.metadata.jobrep.hotdog or 0

    playerData.metadata.callsign = playerData.metadata.callsign or 'NO CALLSIGN'
    playerData.metadata.fingerprint = playerData.metadata.fingerprint or GenerateUniqueIdentifier('FingerId')
    playerData.metadata.licences = playerData.metadata.licences or {
        id = true,
        driver = false,
        weapon = false,
    }

    if playerData.job and playerData.job.name and not QBX.Shared.Jobs[playerData.job.name] then playerData.job = nil end
    playerData.job = playerData.job or {}
    playerData.job.name = playerData.job.name or 'unemployed'
    playerData.job.label = playerData.job.label or 'Civilian'
    playerData.job.payment = playerData.job.payment or 10
    playerData.job.offDutyPay = playerData.job.offDutyPay or QBX.Shared.Jobs[playerData.job.name].offDutyPay
    playerData.job.type = playerData.job.type or 'none'
    if QBX.Shared.ForceJobDefaultDutyAtLogin or playerData.job.onduty == nil then
        playerData.job.onduty = QBX.Shared.Jobs[playerData.job.name].defaultDuty
    end
    playerData.job.isboss = playerData.job.isboss or false
    playerData.job.grade = playerData.job.grade or {}
    playerData.job.grade.name = playerData.job.grade.name or 'Freelancer'
    playerData.job.grade.level = playerData.job.grade.level or 0

    if playerData.gang and playerData.gang.name and not QBX.Shared.Gangs[playerData.gang.name] then playerData.gang = nil end
    playerData.gang = playerData.gang or {}
    playerData.gang.name = playerData.gang.name or 'none'
    playerData.gang.label = playerData.gang.label or 'No Gang Affiliation'
    playerData.gang.isboss = playerData.gang.isboss or false
    playerData.gang.grade = playerData.gang.grade or {}
    playerData.gang.grade.name = playerData.gang.grade.name or 'none'
    playerData.gang.grade.level = playerData.gang.grade.level or 0

    playerData.position = playerData.position or defaultSpawn
    playerData.items = {}
    return CreatePlayer(playerData --[[@as PlayerData]], Offline)
end

---On player logout
---@param source Source
function Logout(source)
    local player = GetPlayer(source)
    if not player then return end
    local playerState = Player(source)?.state
    player.PlayerData.metadata.hunger = playerState?.hunger or player.PlayerData.metadata.hunger
    player.PlayerData.metadata.thirst = playerState?.thirst or player.PlayerData.metadata.thirst
    player.PlayerData.metadata.stress = playerState?.stress or player.PlayerData.metadata.stress

    TriggerClientEvent('QBCore:Client:OnPlayerUnload', source)
    TriggerEvent('QBCore:Server:OnPlayerUnload', source)

    player.PlayerData.lastLoggedOut = os.time()
    Save(player.PlayerData.source)

    Wait(200)
    QBX.Players[source] = nil
    GlobalState.PlayerCount -= 1
    TriggerClientEvent('qbx_core:client:playerLoggedOut', source)
    TriggerEvent('qbx_core:server:playerLoggedOut', source)
end

exports('Logout', Logout)

---Create a new character
---Don't touch any of this unless you know what you are doing
---Will cause major issues!
---@param playerData PlayerData
---@param Offline boolean
---@return Player player
function CreatePlayer(playerData, Offline)
    local self = {}
    self.Functions = {}
    self.PlayerData = playerData
    self.Offline = Offline

    ---@deprecated use UpdatePlayerData instead
    function self.Functions.UpdatePlayerData()
        if self.Offline then
            lib.print.warn('UpdatePlayerData is unsupported for offline players')
            return
        end

        UpdatePlayerData(self.PlayerData.source)
    end

    ---@param job string name
    ---@param grade integer
    ---@return boolean success if job was set
    function self.Functions.SetJob(job, grade)
        job = job or ''
        grade = tonumber(grade) or 0
        if not QBX.Shared.Jobs[job] then return false end
        self.PlayerData.job.name = job
        self.PlayerData.job.label = QBX.Shared.Jobs[job].label
        self.PlayerData.job.onduty = QBX.Shared.Jobs[job].defaultDuty
        self.PlayerData.job.type = QBX.Shared.Jobs[job].type or 'none'
        if QBX.Shared.Jobs[job].grades[grade] then
            local jobgrade = QBX.Shared.Jobs[job].grades[grade]
            self.PlayerData.job.grade = {}
            self.PlayerData.job.grade.name = jobgrade.name
            self.PlayerData.job.grade.level = grade
            self.PlayerData.job.payment = jobgrade.payment or 30
            self.PlayerData.job.isboss = jobgrade.isboss or false
        else
            self.PlayerData.job.grade = {}
            self.PlayerData.job.grade.name = 'No Grades'
            self.PlayerData.job.grade.level = 0
            self.PlayerData.job.payment = 30
            self.PlayerData.job.isboss = false
        end

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerEvent('QBCore:Server:OnJobUpdate', self.PlayerData.source, self.PlayerData.job)
            TriggerClientEvent('QBCore:Client:OnJobUpdate', self.PlayerData.source, self.PlayerData.job)
        end

        return true
    end


    ---@param gang string name
    ---@param grade integer
    ---@return boolean success if gang was set
    function self.Functions.SetGang(gang, grade)
        gang = gang or ''
        grade = tonumber(grade) or 0
        if not QBX.Shared.Gangs[gang] then return false end
        self.PlayerData.gang.name = gang
        self.PlayerData.gang.label = QBX.Shared.Gangs[gang].label
        if QBX.Shared.Gangs[gang].grades[grade] then
            local ganggrade = QBX.Shared.Gangs[gang].grades[grade]
            self.PlayerData.gang.grade = {}
            self.PlayerData.gang.grade.name = ganggrade.name
            self.PlayerData.gang.grade.level = grade
            self.PlayerData.gang.isboss = ganggrade.isboss or false
        else
            self.PlayerData.gang.grade = {}
            self.PlayerData.gang.grade.name = 'No Grades'
            self.PlayerData.gang.grade.level = 0
            self.PlayerData.gang.isboss = false
        end

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerEvent('QBCore:Server:OnGangUpdate', self.PlayerData.source, self.PlayerData.gang)
            TriggerClientEvent('QBCore:Client:OnGangUpdate', self.PlayerData.source, self.PlayerData.gang)
        end

        return true
    end

    ---@param onDuty boolean
    function self.Functions.SetJobDuty(onDuty)
        self.PlayerData.job.onduty = not not onDuty -- Make sure the value is a boolean if nil is sent
        TriggerEvent('QBCore:Server:SetDuty', self.PlayerData.source, self.PlayerData.job.onduty)
        TriggerClientEvent('QBCore:Client:SetDuty', self.PlayerData.source, self.PlayerData.job.onduty)
        self.Functions.UpdatePlayerData()
    end

    ---@param key string
    ---@param val any
    function self.Functions.SetPlayerData(key, val)
        SetPlayerData(self.PlayerData.source, key, val)
    end

    ---@deprecated use SetMetadata instead
    ---@param meta string
    ---@param val any
    function self.Functions.SetMetaData(meta, val)
        SetMetadata(self.PlayerData.source, meta, val)
    end

    ---@deprecated use GetMetadata instead
    ---@param meta string
    ---@return any
    function self.Functions.GetMetaData(meta)
        return GetMetadata(self.PlayerData.source, meta)
    end

    ---@deprecated use SetMetadata instead
    ---@param amount number
    function self.Functions.AddJobReputation(amount)
        if not amount then return end

        amount = tonumber(amount) --[[@as number]]

        self.PlayerData.metadata[self.PlayerData.job.name].reputation += amount

        ---@diagnostic disable-next-line: param-type-mismatch
        UpdatePlayerData(self.Offline and self.PlayerData.citizenid or self.PlayerData.source)
    end

    ---@param moneytype MoneyType
    ---@param amount number
    ---@param reason? string
    ---@return boolean success if money was added
    function self.Functions.AddMoney(moneytype, amount, reason)
        return AddMoney(self.PlayerData.source, moneytype, amount, reason)
    end

    ---@param moneytype MoneyType
    ---@param amount number
    ---@param reason? string
    ---@return boolean success if money was removed
    function self.Functions.RemoveMoney(moneytype, amount, reason)
        return RemoveMoney(self.PlayerData.source, moneytype, amount, reason)
    end

    ---@param moneytype MoneyType
    ---@param amount number
    ---@param reason? string
    ---@return boolean success if money was set
    function self.Functions.SetMoney(moneytype, amount, reason)
        return SetMoney(self.PlayerData.source, moneytype, amount, reason)
    end

    ---@param moneytype MoneyType
    ---@return boolean | number amount or false if moneytype does not exist
    function self.Functions.GetMoney(moneytype)
        return GetMoney(self.PlayerData.source, moneytype)
    end

    local function qbItemCompat(item)
        if not item then return end

        item.info = item.metadata
        item.amount = item.count

        return item
    end

    ---@param item string
    ---@return string
    local function oxItemCompat(item)
        return item == 'cash' and 'money' or item
    end

    ---@deprecated use ox_inventory exports directly
    ---@param item string
    ---@param amount number
    ---@param metadata? table
    ---@param slot? number
    ---@return boolean success
    function self.Functions.AddItem(item, amount, slot, metadata)
        assert(not self.Offline, 'unsupported for offline players')
        return exports.ox_inventory:AddItem(self.PlayerData.source, oxItemCompat(item), amount, metadata, slot)
    end

    ---@deprecated use ox_inventory exports directly
    ---@param item string
    ---@param amount number
    ---@param slot? number
    ---@return boolean success
    function self.Functions.RemoveItem(item, amount, slot)
        assert(not self.Offline, 'unsupported for offline players')
        return exports.ox_inventory:RemoveItem(self.PlayerData.source, oxItemCompat(item), amount, nil, slot)
    end

    ---@deprecated use ox_inventory exports directly
    ---@param slot number
    ---@return any table
    function self.Functions.GetItemBySlot(slot)
        assert(not self.Offline, 'unsupported for offline players')
        return qbItemCompat(exports.ox_inventory:GetSlot(self.PlayerData.source, slot))
    end

    ---@deprecated use ox_inventory exports directly
    ---@param itemName string
    ---@return any table
    function self.Functions.GetItemByName(itemName)
        assert(not self.Offline, 'unsupported for offline players')
        return qbItemCompat(exports.ox_inventory:GetSlotWithItem(self.PlayerData.source, oxItemCompat(itemName)))
    end

    ---@deprecated use ox_inventory exports directly
    ---@param itemName string
    ---@return any table
    function self.Functions.GetItemsByName(itemName)
        assert(not self.Offline, 'unsupported for offline players')
        return qbItemCompat(exports.ox_inventory:GetSlotsWithItem(self.PlayerData.source, oxItemCompat(itemName)))
    end

    ---@deprecated use ox_inventory exports directly
    function self.Functions.ClearInventory()
        assert(not self.Offline, 'unsupported for offline players')
        return exports.ox_inventory:ClearInventory(self.PlayerData.source)
    end

    ---@deprecated use ox_inventory exports directly
    function self.Functions.SetInventory()
        error('Player.Functions.SetInventory is unsupported for ox_inventory. Try ClearInventory, then add the desired items.')
    end

    ---@deprecated use SetCharInfo instead
    ---@param cardNumber number
    function self.Functions.SetCreditCard(cardNumber)
        self.PlayerData.charinfo.card = cardNumber

        ---@diagnostic disable-next-line: param-type-mismatch
        UpdatePlayerData(self.Offline and self.PlayerData.citizenid or self.PlayerData.source)
    end

    ---@deprecated use Save or SaveOffline instead
    function self.Functions.Save()
        if self.Offline then
            SaveOffline(self.PlayerData)
        else
            Save(self.PlayerData.source)
        end
    end

    ---@deprecated call exports.qbx_core:Logout(source)
    function self.Functions.Logout()
        assert(not self.Offline, 'unsupported for offline players')
        Logout(self.PlayerData.source)
    end

    if not self.Offline then
        QBX.Players[self.PlayerData.source] = self
        local ped = GetPlayerPed(self.PlayerData.source)
        lib.callback.await('qbx_core:client:setHealth', self.PlayerData.source, self.PlayerData.metadata.health)
        SetPedArmour(ped, self.PlayerData.metadata.armor)
        -- At this point we are safe to emit new instance to third party resource for load handling
        GlobalState.PlayerCount += 1
        UpdatePlayerData(self.PlayerData.source)
        Player(self.PlayerData.source).state:set('loadInventory', true, true)
        TriggerEvent('QBCore:Server:PlayerLoaded', self)
    end

    return self
end

exports('CreatePlayer', CreatePlayer)

---Save player info to database (make sure citizenid is the primary key in your database)
---@param source Source
function Save(source)
    local ped = GetPlayerPed(source)
    local playerData = QBX.Players[source].PlayerData
    local playerState = Player(source)?.state
    local pcoords = playerData.position
    if not playerState.inApartment and not playerState.inProperty then
        local coords = GetEntityCoords(ped)
        pcoords = vec4(coords.x, coords.y, coords.z, GetEntityHeading(ped))
    end
    if not playerData then
        lib.print.error('QBX.PLAYER.SAVE - PLAYERDATA IS EMPTY!')
        return
    end

    playerData.metadata.health = GetEntityHealth(ped)
    playerData.metadata.armor = GetPedArmour(ped)

    if playerState.isLoggedIn then
        playerData.metadata.hunger = playerState.hunger or 0
        playerData.metadata.thirst = playerState.thirst or 0
        playerData.metadata.stress = playerState.stress or 0
    end

    CreateThread(function()
        storage.upsertPlayerEntity({
            playerEntity = playerData,
            position = pcoords,
        })
    end)
    assert(GetResourceState('qb-inventory') ~= 'started', 'qb-inventory is not compatible with qbx_core. use ox_inventory instead')
    lib.print.verbose(('%s PLAYER SAVED!'):format(playerData.name))
end

exports('Save', Save)

---@param playerData PlayerEntity
function SaveOffline(playerData)
    if not playerData then
        lib.print.error('SaveOffline - PLAYERDATA IS EMPTY!')
        return
    end

    CreateThread(function()
        storage.upsertPlayerEntity({
            playerEntity = playerData,
            position = playerData.position.xyz
        })
    end)
    assert(GetResourceState('qb-inventory') ~= 'started', 'qb-inventory is not compatible with qbx_core. use ox_inventory instead')
    lib.print.verbose(('%s OFFLINE PLAYER SAVED!'):format(playerData.name))
end

exports('SaveOffline', SaveOffline)

---@param identifier Source | string
---@param key string
---@param value any
function SetPlayerData(identifier, key, value)
    if type(key) ~= 'string' then return end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return end

    player.PlayerData[key] = value

    UpdatePlayerData(identifier)
end

---@param identifier Source | string
function UpdatePlayerData(identifier)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player or player.Offline then return end

    TriggerEvent('QBCore:Player:SetPlayerData', player.PlayerData)
    TriggerClientEvent('QBCore:Player:SetPlayerData', player.PlayerData.source, player.PlayerData)
end

---@param identifier Source | string
---@param metadata string
---@param value any
function SetMetadata(identifier, metadata, value)
    if type(metadata) ~= 'string' then return end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return end

    local oldValue = player.PlayerData.metadata[metadata]

    player.PlayerData.metadata[metadata] = value

    UpdatePlayerData(identifier)

    if not player.Offline then
        local playerState = Player(player.PlayerData.source).state

        TriggerClientEvent('qbx_core:client:onSetMetaData', player.PlayerData.source, metadata, oldValue, value)
        TriggerEvent('qbx_core:server:onSetMetaData', metadata,  oldValue, value, player.PlayerData.source)

        if (metadata == 'hunger' or metadata == 'thirst' or metadata == 'stress') then
            value = lib.math.clamp(value, 0, 100)

            if playerState[metadata] ~= value then
                playerState:set(metadata, value, true)
            end
        end

        if (metadata == 'dead' or metadata == 'inlaststand') then
            playerState:set('canUseWeapons', not value, true)
        end
    end

    if metadata == 'inlaststand' or metadata == 'isdead' then
        if player.Offline then
            SaveOffline(player.PlayerData)
        else
            Save(player.PlayerData.source)
        end
    end
end

exports('SetMetadata', SetMetadata)

---@param identifier Source | string
---@param metadata string
---@return any
function GetMetadata(identifier, metadata)
    if type(metadata) ~= 'string' then return end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return end

    return player.PlayerData.metadata[metadata]
end

exports('GetMetadata', GetMetadata)

---@param identifier Source | string
---@param charInfo string
---@param value any
function SetCharInfo(identifier, charInfo, value)
    if type(charInfo) ~= 'string' then return end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return end

    --local oldCharInfo = player.PlayerData.charinfo[charInfo]

    player.PlayerData.charinfo[charInfo] = value

    UpdatePlayerData(identifier)
end

exports('SetCharInfo', SetCharInfo)

---@param source Source
---@param playerMoney table
---@param moneyType MoneyType
---@param amount number
---@param actionType 'add' | 'remove' | 'set'
---@param direction boolean
---@param reason? string
local function emitMoneyEvents(source, playerMoney, moneyType, amount, actionType, direction, reason)
    TriggerClientEvent('hud:client:OnMoneyChange', source, moneyType, amount, direction)
    TriggerClientEvent('QBCore:Client:OnMoneyChange', source, moneyType, amount, actionType, reason)
    TriggerEvent('QBCore:Server:OnMoneyChange', source, moneyType, amount, actionType, reason)

    if moneyType == 'bank' and actionType == 'remove' then
        TriggerClientEvent('qb-phone:client:RemoveBankMoney', source, amount)
    end

    local oxMoneyType = moneyType == 'cash' and 'money' or moneyType

    if accountsAsItems[oxMoneyType] then
        exports.ox_inventory:SetItem(source, oxMoneyType, playerMoney[moneyType])
    end
end

---@param identifier Source | string
---@param moneyType MoneyType
---@param amount number
---@param reason? string
---@return boolean success if money was added
function AddMoney(identifier, moneyType, amount, reason)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    reason = reason or 'unknown'
    amount = qbx.math.round(tonumber(amount) --[[@as number]])

    if amount < 0 or not player.PlayerData.money[moneyType] then return false end

    player.PlayerData.money[moneyType] += amount

    if not player.Offline then
        UpdatePlayerData(identifier)

        emitMoneyEvents(player.PlayerData.source, player.PlayerData.money, moneyType, amount, 'add', false, reason)
    end

    return true
end

exports('AddMoney', AddMoney)

---@param identifier Source | string
---@param moneyType MoneyType
---@param amount number
---@param reason? string
---@return boolean success if money was removed
function RemoveMoney(identifier, moneyType, amount, reason)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    reason = reason or 'unknown'
    amount = qbx.math.round(tonumber(amount) --[[@as number]])

    if amount < 0 or not player.PlayerData.money[moneyType] then return false end

    for _, mType in pairs(config.money.dontAllowMinus) do
        if mType == moneyType then
            if (player.PlayerData.money[moneyType] - amount) < 0 then
                return false
            end
        end
    end

    player.PlayerData.money[moneyType] -= amount

    if not player.Offline then
        UpdatePlayerData(identifier)
        emitMoneyEvents(player.PlayerData.source, player.PlayerData.money, moneyType, amount, 'remove', false, reason)
    end

    return true
end

exports('RemoveMoney', RemoveMoney)

---@param identifier Source | string
---@param moneyType MoneyType
---@param amount number
---@param reason? string
---@return boolean success if money was set
function SetMoney(identifier, moneyType, amount, reason)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    reason = reason or 'unknown'
    amount = qbx.math.round(tonumber(amount) --[[@as number]])

    if amount < 0 or not player.PlayerData.money[moneyType] then return false end

    player.PlayerData.money[moneyType] = amount

    if not player.Offline then
        UpdatePlayerData(identifier)
    end

    return true
end

exports('SetMoney', SetMoney)

---@param identifier Source | string
---@param moneyType MoneyType
---@return boolean | number amount or false if moneytype does not exist
function GetMoney(identifier, moneyType)
    if not moneyType then return false end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    return player.PlayerData.money[moneyType]
end

exports('GetMoney', GetMoney)

---@param source Source
---@param citizenid string
function DeleteCharacter(source, citizenid)
    local license, license2 = GetPlayerIdentifierByType(source --[[@as string]], 'license'), GetPlayerIdentifierByType(source --[[@as string]], 'license2')
    local result = storage.fetchPlayerEntity(citizenid).license
    if license == result or license2 == result then
        CreateThread(function()
            local success = storage.deletePlayer(citizenid)
            if success then
                logger.log({
                    source = citizenid,
                    event = 'Character Deleted',
                    message = ('**%s** deleted **%s**...'):format(GetPlayerName(source), citizenid, source),
                    metadata = {
                        citizenid = citizenid
                    }
                })
            end
        end)
    else
        DropPlayer(tostring(source), locale('info.exploit_dropped'))
        logger.log({
            source = citizenid,
            event = 'Anti-Cheat',
            message = ('%s has been dropped for character deleting exploit'):format(GetPlayerName(source)),
            metadata = {
                citizenid = citizenid,
                license = license or license2
            }
        })
    end
end

---@param citizenid string
function ForceDeleteCharacter(citizenid)
    local result = storage.fetchPlayerEntity(citizenid).license
    if result then
        local player = GetPlayerByCitizenId(citizenid)
        if player then
            DropPlayer(player.PlayerData.source --[[@as string]], 'An admin deleted the character which you are currently using')
        end

        CreateThread(function()
            local success = storage.deletePlayer(citizenid)
            if success then
                logger.log({
                    source = citizenid,
                    event = 'Character Force Deleted',
                    message = ('Character **%s** got deleted'):format(citizenid),
                    metadata = {
                        citizenid = citizenid,
                        license = result
                    }
                })
            end
        end)
    end
end

exports('DeleteCharacter', ForceDeleteCharacter)

---Generate unique values for player identifiers
---@param type UniqueIdType The type of unique value to generate
---@return string | number UniqueVal unique value generated
function GenerateUniqueIdentifier(type)
    local isUnique, uniqueId
    local table = config.player.identifierTypes[type]
    repeat
        uniqueId = table.valueFunction()
        isUnique = storage.fetchIsUnique(type, uniqueId)
    until isUnique
    return uniqueId
end

exports('GenerateUniqueIdentifier', GenerateUniqueIdentifier)
