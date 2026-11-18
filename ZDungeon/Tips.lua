-- ZDungeon deep dives: what each dungeon is like, what to look out for, and
-- what to do as tank, healer and damage dealer.
--
-- Written for ZDungeon. The mechanics were checked against Method's and
-- Warcraft Tavern's WoW Forever dungeon guides (November 2026); the wording
-- and the role advice are ZDungeon's own. Forever changed several of the
-- old dungeons, so do not fill gaps here from Classic memory: check a
-- current guide.
local _, ns = ...

ns.tips = {}
ns.tipsChecked = "November 2026"

ns.tips.LORD = {
    about = "Open-air ruins above the Undercity with six bosses. Two of them are wave events you start yourself: click the chimney in the house south-west of Lordamere Overlook for Viktor the Vile, and the Market Square statue for The Abandoned.",
    watch = {
        "Kings Alley spiders come in groups with fast patrols. Pull back to where you came from, never forward.",
        "Ghoul packs stand close together, so two packs come easily. Kill the Ragged Ghoul first.",
        "Flesh Golems knock back and patrol the Overlook. Fight them where a knockback can't throw you into another pack.",
        "Take a Living Monstrosity on its own, and kill it quickly.",
        "The wave events leave almost no time to drink. Start them at full mana.",
    },
    tank = {
        "The Baron's Knockout takes close to half your health and then stuns you. Be near full before it lands and keep a cooldown for it.",
        "Grab Viktor the moment he appears on wave six: he hits hard and goes for whoever has been doing the most.",
        "Clear Witherfang's patrol path first and pull him into the gap.",
        "Bjork wanders the middle. Make sure no ghouls are nearby before you start.",
    },
    heal = {
        "Keep the tank as close to full as you can on The Baron; the stun comes right after the big hit.",
        "Pace your mana through Viktor's five waves and The Abandoned's three. Drink whenever a wave dies early.",
        "Witherfang and Viktor put a leeching poison on the tank. Cure it if you can.",
    },
    dps = {
        "Witherfang: boss first, then his two adds.",
        "The Abandoned: stun him as Life Drain starts. Melee get Chilled for hitting him.",
        "Rath'mael: step out of Flamestrike. A stun stops the cast.",
        "Bjork's Anti-Magic Shield lasts about three seconds. Casters, hold your big spell.",
    },
    bosses = {
        {"Witherfang", "Patrols Kings Alley with two adds. Leech Poison on the tank."},
        {"The Baron", "Hard swings; Knockout halves the tank's health, then stuns. Can be stunned."},
        {"Viktor the Vile", "Optional. Five waves, then Viktor. Leech Poison."},
        {"The Abandoned", "Three waves, then the boss. Frost Nova and Life Drain on the tank."},
        {"Bjork", "Patrols the centre. Brief Anti-Magic Shield."},
        {"Rath'mael", "Last boss. Flamestrike: move out, or stun the cast."},
    },
}

ns.tips.WC = {
    about = "A winding cave with nine bosses and no fixed order. Killing the four Druid of the Fang leaders (Anacondra, Cobrahn, Pythas, Serpentis) unlocks the escort from the entrance that ends with Mutanus the Devourer; do the escort last, when the cave is already clear.",
    watch = {
        "Druid's Slumber puts a random player to sleep, the healer included. It is the first thing to interrupt.",
        "Druids of the Fang heal themselves and each other with Healing Touch. Interrupt it or the pull drags on.",
        "They turn into serpents near death and hit much harder. Finish them quickly.",
        "Deviate Dreadfangs fear. Fight them away from other packs.",
        "Poison and nature damage everywhere. Bring cures.",
        "Deviate Hides and Wailing Essence rarely finish in one pass. Kill everything rather than skipping packs if anyone has those quests.",
    },
    tank = {
        "Anacondra patrols near the start and has a thorns aura that hurts everyone hitting her in melee. Pull her alone.",
        "Kresh and Verdan the Everliving both hit very hard. Verdan also roots the whole group in place.",
        "Pythas uses Thunderclap, which slows your attacks. He has two adds: hold all three.",
        "On the Naralex escort, pick up both add waves before Mutanus arrives.",
    },
    heal = {
        "Verdan is non-stop tank healing. Start at full mana.",
        "If you are slept, the group has to notice. Say so before the pull so someone is watching for it.",
        "Mutanus stuns nearby players, fears, and sleeps or mind-controls one player. Keep heals over time rolling before each.",
        "Cure the Deviate Vipers' poison off the tank.",
    },
    dps = {
        "Interrupt order on every druid boss: Druid's Slumber first, Healing Touch second.",
        "Kill adds before the boss on Cobrahn, Pythas, Serpentis and the Deviate Faerie Dragon.",
        "Spread out for Skum's Chained Bolt.",
        "Kresh has high armour: casters do full damage, physical damage is reduced.",
        "Deviate Shamblers heal with Wild Regeneration. Interrupt it.",
    },
    bosses = {
        {"Lady Anacondra", "Patrols the start. Lightning Bolt, Healing Touch, Sleep, thorns aura."},
        {"Kresh", "Hard bite, high armour. Nothing else."},
        {"Lord Cobrahn", "Small pythons with him. Slumber, heals, serpent form near death."},
        {"Deviate Faerie Dragon", "Rare. Comes with Druids of the Fang: kill them first."},
        {"Lord Pythas", "Two adds, Thunderclap, Slumber, heals."},
        {"Skum", "Chained Bolt. Spread out."},
        {"Lord Serpentis", "Two druid adds. Slumber, heals, Lightning Bolt."},
        {"Verdan the Everliving", "Hits very hard. Grasping Vines roots and damages everyone."},
        {"Mutanus the Devourer", "After the escort and two waves. Stun, fear, sleep or mind control."},
    },
}

