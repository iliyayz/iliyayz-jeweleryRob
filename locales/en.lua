local Translations = {
    notify = {
        not_enough_cops = "Not enough police on duty.",
        cooldown = "The store has just been hit. Come back later.",
        no_item = "You need a %{item} to start the robbery.",
        consume = "You used your %{item}.",
        got = "You received %{count}x %{item}.",
        empty = "This case is empty right now.",
        unknown = "Action failed.",
        minigame_success = "Security bypassed!",
        minigame_fail = "You failed to bypass security.",
        case_smashed_left = "Case #%{id} smashed. %{left} left to finish the job.",
        case_smashed_last = "Case #%{id} smashed. That was the last one!",
        robbery_done_player = "All glass cases are smashed. Robbery is complete!",
        payout_received = "Payout received: %{loot}",
        need_bat = "You must be holding a bat to smash the glass."
    },
    progress = {
        smash = "Smashing the display..."
    }
}
Lang = Lang or Locale:new({ phrases = Translations, warnOnMissing = true })
return Translations
