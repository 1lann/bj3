local _ = require("util.score")

local Solyd = require("modules.solyd")
local Cards = require("modules.cards")
local Display = require("modules.display")

local Canvas = require("modules.canvas")
local PixelCanvas = Canvas.PixelCanvas

local hooks = require("modules.hooks")
local useAnimation, useBoundingBox = hooks.useAnimation, hooks.useBoundingBox

local Sprite = require("components.Sprite")
local BigText = require("components.BigText")
local ChipStack = require("components.ChipStack")
local Button = require("components.Button")
local HandModule = require("components.Hand")
local Hand, getDeckDims = HandModule.Hand, HandModule.getDeckDims

local loadRIF = require("modules.rif")
local playerSlotEmpty = loadRIF("res/cum.rif")

---@param props { x: integer, width: integer, height: integer, onStand: fun() }
return Solyd.wrapComponent("PlayerSlot", function(props)
    -- local filledCanvas = useCanvas()
    -- local canvas = useCanvas()
    local gameState = Solyd.useContext("gameState") ---@type GameState
    local playerId, setPlayerId = Solyd.useState--[[@as UseState<integer?>]](nil)
    local player = gameState.players[playerId]

    -- local isFilled, setFilled = Solyd.useState(false)
    local isFilled = player ~= nil

    -- local cards, setCards = Solyd.useState({})
    local cards = player and player.hand or {}

    local pendingBet, setPendingBet = Solyd.useState(0)

    local afCards, setAfCards = Solyd.useState({})

    local softValue = Cards.getHandValue(afCards, false, true)
    local hardValue = Cards.getHandValue(afCards, false, false)

    local didBust = softValue > 21
    local clearColor = didBust and colors.red or colors.lime

    local emptySprite = Solyd.useMemo(function()
        local canv = PixelCanvas(props.width, props.height)
        
        canv:drawCanvas(
            playerSlotEmpty,
            (props.width - playerSlotEmpty.width)/2,
            (props.height - playerSlotEmpty.height)/2
        )

        return canv
    end, { props.width, props.height })

    local hitSprite = Solyd.useMemo(function()
        local canv = PixelCanvas(props.width, props.height)
        
        canv:drawRect(clearColor, 1, 1, props.width, props.height) --drawCanvas(playerSlotEmpty, (props.width - playerSlotEmpty.width)/2, 25)

        return canv
    end, { clearColor, props.width, props.height })

    local x, y = props.x, Display.ccCanvas.pixelCanvas.height-props.height-2

    local t = useAnimation(#cards ~= #afCards)
    local finished = false
    if t and t > 1 then
        afCards = setAfCards(cards)
        t = nil
        finished = true
    end
    -- local h = 
    -- if isFilled then
    --     h = nil
    -- end

    -- ease t
    -- t = t and math.sqrt(t)
    -- t = t and -1 * t*(t-2); -- quad
    t = t and t - 1
	t = t and t*t*t + 1;

    local dealerContext = Solyd.useContext("dealerContext")
    local stood, setStood = Solyd.useState(false)

    -- I have a fucking clue to whats happening here
    local dmx = ((getDeckDims(#cards) - getDeckDims(#afCards))/2)*(#afCards > 0 and 1 or 0)
    local amx = -math.min(dmx, (t or 0)*2*dmx)

    if isFilled then
        local canAct = not didBust and not dealerContext.revealed and not stood
        
        local valueText
        if softValue > 0 then
            if softValue == hardValue then
                valueText = tostring(softValue)
            else
                valueText = tostring(softValue) .. "/" .. tostring(hardValue)
            end
        end

        if not player.bet then
            -- local num1Chips   = math.floor(pendingBet/1)
            -- local num5Chips   = math.floor((pendingBet - num1Chips)/5)
            -- local num10Chips  = math.floor((pendingBet - num1Chips - num5Chips*5)/10)
            -- local num25Chips  = math.floor((pendingBet - num1Chips - num5Chips*5 - num10Chips*10)/25)
            -- local num100Chips = math.floor((pendingBet - num1Chips - num5Chips*5 - num10Chips*10 - num25Chips*25)/100)

            local num100Chips = math.floor(pendingBet/100)
            local num25Chips  = math.floor((pendingBet - num100Chips*100)/25)
            local num10Chips  = math.floor((pendingBet - num100Chips*100 - num25Chips*25)/10)
            local num5Chips   = math.floor((pendingBet - num100Chips*100 - num25Chips*25 - num10Chips*10)/5)
            local num1Chips   = math.floor((pendingBet - num100Chips*100 - num25Chips*25 - num10Chips*10 - num5Chips*5)/1)

            return {
                Sprite { sprite = hitSprite, x = x, y = y },

                BigText { 
                    text = "\164" .. tostring(pendingBet),
                    x = props.x + 2,
                    y = y + 2,
                    width = props.width - 4,
                    color = colors.white
                },

                Button {
                    x = x+2,
                    y = y+props.height-14,
                    width = props.width-4,
                    text = "Bet",
                    bg = canAct and colors.orange,
                    color = colors.white,
                    onClick = function()
                        player.bet = 1 -- TODO
                    end,
                },

                ChipStack {
                    x = props.x + 8 + 10*0,
                    y = y + props.height - 30,
                    clear = colors.lime,
                    chipCount = 1,
                    chipValue = 1,
                    onClick = function()
                        setPendingBet(pendingBet + 1)
                    end,
                },
        
                ChipStack {
                    x = props.x + 8 + 10*2,
                    y = y + props.height - 30,
                    clear = colors.lime,
                    chipCount = 1,
                    chipValue = 5,
                    onClick = function()
                        setPendingBet(pendingBet + 5)
                    end,
                },
        
                ChipStack {
                    x = props.x + 8 + 10*4,
                    y = y + props.height - 30,
                    clear = colors.lime,
                    chipCount = 1,
                    chipValue = 10,
                    onClick = function()
                        setPendingBet(pendingBet + 10)
                    end,
                },
        
                ChipStack {
                    x = props.x + 8 + 10*6,
                    y = y + props.height - 30,
                    clear = colors.lime,
                    chipCount = 1,
                    chipValue = 25,
                    onClick = function()
                        setPendingBet(pendingBet + 25)
                    end,
                },
        
                ChipStack {
                    x = props.x + 8 + 10*8,
                    y = y + props.height - 30,
                    clear = colors.lime,
                    chipCount = 1,
                    chipValue = 100,
                    onClick = function()
                        setPendingBet(pendingBet + 100)
                    end,
                },

                -- Actual bet

                ChipStack {
                    x = props.x + 8 + 10*0,
                    y = y + props.height - 50,
                    clear = colors.lime,
                    chipCount = num1Chips,
                    chipValue = 1,
                    onClick = function()
                        setPendingBet(pendingBet - 1)
                    end,
                },
        
                ChipStack {
                    x = props.x + 8 + 10*2,
                    y = y + props.height - 50,
                    clear = colors.lime,
                    chipCount = num5Chips,
                    chipValue = 5,
                    onClick = function()
                        setPendingBet(pendingBet - 5)
                    end,
                },
        
                ChipStack {
                    x = props.x + 8 + 10*4,
                    y = y + props.height - 50,
                    clear = colors.lime,
                    chipCount = num10Chips,
                    chipValue = 10,
                    onClick = function()
                        setPendingBet(pendingBet - 10)
                    end,
                },
        
                ChipStack {
                    x = props.x + 8 + 10*6,
                    y = y + props.height - 50,
                    clear = colors.lime,
                    chipCount = num25Chips,
                    chipValue = 25,
                    onClick = function()
                        setPendingBet(pendingBet - 25)
                    end,
                },
        
                ChipStack {
                    x = props.x + 8 + 10*8,
                    y = y + props.height - 50,
                    clear = colors.lime,
                    chipCount = num100Chips,
                    chipValue = 100,
                    onClick = function()
                        setPendingBet(pendingBet - 100)
                    end,
                }
            }
        end

        return {
            -- Canvas {
            --     key = "filled",
            --     children = {
                Sprite { sprite = hitSprite, x = x, y = y },
                Hand { x=x+(props.width - getDeckDims(#afCards))/2+amx -- x+1
                , y=y+26, cards = afCards, clear = clearColor },
                Hand { x=x+(props.width + getDeckDims(#afCards) - getDeckDims(#cards - #afCards) - dmx)/2 - (#afCards > 0 and 2 or 0)       --x+(props.width - getDeckDims(#cards))/2 -- x+1
                , y=y+26+math.max(0, props.height-props.height*(t or 1)), cards = _.intersectSeq(afCards, cards), clear = clearColor },
                Button {
                    x = x+2,
                    y = y+2,
                    width = props.width-4,
                    text = canAct and "Stand" or "",
                    bg = canAct and colors.red,
                    color = colors.white,
                    onClick = function()
                        setStood(true)
                        props.onStand()
                    end,
                },
                BigText {
                    x = x+2,
                    y = y+14,
                    width = props.width-4,
                    text = valueText or "",
                    color = colors.white,
                    bg = clearColor,
                }
            --     }
            -- }
            -- getHandValue(cards, true, true) > 21 and BigText { text = "UR A FUCKING IDIOT", x=x+10, y=y-10, color=colors.red },
        }, {
            -- canvas = canvas,
            aabb = useBoundingBox(x, y, emptySprite.width, emptySprite.height, function()
                if canAct and (not finished) then
                    -- setCards(_.append(cards, table.remove(dealerContext.deck, 1)))
                    -- TODO
                end
            end)
        }
    else
        return {
             
                -- key = "waiting",
                -- children = 
                Sprite { sprite = emptySprite, x = x, y = y }
            
        }, {
            -- canvas = canvas,
            aabb = useBoundingBox(x, y, emptySprite.width, emptySprite.height, function()
                table.insert(gameState.players, { hand = {} })
                setPlayerId(#gameState.players)
                -- setFilled(true)
                -- setCards({ table.remove(dealerContext.deck, 1), table.remove(dealerContext.deck, 1) })
            end)
        }
    end
end)
