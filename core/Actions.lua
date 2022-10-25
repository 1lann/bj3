local Cards = require("modules.cards")
local Wallet = require("modules.wallet")

local Actions = {}

---Is Blackjack or a Bust
function Actions.isSpecial(player, hand)
    local total = Cards.getHandValue(hand, true, false)
    return (#hand == 2 and total == 21) or total > 21
end

function Actions.canHit(player, hand)
    local optimalHand = Cards.getHandValue(hand, true, false)
    return optimalHand < 21
    and not hand.didDoubleDown
    and not hand.didStand
    -- return not hand.didDoubleDown
end

function Actions.canDealerHit(dealer, hand)
    local optimalHand = Cards.getHandValue(hand, true, false)
    return optimalHand < 17
end

-- function Actions.canStand

---@param player Player
---@param hand PlayerHand
function Actions.canDoubleDown(player, hand)
    local wallet = Wallet.getWallet(player.entity.id)
    return #hand == 2
    and wallet.balance >= hand.bet
    -- and not hand.didDoubleDown
end

---@param player Player
---@param hand PlayerHand
function Actions.canSplit(player, hand)
    local wallet = Wallet.getWallet(player.entity.id)
    return #player.hands == 1 and #hand == 2
    and wallet.balance >= hand.bet
    and Cards.baseValue[hand[1].rank] == Cards.baseValue[hand[2].rank]
    -- and not hand.didDoubleDown
end

---@param player Player
---@param hand PlayerHand
---@param dealer Dealer
---@return number payout, string? message
function Actions.payout(player, hand, dealer)
    local dealerTotal = Cards.getHandValue(dealer.hand, true, false)
    local playerTotal = Cards.getHandValue(hand, true, false)

    if (playerTotal == 21 and #hand == 2) and not (dealerTotal == 21 and #dealer.hand == 2) then
        return hand.bet * 2.5
    elseif playerTotal > 21 then
        return 0, "Bust"
    elseif (dealerTotal == 21 and #dealer.hand == 2) and not (playerTotal == 21 and #hand == 2) then
        return 0, "Dealer Blackjack"
    elseif dealerTotal > 21 then
        return hand.bet * 2, "House Bust!"
    elseif playerTotal == dealerTotal then
        return hand.bet, "Push"
    elseif playerTotal > dealerTotal then
        return hand.bet * 2, "You Win!"
    else
        return 0, "You Lose"
    end
end

return Actions