ns.tips.SFK = {
    about = "Arugal's keep in Silverpine. Forever's version is longer than the Classic one, with nine boss encounters and several new kinds of trash, so old habits will get you killed in the courtyard.",
    watch = {
        "Wailing Guardsmen silence everyone in melee range for five seconds, and do it again and again. Kill them first; casters and the healer stay out of reach.",
        "Shadowfang Moonwalkers go fully immune to magic for ten seconds. Casters wait it out.",
        "Fel Steeds stun everyone near them and raise physical damage taken.",
        "Haunted Servitors curse a player so ghosts keep spawning on them. Remove the curse.",
        "Lupine Horrors summon more wolves. Kill the Horror first and fast.",
        "Sons of Arugal leave a shadow damage effect that keeps ticking for minutes.",
    },
    tank = {
        "Baron Silverlaine's Veil of Shadow cuts healing on you by 75% for 15 seconds. Use a cooldown and don't have extra mobs on you.",
        "Odo's two bats cleave and disarm. Face them away from the group and expect to lose some threat while disarmed.",
        "Archmage Arugal's Void Bolt hits you very hard: step behind the room's corners to break line of sight on the cast.",
        "When Arugal takes control of a player, taunt whatever they are hitting.",
        "Wolf Master Nandos comes when his four wolves die, and he hits hard. Have the wolves under control first.",
    },
    heal = {
        "Top the tank off before Silverlaine's Veil lands; you are healing at a quarter strength for 15 seconds.",
        "Rethilgore's Soul Drain stuns its target and drains their health.",
        "Fenrus applies a poison that ticks hard. Cleanse it.",
        "Arugal: the tank spikes on every Void Bolt, and Thundershock hits the whole group.",
    },
    dps = {
        "Adds before boss on Rethilgore, Razorclaw, Odo (the bats) and Nandos (whatever he calls).",
        "Commander Springvale: kill his Wailing Guardsman first. He heals with Holy Light (interrupt it) and bubbles for ten seconds (stop and wait).",
        "Odo the Blindwatcher grows and hits harder the longer he lives. Burn him once the bats are dead.",
        "Arugal: crowd-control the player he takes over. He teleports around the room, so melee keep up.",
        "The Deathsworn Captain is a rare after Odo. Don't pull him together with trash.",
    },
    bosses = {
        {"Rethilgore", "Soul Drain stuns and drains. Adds first."},
        {"Razorclaw the Butcher", "Drains your resource. Adds first."},
        {"Baron Silverlaine", "Veil of Shadow: -75% healing on the tank for 15 seconds."},
        {"Commander Springvale", "Stun, Holy Light, ten-second Divine Shield. Two adds."},
        {"Odo the Blindwatcher", "Two disarming bats. Grows stronger over time."},
        {"Deathsworn Captain", "Rare. Cleave and Hamstring."},
        {"Fenrus the Devourer", "Hard hits and a poison."},
        {"Wolf Master Nandos", "Four wolves, then he calls worgs or Lupine Horrors."},
        {"Archmage Arugal", "Void Bolt, mind control, teleports, Thundershock."},
    },
}

