local FIGHT_REFRESH_INTERVAL = 1
local FIGHT_SERVER_ENTITY = "server"

local FIGHT_MANAGE_MESSAGE = {
    GET = "irden:fight:manage:get",
    NEXT_TURN = "irden:fight:manage:turn:next",
    SET_INITIATIVE = "irden:fight:manage:initiative:set",
    KICK_PLAYER = "irden:fight:manage:player:kick",
    FINISH = "irden:fight:manage:finish"
}

local FIGHTERS_LIST = "lytFightManager.lytCurrentFight.saFighters.listFighters"
local CURRENT_FIGHT_LAYOUT = "lytFightManager.lytCurrentFight"
local CHANGE_INIT_LAYOUT = CURRENT_FIGHT_LAYOUT .. ".lytChangeInit"

local ENTITY_FONT_COLOR = {
    PLAYER = "white",
    MONSTER = "red",
    SPECTATOR = "cyan"
}


---@param messageName string
---@param arguments table|nil
---@param onSuccess function|nil
---@param onError function|nil
local function sendFightManageMessage(messageName, arguments, onSuccess, onError)
    promises:add(
            world.sendEntityMessage(
                    FIGHT_SERVER_ENTITY,
                    messageName,
                    table.unpack(arguments or {})
            ),
            onSuccess or function() end,
            onError or function(error)
                irdenUtils.alert("^red;Ошибка управления боем: " .. tostring(error or "неизвестная ошибка"))
            end
    )
end

local function clearManagingFight()
    self.currentManagingFight = nil
    self.managingFightName = nil

    widget.setVisible(CURRENT_FIGHT_LAYOUT, false)
    widget.setVisible(CHANGE_INIT_LAYOUT, false)
    widget.clearListItems(FIGHTERS_LIST)
end

local function registerFightManagerCallbacks()
    if self.fightManagerCallbacksRegistered then
        return
    end

    widget.registerMemberCallback(FIGHTERS_LIST, "kickFromFight", kickFromFight)
    widget.registerMemberCallback(FIGHTERS_LIST, "prepareChangeInitiative", prepareChangeInitiative)
    self.fightManagerCallbacksRegistered = true
end

---@param currentFight FightData
---@return string
function getNameOfCurrentPlayer(currentFight)
    if not currentFight or not currentFight.playersInFight then
        return "Неизвестно"
    end

    local currentPlayer = currentFight.playersInFight[currentFight.currentPlayerUuidTurn]
    return currentPlayer and currentPlayer.name or "Неизвестно"
end

---@param playerData PlayerInFight
---@return string
local function getFighterFontColor(playerData)
    if playerData.uuid == player.uniqueId() then
        return "yellow"
    end

    return ENTITY_FONT_COLOR[playerData.entityType] or "white"
end

---@param playerData PlayerInFight
---@param tooltip string
---@return table
local function createFighterWidgetData(playerData, tooltip)
    return {
        name = playerData.name,
        uuid = playerData.uuid,
        entityType = playerData.entityType,
        initiative = playerData.initiative,
        defaultTooltip = tooltip
    }
end

---@param currentFight FightData
function drawFight(currentFight)
    widget.clearListItems(FIGHTERS_LIST)

    if not currentFight then
        return
    end

    widget.setText(
            CURRENT_FIGHT_LAYOUT .. ".lblCurrentPlayer",
            ("Ходит: %s"):format(getNameOfCurrentPlayer(currentFight))
    )
    widget.setText(
            CURRENT_FIGHT_LAYOUT .. ".lblCurrentRound",
            ("Раунд: %s"):format(currentFight.turn or "Неизвестно")
    )

    for _, uuid in ipairs(currentFight.queue or {}) do
        local fighter = currentFight.playersInFight and currentFight.playersInFight[uuid]

        -- На случай, если сервер прислал UUID в queue, но ещё не положил данные бойца.
        if fighter then
            local listItem = widget.addListItem(FIGHTERS_LIST)
            local itemPath = FIGHTERS_LIST .. "." .. listItem
            local isCurrentTurn = uuid == currentFight.currentPlayerUuidTurn

            widget.setText(
                    itemPath .. ".lblName",
                    (isCurrentTurn and "-> " or "") .. fighter.name
            )
            widget.setFontColor(itemPath .. ".lblName", getFighterFontColor(fighter))
            widget.setText(itemPath .. ".lblInitiative", tostring(fighter.initiative))
            widget.setData(itemPath, fighter)

            widget.setData(
                    itemPath .. ".btnKick",
                    createFighterWidgetData(fighter, "Кикнуть из боя")
            )
            widget.setData(
                    itemPath .. ".btnKChangeInit",
                    createFighterWidgetData(fighter, "Изменить инициативу")
            )
        end
    end
end

---@param fightName string
local function scheduleFightRefresh(fightName)
    timers:add(FIGHT_REFRESH_INTERVAL, function()
        if self.managingFightName == fightName then
            requestFightSnapshot(fightName, false)
        end
    end)
end