ns.tips.BFD = {
    about = "A flooded temple on the Ashenvale coast with six bosses in a line. The last room has four braziers: each one you light releases a wave, and Aku'mai waits behind them.",
    watch = {
        "Twilight Shadowmages mind-control a player. Kill them first, and pull them round a corner so they come to you.",
        "Twilight Acolytes heal. Interrupt or stun the cast.",
        "Fallenroot Hellcallers burn mana. Interrupt or stun them too.",
        "Fallenroot Shadowstalkers are stealthed until they strike, and curse the tank.",
        "Snapclaws and Myrmidons disarm the tank. Sea Witches freeze the group in place with Frost Nova.",
        "Old Serra'kis is fought underwater. Watch your breath.",
    },
    tank = {
        "Lady Sarevess: face her away from the group for Forked Lightning. After her Frost Nova she runs off and shoots people until you reach her again.",
        "Twilight Lord Kelris casts Mind Blast at you the whole fight. Clear his room first.",
        "Aku'mai attacks 75% faster as the fight goes on. Save your cooldown for the second half.",
        "Light the braziers one at a time and collect each wave before the next. The top-right one releases ten small turtles.",
        "Ghamoo-ra tramples everyone standing near him.",
    },
    heal = {
        "Kelris puts random players to sleep, you included. Keep the tank high and heals over time running.",
        "Aku'mai's Poison Cloud ticks on everyone standing in it for 45 seconds. Call for people to move out.",
        "The heavy tank healing on Aku'mai comes late, during Frenzied Rage. Don't spend your mana on the braziers.",
    },
    dps = {
        "Ghamoo-ra has very high armour. Casters carry this fight; physical damage wants Sunder Armor or Faerie Fire up.",
        "Sarevess: her two naga first. Crowd-control one (Polymorph works) and kill the other.",
        "Gelihast: clear the murlocs around him in pulls of one or two before touching the boss. His only trick is a ten-second net.",
        "Kelris: use the wall by the door to break line of sight so his casters walk to you.",
        "Never light two braziers at once.",
    },
    bosses = {
        {"Ghamoo-ra", "High armour. Trample around him."},
        {"Lady Sarevess", "Two adds, Forked Lightning in front, Frost Nova, Slow."},
        {"Gelihast", "Clear the room first. Net."},
        {"Old Serra'kis", "Underwater, no abilities. The danger is drowning."},
        {"Twilight Lord Kelris", "Mind Blast on the tank, Sleep on random players."},
        {"Aku'mai", "Four braziers first. Poison Cloud, Frenzied Rage."},
    },
}

ns.tips.EXCAV = {
    about = "A new Forever dungeon above Whelgar's Excavation in the Wetlands. Four bosses in a line through four areas: the Lost Marsh (Saltspine), Stalker's Thicket (Shadetooth), the Lost Dig Site (Highland Horror, optional, to the north), and the Site of the Guardian (Relic Guardian).",
    watch = {
        "Raptors in the Thicket hide in the tall grass, some of them stealthed, and call for help. Their bleeds kill cloth wearers quickly.",
        "Shadetooth patrols the whole raptor path and fears the group into those hidden packs. Clear the grass before you fight him, or bring a Tremor Totem or Fear Ward.",
        "Three diseases to cure: Infected Wound (more damage taken), Muculent Rot (drains Stamina and Spirit), Highland Venom (slows and weakens).",
        "Dragonmaw Warders net a player for ten seconds and halve healing with Mortal Strike. Saboteurs throw bombs at the ground: move.",
        "Dragonmaw Thaumaturgists bring a fire elemental. Kill the elemental first.",
        "If anyone needs raptor pelts or other drops, clear the whole Thicket. Skipping packs is how you end up running it twice.",
    },
    tank = {
        "Saltspine's Dust Storm cuts your threat and makes melee miss. Build a lead before the group opens up, and pull him to a cleared dry patch, alone.",
        "Shadetooth puts Rend on you and attacks 30% faster below 20% health. Keep a cooldown for the end.",
        "Relic Guardian is level 31, so you will miss more and threat is shaky. Face him away from the group (Arcing Smash), taunt after Knockaway, and don't stand near the edge.",
        "You start the Relic Guardian yourself at the titan panel beside him. Nobody clicks it until everyone is ready.",
    },
    heal = {
        "Save mana for Shadetooth's last 20%.",
        "Relic Guardian is a long, steady drain with no adds: a mana check. Stay well away from War Stomp, which stuns and knocks back.",
        "Cure diseases as they appear; Infected Wound on the tank is the one that hurts most.",
        "On Saltspine several people take damage at once from Dust Storm. Ranged and healers stand outside it.",
    },
    dps = {
        "Young Riptooth packs of three: kill one at a time. Area damage here just spreads threat.",
        "Shadetooth: his two Thicket Hunters first, then the boss.",
        "Highland Horror: interrupt Wild Regeneration and keep him away from the slimes around him. He drops nothing but an Alliance quest item.",
        "Relic Guardian: ranged stay out of Thunderclap and War Stomp range and give the tank time. He can be slowed and stunned, so he can be kited if the tank drops.",
    },
    bosses = {
        {"Saltspine", "Giant crocolisk patrolling the lake edge. Dust Storm, Tendon Rip, Fatal Bite."},
        {"Shadetooth", "Raptor with two adds. Terrifying Roar (fear), Rend, enrage at 20%."},
        {"Highland Horror", "Optional. Entangling Roots, Wild Regeneration."},
        {"Relic Guardian", "Level 31. Thunderclap, Arcing Smash, Knockaway, War Stomp."},
    },
}