---@param fightName string
---@param initialRequest boolean
function requestFightSnapshot(fightName, initialRequest)
    sendFightManageMessage(
            FIGHT_MANAGE_MESSAGE.GET,
            { fightName },
            function(currentFight)
                -- Ответ от предыдущего выбранного боя больше не актуален.
                if self.managingFightName ~= fightName then
                    return
                end

                if not currentFight then
                    irdenUtils.alert(initialRequest and "^red;Такой бой не найден" or "^red;Бой больше не существует")
                    clearManagingFight()
                    return
                end

                local previousFight = self.currentManagingFight
                local snapshotChanged = not previousFight
                        or not currentFight.snapshotVersion
                        or previousFight.snapshotVersion ~= currentFight.snapshotVersion

                self.currentManagingFight = currentFight
                widget.setVisible(CURRENT_FIGHT_LAYOUT, true)

                if snapshotChanged then
                    drawFight(currentFight)
                end

                scheduleFightRefresh(fightName)
            end,
            function(error)
                if self.managingFightName ~= fightName then
                    return
                end

                irdenUtils.alert(
                        (initialRequest and "^red;Не удалось найти бой: " or "^red;Не удалось обновить бой: ")
                                .. tostring(error or "неизвестная ошибка")
                )
                clearManagingFight()
            end
    )
end

function findFightToManage(_)
    local fightName = widget.getText("lytFightManager.tbxFightname")

    if not fightName or fightName == "" then
        irdenUtils.alert("^red;Введите название боя")
        clearManagingFight()
        return
    end

    registerFightManagerCallbacks()

    self.currentManagingFight = nil
    self.managingFightName = fightName
    widget.setVisible(CURRENT_FIGHT_LAYOUT, false)
    widget.clearListItems(FIGHTERS_LIST)

    requestFightSnapshot(fightName, true)
end

function forceNextTurn()
    local currentFight = self.currentManagingFight
    if not currentFight then
        return
    end

    promises:add(
            player.confirm({
                title = currentFight.fightName,
                sourceEntityId = player.id(),
                okCaption = "Да",
                cancelCaption = "Нет",
                paneLayout = self.confirmationLayout,
                message = "Скипнуть ход " .. getNameOfCurrentPlayer(currentFight) .. "?"
            }),
            function(result)
                if result then
                    sendFightManageMessage(
                            FIGHT_MANAGE_MESSAGE.NEXT_TURN,
                            { currentFight.fightName }
                    )
                end
            end
    )
end

---@param _ string
---@param data PlayerInFight
function prepareChangeInitiative(_, data)
    if not data then
        return
    end

    widget.setText(CHANGE_INIT_LAYOUT .. ".lblName", "Инициатива " .. data.name .. ":")
    widget.setText(CHANGE_INIT_LAYOUT .. ".tbxInit", tostring(data.initiative))
    widget.setData(CHANGE_INIT_LAYOUT, data.uuid)
    widget.setData(CHANGE_INIT_LAYOUT .. ".btnAccept", data)
    widget.setVisible(CHANGE_INIT_LAYOUT, true)
    widget.focus(CHANGE_INIT_LAYOUT .. ".tbxInit")
end

---@param _ string
---@param data PlayerInFight
function changeInitiative(_, data)
    local currentFight = self.currentManagingFight
    local newInitiative = tonumber(widget.getText(CHANGE_INIT_LAYOUT .. ".tbxInit"))

    if not currentFight or not data or not newInitiative then
        irdenUtils.alert("^red;Введите корректную инициативу")
        return
    end

    promises:add(
            player.confirm({
                title = currentFight.fightName,
                sourceEntityId = player.id(),
                okCaption = "Да",
                cancelCaption = "Нет",
                paneLayout = self.confirmationLayout,
                message = "Поставить " .. data.name .. " на " .. newInitiative .. "?"
            }),
            function(result)
                if result then
                    sendFightManageMessage(
                            FIGHT_MANAGE_MESSAGE.SET_INITIATIVE,
                            { currentFight.fightName, data.uuid, newInitiative }
                    )
                    widget.setVisible(CHANGE_INIT_LAYOUT, false)
                end
            end
    )
end

---@param _ string
---@param data PlayerInFight
function kickFromFight(_, data)
    local currentFight = self.currentManagingFight
    if not currentFight or not data then
        return
    end

    promises:add(
            player.confirm({
                title = currentFight.fightName,
                sourceEntityId = player.id(),
                okCaption = "Да",
                cancelCaption = "Нет",
                paneLayout = self.confirmationLayout,
                message = "Кикнуть " .. data.name .. " из боя?"
            }),
            function(result)
                if result then
                    sendFightManageMessage(
                            FIGHT_MANAGE_MESSAGE.KICK_PLAYER,
                            { currentFight.fightName, data.uuid }
                    )
                end
            end
    )
end

function finishFight()
    local currentFight = self.currentManagingFight
    if not currentFight then
        return
    end

    promises:add(
            player.confirm({
                title = currentFight.fightName,
                sourceEntityId = player.id(),
                okCaption = "Да",
                cancelCaption = "Нет",
                paneLayout = self.confirmationLayout,
                message = "Завершить бой " .. currentFight.fightName .. "?"
            }),
            function(result)
                if result then
                    sendFightManageMessage(
                            FIGHT_MANAGE_MESSAGE.FINISH,
                            { currentFight.fightName },
                            function()
                                clearManagingFight()
                                widget.setText("lytFightManager.tbxFightname", "")
                            end
                    )
                end
            end
    )
end