ns.tips.DALA = {
    about = "A new Forever dungeon in the Alterac Mountains, entered from the sewers on the city's north-west side. You need the Dalaran Sewers Key: Horde earn it through a chain that starts with Magus Wordeen Voidglare in Tarren Mill, Alliance from a quest at Southshore's town hall. Eight bosses, one of them secret.",
    watch = {
        "Mana Phantoms cast Mana Burn. Interrupt or stun every one, or bring plenty of water.",
        "Phantasms put up a Reflection Field that sends spells back at the caster. Stop casting while it is up.",
        "Kirin Tor Necromancers keep raising skeletons and speed them up with Unholy Frenzy. Kill the necromancer, not the skeletons.",
        "Fallen Mages cast Frostbolt from range. Pull them round a corner.",
        "Fragmented Sentries hit everyone in front of them. Saturated Remnants' arcane swings can't be blocked.",
        "Seeking Remnants see through stealth.",
    },
    tank = {
        "Atrexis the Grave Knight disarms you and hits very hard. He patrols with three necromancers: kill a couple of them before you take him.",
        "Unstable Sentinel: face him away from the group for Arcing Smash. This is the fight where you take the most damage.",
        "Arcane Anomaly mixes heavy physical hits with Arcane Bolts of about 500.",
        "Shade of the Archmage: move him off the spot when he casts Bounding Mana so the returning sphere misses everyone.",
        "Lyn the Ignored curses you so that dealing damage hurts you. Ask for a decurse.",
    },
    heal = {
        "Unstable Sentinel is the hard one for you: constant heavy tank damage.",
        "Mana Devourer's Debilitate hits everyone and takes 200 mana each time. The longer it lives, the less you have.",
        "Arcanic Enigma polymorphs random players (dispellable) and has an area silence. Stand at range.",
        "Fel Ancient roots players for ten seconds with damage ticking. Blessing of Freedom frees them.",
    },
    dps = {
        "Arcanic Enigma: its two Mana Phantoms must never finish Mana Burn. Then split damage between the Manalings and the boss.",
        "Unstable Sentinel: ranged move out of the Malfunction pulse (25 yards). A stun just before the cast prevents it.",
        "Fel Ancient: talk to Grindle Firespark to drop the barriers. Get out of the green pools straight away.",
        "Mana Devourer: clear the entire room first, then kill it as fast as you can.",
        "Shade of the Archmage: after the sphere returns he casts Arcane Explosion, so be more than 20 yards away. At zero mana he polymorphs everyone and drinks; the fight restarts after.",
        "Arcane Anomaly's Focal Blast is a three-second beam that sweeps round the room. Keep moving ahead of it.",
    },
    bosses = {
        {"Atrexis the Grave Knight", "Patrols with three necromancers. Disarm, Raise Dead, Unholy Frenzy."},
        {"Lyn the Ignored", "Secret; needs the Tome of Dalaran. Raise Dead, Shadow Bolt Volley, Curse of Thorns."},
        {"Arcane Anomaly", "Krasus Landing. Arcane Bolt, sweeping Focal Blast."},
        {"Arcanic Enigma", "Two Mana Phantoms, Manamorph, silence, Manalings."},
        {"Unstable Sentinel", "Arcing Smash in front, Malfunction pulse."},
        {"Fel Ancient", "Entangle, Fel Timbers pools. Barriers come down at Grindle Firespark."},
        {"Mana Devourer", "Drain Vitality on the tank, Debilitate on everyone."},
        {"Shade of the Archmage", "Arcane Bolt, Bounding Mana, Arcane Explosion, Mass Polymorph at zero mana."},
    },
}

ns.tips.GNOMER = {
    about = "The irradiated gnome city under Dun Morogh, six bosses. The main way in is left after the elevator, past the troggs. The back door needs the Workshop Key, which drops from Electrocutioner 6000.",
    watch = {
        "Mobile Alert Systems patrol and call for reinforcements. Kill them the moment you see one.",
        "Arcane Nullifier X-21 reflects magic back at the caster. Stop casting while Reflection Field is up.",
        "Dark Iron Agents hit very hard and drop land mines. Kill the mines or move away.",
        "Irradiated Horrors drain mana and health with Chain Burn. Focus them.",
        "Caverndeep Ambushers patrol and Backstab for a lot.",
        "There are ledges everywhere. A knockback near one means a long walk or a wipe.",
        "Bleeds and some other effects do nothing to mechanical mobs.",
    },
    tank = {
        "Grubbis comes with Chomper after you defend Emi Shortfuse through the trogg waves. Hold both; the group kills one at a time.",
        "Viscous Fallout's hits are nature damage that armour and block don't reduce. Keep Demoralizing Shout or Roar on it. It patrols the Hall of Gears.",
        "Electrocutioner 6000: face it away from the group for Megavolt.",
        "Crowd Pummeler 9-60: put your back to a wall in a hallway. Arcing Smash hits in front, Crowd Pummel knocks back.",
        "Mekgineer Thermaplugg's Knock Away drops threat on everyone near him. Taunt straight back.",
    },
    heal = {
        "Viscous Fallout is unmitigated damage on the tank from the first hit.",
        "Electrocutioner's Shock is instant heavy damage on the tank and Chain Bolt jumps to people standing close. Stay spread.",
        "Poisons and diseases all through the dungeon. Cure them.",
        "On Thermaplugg, whoever has threat after a Knock Away needs a heal right away.",
    },
    dps = {
        "Thermaplugg: one ranged player (a mage or hunter is ideal) kills the walking bombs and presses the pillar buttons to shut them off. Everyone watches threat after Knock Away.",
        "Crowd Pummeler: stand to his side, never in front, and never with a ledge behind you.",
        "Grubbis and Chomper: one target at a time. Don't cleave.",
        "Dark Iron Ambassador is a rare with a Fire Shield that burns melee attackers. Pull him with nothing else around.",
    },
    bosses = {
        {"Grubbis", "After the trogg waves, with Chomper. Heavy melee from both."},
        {"Viscous Fallout", "Patrols. Nature melee that ignores armour."},
        {"Electrocutioner 6000", "Chain Bolt, Megavolt in front, Shock. Drops the Workshop Key."},
        {"Crowd Pummeler 9-60", "Arcing Smash, Crowd Pummel knockback, Trample."},
        {"Dark Iron Ambassador", "Rare. Fireball, Burning Servant, Fire Shield."},
        {"Mekgineer Thermaplugg", "Walking bombs from the pillars, Knock Away."},
    },
}

ns.tips.RFK = {
    about = "The quilboar warren in the southern Barrens, eight bosses. Most of the danger is in the trash: stuns, silences and healers.",
    watch = {
        "Razorfen Groundshakers stun the whole group for two seconds and interrupt. Kill them first, always.",
        "Kraul Bats silence for ten seconds. Casters and the healer stay ten yards or more away.",
        "Razorfen Defenders silence nearby casters with Shield Bash.",
        "Razorfen Geomancers summon an Earth Rumbler. Kill or stun them before the summon.",
        "Death's Head Priests heal. Interrupt, and pull them round a corner because more packs are usually close.",
        "Razorfen Beastmasters poison a random player and bring a hyena.",
    },
    tank = {
        "Agathelos the Raging charges the first target he sees. Make sure that is you. He enrages near death.",
        "Aggem Thorncurse summons a Boar Spirit: taunt it as it appears.",
        "Earthcaller Halmgar summons an Earth Rumbler and drops an Earthbind Totem. Get threat on the Rumbler before ranged do, because you won't catch it while slowed.",
        "Overlord Ramtusk uses Thunderclap and has two Spearhides.",
        "Charlga Razorflank stands in her hut. Pull her, then break line of sight so she comes down to you.",
    },
    heal = {
        "Stay out of silence range of bats and of the Blind Hunter.",
        "Charlga's Chain Bolt hits its target and two more for heavy damage. People low on health should step away from the chain.",
        "Agathelos enrages near death: keep heals on the tank through the end.",
        "Cure the Beastmasters' poison.",
    },
    dps = {
        "Death Speaker Jargba mind-controls a random player. No area damage, and stun or interrupt the boss to stop his casts. Kill any Groundshaker near him first.",
        "Overlord Ramtusk: crowd-control his two Spearhides (Polymorph works) and kill the boss first. Without control, kill the adds one at a time.",
        "Roogug: his earth elemental first, then him.",
        "Charlga goes immune for two seconds with Purity and heals herself with Renew. Anyone who can heal a little should help here.",
        "Paladin tanks struggle to hold bats. Go easy on them.",
    },
    bosses = {
        {"Roogug", "Lightning Bolt and an Earth Rumbler."},
        {"Death Speaker Jargba", "Shadow Bolt, Dominate Mind on a random player."},
        {"Aggem Thorncurse", "Boar Spirit, Chain Heal."},
        {"Overlord Ramtusk", "Two Spearhides, Thunderclap."},
        {"Agathelos the Raging", "Rushing Charge, enrage near death."},
        {"Blind Hunter", "Rare. Sonic Burst silence, Ravage stun."},
        {"Earthcaller Halmgar", "Lightning Bolt, Earthbind Totem, Earth Rumbler."},
        {"Charlga Razorflank", "Chain Bolt, Renew, two seconds of Purity."},
    },
}

ns.tips.SM = {
    about = "Four wings behind four doors in Tirisfal Glades. Only the Graveyard (levels 30-38, the left-most door) is written up so far; the Library, Armory and Cathedral will follow. The Graveyard is short: two guaranteed bosses and three rares.",
    watch = {
        "Almost everything in the Monastery runs at low health and comes back with friends. Stun or kill runners.",
        "Scarlet Scryers sleep a player for 20 seconds (dispellable) and cast Shadow Bolt. Kill them early; break line of sight to make them walk to you.",
        "Anguished Dead cast Veil of Shadow: 75% less healing on the target. It can be interrupted, and removed as a curse.",
        "Haunting Phantasms summon copies that die in one hit. Tag them quickly.",
    },
    tank = {
        "Interrogator Vishas stands close to several packs. Clear them first. Keep his Immolate on you by holding threat.",
        "Fallen Champion cleaves: stand on the opposite side of him from the melee.",
        "Azshir the Sleepless drains you and the nearest other player. Have the next sturdiest person stand on you so it isn't a cloth wearer.",
    },
    heal = {
        "Bloodmage Thalnos: stay as far out as you can for Fire Nova, and heal anyone caught by Flame Spike, which leaves a burn.",
        "Azshir's Call of the Grave is a curse that goes off a minute later, even after he is dead. Remove it or have that player full.",
        "Ironspine's Poison Cloud ticks hard on everyone near him. Tank and melee need healing through it; you stand far back.",
    },
    dps = {
        "Thalnos: interrupt Shadow Bolt and step out of Flame Spike.",
        "Vishas: kill his Torturer or Scryer first.",
        "Azshir fears his target for four seconds. Fight him in open space, with ranged close enough that a fear doesn't run into another pack.",
        "Ironspine curses physical damage dealers with Curse of Weakness. Remove it from them; ignore it on casters.",
    },
    bosses = {
        {"Interrogator Vishas", "Graveyard. One add, Immolate on the tank."},
        {"Bloodmage Thalnos", "Graveyard, last boss. Shadow Bolt, Flame Spike, Fire Nova."},
        {"Azshir the Sleepless", "Graveyard rare. Terrify, Call of the Grave, Soul Siphon."},
        {"Fallen Champion", "Graveyard rare. Cleave."},
        {"Ironspine", "Graveyard rare. Curse of Weakness, Poison Cloud."},
    },
}
