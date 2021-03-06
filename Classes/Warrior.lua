local addon, ns = ...
local Hekili = _G[ addon ]

local class = ns.class
local state = ns.state

local addHook = ns.addHook

local addAbility = ns.addAbility
local modifyAbility = ns.modifyAbility
local addHandler = ns.addHandler

local addAura = ns.addAura
local modifyAura = ns.modifyAura

local addGearSet = ns.addGearSet
local addGlyph = ns.addGlyph
local addMetaFunction = ns.addMetaFunction
local addTalent = ns.addTalent
local addTrait = ns.addTrait
local addResource = ns.addResource
local addStance = ns.addStance

local setRegenModel = ns.setRegenModel

local addSetting = ns.addSetting
local addToggle = ns.addToggle

local registerCustomVariable = ns.registerCustomVariable
local registerInterrupt = ns.registerInterrupt

local removeResource = ns.removeResource

local setArtifact = ns.setArtifact
local setClass = ns.setClass
local setPotion = ns.setPotion
local setRole = ns.setRole
local setTalentLegendary = ns.setTalentLegendary


local RegisterEvent = ns.RegisterEvent
local RegisterUnitEvent = ns.RegisterUnitEvent

local storeDefault = ns.storeDefault


local PTR = ns.PTR or false

if (select(2, UnitClass('player')) == 'WARRIOR') then

    ns.initializeClassModule = function ()
    
        setClass( "WARRIOR" )

        setPotion( 'old_war' ) 
        -- Resources
        --addResource( "rage", nil, false )
        addResource( "rage", SPELL_POWER_RAGE, true )


        -- According to SimC 7.3.5:
        -- Base Rage Generation = 1.75
        -- Arms Rage Multiplier = 4.286
        -- Fury Rage Multiplier = 0.80

        local base_rage_gen, arms_rage_mult, fury_rage_mult = 1.75, 4.286, 0.80
        local offhand_mod = 0.80
        

        setRegenModel( {
            mainhand_arms = {
                resource = 'rage',
                spec = 'arms',
                setting = 'forecast_fury',
                

                last = function ()
                    local swing = state.combat == 0 and state.now or state.swings.mainhand
                    local t = state.query_time

                    return swing + ( floor( ( t - swing ) / state.swings.mainhand_speed ) * state.swings.mainhand_speed )
                end,

                interval = 'mainhand_speed',

                value = function ()
                    return base_rage_gen * arms_rage_mult * state.swings.mainhand_speed
                end,
            },


            mainhand_fury = {
                resource = 'rage',
                spec = 'fury',
                setting = 'forecast_fury',

                last = function ()
                    local swing = state.swings.mainhand
                    local t = state.query_time

                    return swing + ( floor( ( t - swing ) / state.swings.mainhand_speed ) * state.swings.mainhand_speed )
                end,

                interval = 'mainhand_speed',

                stop = function () return state.time == 0 end,
                
                value = function ()
                    return base_rage_gen * fury_rage_mult * state.swings.mainhand_speed
                end,
            },

            offhand_fury = {
                resource = 'rage',
                spec = 'fury',
                setting = 'forecast_fury',

                last = function ()
                    local swing = state.swings.offhand
                    local t = state.query_time

                    return swing + ( floor( ( t - swing ) / state.swings.offhand_speed ) * state.swings.offhand_speed )
                end,

                interval = 'offhand_speed',

                stop = function () return state.time == 0 end,
                
                value = function ()
                    return base_rage_gen * fury_rage_mult * state.swings.mainhand_speed * offhand_mod * ( state.talent.endless_rage.enabled and 1.3 or 1 )
                end,
            }
        } )
        
 
        -- Talents
        --[[ Anger Management: Every 20 Rage you spend reduces the remaining cooldown on Battle Cry and Bladestorm by 1 sec. ]]
        addTalent( "anger_management", 152278 ) -- 21204
        
        --[[ Avatar: Transform into a colossus for 20 sec, causing you to deal 20% increased damage and removing all roots and snares. ]]
        addTalent( "avatar", 107574 ) -- 19138

        --[[ Bladestorm: Become an unstoppable storm of destructive force, striking all targets within 8 yards with both weapons for 67,964 Physical damage over 5.6 sec.    You are immune to movement impairing and loss of control effects, but can use defensive abilities and can avoid attacks. ]]
        addTalent( "bladestorm", 46924 ) -- 22405

        --[[ Bloodbath: For 10 sec, your melee attacks and abilities cause the target to bleed for 40% additional damage over 6 sec. ]]
        addTalent( "bloodbath", 12292 ) -- 22395

        --[[ Bounding Stride: Reduces the cooldown on Heroic Leap by 15 sec, and Heroic Leap now also increases your run speed by 70% for 3 sec. ]]
        addTalent( "bounding_stride", 202163 ) -- 22627

        --[[ Carnage: Reduces the cost of Rampage by 15 Rage. ]]
        addTalent( "carnage", 202922 ) -- 19140

        --[[ Dauntless: Your abilities cost 10% less Rage. ]]
        addTalent( "dauntless", 202297 ) -- 22624

        --[[ Deadly Calm: Battle Cry also reduces the Rage cost of your abilities by 75% for the duration. ]]
        addTalent( "deadly_calm", 227266 ) -- 22394

        --[[ Defensive Stance: A defensive combat state that reduces all damage you take by 20%, and all damage you deal by 10%. Lasts until cancelled. ]]
        addTalent( "defensive_stance", 197690 ) -- 22628

        --[[ Double Time: Increases the maximum number of charges on Charge by 1, and reduces its cooldown by 3 sec. ]]
        addTalent( "double_time", 103827 ) -- 22409

        --[[ Dragon Roar: Roar explosively, dealing 6,498 damage to all enemies within 8 yards and increasing all damage you deal by 16% for 6 sec. Dragon Roar ignores all armor and always critically strikes. ]]
        addTalent( "dragon_roar", 118000 ) -- 16037

        --[[ Endless Rage: Your auto attack generates 30% additional Rage. ]]
        addTalent( "endless_rage", 202296 ) -- 22633

        --[[ Fervor of Battle: Whirlwind deals 80% increased damage to your primary target.  ]]
        addTalent( "fervor_of_battle", 202316 ) -- 22383
        
        --[[ Focused Rage: Focus your rage on your next Mortal Strike, increasing its damage by 30%, stacking up to 3 times. Unaffected by the global cooldown. ]]
        addTalent( "focused_rage", 207982 ) -- 22399

        --[[ Frenzy: Furious Slash increases your Haste by 5% for 10 sec, stacking up to 3 times. ]]
        addTalent( "frenzy", 206313 ) -- 22544

        --[[ Fresh Meat: Bloodthirst has a 60% increased critical strike chance against targets above 80% health. ]]
        addTalent( "fresh_meat", 215568 ) -- 22491

        --[[ Frothing Berserker: When you reach 100 Rage, your damage is increased by 15% and your movement speed by 30% for 6 sec. ]]
        addTalent( "frothing_berserker", 215571 ) -- 22391

        --[[ Furious Charge: Charge also increases the healing from your next Bloodthirst by 300%. ]]
        addTalent( "furious_charge", 202224 ) -- 22635

        --[[ In For The Kill: Colossus Smash grants you 10% Haste for 8 sec. ]]
        addTalent( "in_for_the_kill", 248621 ) -- 22397

        --[[ Inner Rage: Raging Blow no longer requires Enrage and deals 150% increased damage, but has a 4.5 sec cooldown. ]]
        addTalent( "inner_rage", 215573 ) -- 22400

        --[[ Massacre: Execute critical strikes reduce the Rage cost of your next Rampage by 100%. ]]
        addTalent( "massacre", 206315 ) -- 22384
        
        --[[ Mortal Combo: Mortal Strike now has a maximum of 2 charges. ]]
        addTalent( "mortal_combo", 202593 ) -- 22393

        --[[ Opportunity Strikes: Your melee abilities have up to a 60% chance, based on the target's missing health, to trigger an extra attack that deals 23,354 Physical damage and generates 5 Rage. ]]
        addTalent( "opportunity_strikes", 203179 ) -- 22407
      
        --[[ Outburst: Berserker Rage now causes Enrage, and its cooldown is reduced by 15 sec. ]]
        addTalent( "outburst", 206320 ) -- 22381

        --[[ Overpower: Overpowers the enemy, causing 54,736 Physical damage. Cannot be blocked, dodged or parried, and has a 60% increased chance to critically strike.    Your other melee abilities have a chance to activate Overpower. ]]
        addTalent( "overpower", 7384 ) -- 22360

        --[[ Ravager: Throws a whirling weapon at the target location that inflicts 260,141 damage to all enemies within 8 yards over 6.3 sec.     Generates 7 Rage each time it deals damage. ]]
        addTalent( "ravager", 152277 ) -- 21667

        --[[ Rend: Wounds the target, causing 21,894 Physical damage instantly and an additional 110,116 Bleed damage over 8 sec. ]]
        addTalent( "rend", 772 ) -- 22489

        --[[ Reckless Abandon: Battle Cry lasts 2 sec longer and generates 100 Rage. ]]
        addTalent( "reckless_abandon", 202751 ) -- 22402

        --[[ Second Wind: Restores 6% health every 1 sec when you have not taken damage for 5 sec. ]]
        addTalent( "second_wind", 29838 ) -- 15757        
        
        --[[ Shockwave: Sends a wave of force in a frontal cone, causing 1,905 damage and stunning all enemies within 10 yards for 3 sec.  Cooldown reduced by 20 sec if it strikes at least 3 targets. ]]
        addTalent( "shockwave", 46968 ) -- 22374

        --[[ Storm Bolt: Hurls your weapon at an enemy, causing 4,011 Physical damage and stunning for 4 sec. ]]
        addTalent( "storm_bolt", 107570 ) -- 22372

        --[[ Sweeping Strikes: Mortal Strike and Execute hit 2 additional nearby targets. ]]
        addTalent( "sweeping_strikes", 202161 ) -- 22371

        --[[ Titanic Might: Increases the duration of Colossus Smash by 8 sec, and reduces its cooldown by 8 sec. ]]
        addTalent( "titanic_might", 202612 ) -- 22800

        --[[ Trauma: Slam, Whirlwind, and Execute now cause the target to bleed for 20% additional damage over 6 sec. Multiple uses accumulate increased damage. ]]
        addTalent( "trauma", 215538 ) -- 22380
        
        --[[ War Machine: Killing a target grants you 30% Haste and 30% movement speed for 15 sec. ]]
        addTalent( "war_machine", 215556 ) -- 22632

        --[[ Warpaint: You now take only 15% increased damage from Enrage. ]]
        addTalent( "warpaint", 208154 ) -- 22382

        --[[ Wrecking Ball: Your attacks have a chance to make your next Whirlwind deal 250% increased damage. ]]
        addTalent( "wrecking_ball", 215569 ) -- 22379


        -- Traits
        addTrait( "battle_scars", 200857 )
        addTrait( "bloodcraze", 200859 )
        addTrait( "concordance_of_the_legionfall", 239042 )
        addTrait( "death_and_glory", 238148 )
        addTrait( "deathdealer", 200846 )
        addTrait( "focus_in_chaos", 200871 )
        addTrait( "fury_of_the_valarjar", 241269 )
        addTrait( "helyas_wrath", 200870 )
        addTrait( "juggernaut", 200875 )
        addTrait( "oathblood", 238112 )
        addTrait( "odyns_champion", 200872 )
        addTrait( "odyns_fury", 205545 )
        addTrait( "pulse_of_battle", 238076 )
        addTrait( "rage_of_the_valarjar", 200845 )
        addTrait( "raging_berserker", 200861 )
        addTrait( "sense_death", 200863 )
        addTrait( "thirst_for_battle", 200847 )
        addTrait( "titanic_power", 214938 )
        addTrait( "uncontrolled_rage", 200856 )
        addTrait( "unrivaled_strength", 200860 )
        addTrait( "unstoppable", 200853 )
        addTrait( "wild_slashes", 216273 )
        addTrait( "wrath_and_fury", 200849 )

         -- Traits Arms
        addTrait( "arms_of_the_valarjar", 241264 )
        addTrait( "colossus_smash", 208086 )
        addTrait( "corrupted_blood_of_zakajz", 209566 )
        addTrait( "crushing_blows", 209472 )
        addTrait( "deathblow", 209481 )
        addTrait( "defensive_measures", 209559 )
        addTrait( "executioners_precision", 238147 )
        addTrait( "exploit_the_weakness", 209494 )
        addTrait( "focus_in_battle", 209554 )
        addTrait( "many_will_fall", 216274 )
        addTrait( "one_against_many", 209462 )
        addTrait( "precise_strikes", 248579 )
        addTrait( "shattered_defenses", 248580 )
        addTrait( "soul_of_the_slaughter", 238111 )
        addTrait( "storm_of_swords", 238075 )
        addTrait( "tactical_advance", 209483 )
        addTrait( "thoradins_might", 209480 )
        addTrait( "touch_of_zakajz", 209541 )
        addTrait( "unbreakable_steel", 214937 )
        addTrait( "unending_rage", 209459 )
        addTrait( "void_cleave", 209573 )
        addTrait( "warbreaker", 209577 )
        addTrait( "will_of_the_first_king", 209548 )

        -- Shared/Fury Auras
        addAura( "avatar", 107574, "duration", 20 )
        addAura( "battle_cry", 1719, "duration", 5 )
            modifyAura( "battle_cry", "duration", function( x )
                return x + ( talent.reckless_abandon.enabled and 2 or 0 )
            end )

        -- Kinda dumb to implement this instead of just checking for deadly_calm talent, but I'm not in charge here.
        addAura( "battle_cry_deadly_calm", -100, "duration", 5, "feign", function ()
            local up = buff.battle_cry.up and talent.deadly_calm.enabled
            buff.battle_cry_deadly_calm.name = 'Battle Cry: Deadly Calm'
            buff.battle_cry_deadly_calm.count = up and 1 or 0
            buff.battle_cry_deadly_calm.expires = up and buff.battle_cry.expires or 0
            buff.battle_cry_deadly_calm.applied = up and buff.battle_cry.applied or 0
            buff.battle_cry_deadly_calm.caster = 'player'
        end )


        addAura( "berserker_rage", 18499, "duration", 18499 )
        addAura( "bladestorm", 46924, "duration", 6, "incapacitate", true ) -- Fury.

            modifyAura( "bladestorm", "duration", function( x )
                return x * haste
            end )
            modifyAura( "bladestorm", "id", function( x )
                return spec.arms and 227847 or 46924
            end )
            class.auras[ 227847 ] = class.auras[ 46924 ]

        addAura( "bloodbath", 12292, "duration", 10 )
        addAura( "bounding_stride", 202164, "duration", 3 )
        addAura( "cleave", 188923, "duration", 6, "max_stack", 5 )
        addAura( "colossus_smash", 208086, "duration", 8 )
        addAura( "corrupted_blood_of_zakajz", 209567, "duration", 5 )
        addAura( "commanding_shout", 97463, "duration", 10 )
        addAura( "defensive_stance", 197690, "duration", 3600 )
        addAura( "die_by_the_sword", 118038, "duration", 8 )
        addAura( "dragon_roar", 118000, "duration", 8 )
        addAura( "enrage", 184362, "duration", 4 )
        addAura( "enraged_regeneration", 184364, "duration", 8 )
        addAura( "executioners_precision", 242188, "duration", 30, "max_stack", 2 )
        addAura( "focused_rage", 207982, "duration", 30, "max_stack", 3 )
        addAura( "frenzy", 202539, "duration", 15, "max_stack", 3 )
        addAura( "frothing_berserker", 215571, "duration", 6 )
        addAura( "furious_charge", 202225, "duration", 5 )
        addAura( "hamstring", 1715, "duration", 15 )
        addAura( "in_for_the_kill", 248622, "duration", 8 )
        addAura( "intimidating_shout", 5246, "duration", 8 )
        addAura( "massacre", 206316, "duration", 10 )
        addAura( "mastery_colossal_might", 76838 )
        addAura( "mastery_unshackled_fury", 76856 )
        addAura( "meat_cleaver", 85739, "duration", 20 )
        addAura( "mortal_strike", 115804, "duration", 10 )
        addAura( "odyns_fury", 205546, "duration", 4 )
        addAura( "overpower", 60503, "duration", 12 )
        addAura( "piercing_howl", 12323, "duration", 15 )
        addAura( "ravager", 152277 )
        addAura( "rend", 772, "duration", 8 )
        addAura( "sense_death", 200979, "duration", 12 )
        addAura( "shattered_defenses", 248625, "duration", 10 )
        addAura( "shockwave", 46968, "duration", 3 )
        addAura( "storm_bolt", 107570, "duration", 4 )
        addAura( "tactician", 184783 )
        addAura( "taste_for_blood", 206333, "duration", 8, "max_stack", 6 )
        addAura( "titans_grip", 46917 )
        addAura( "victory_rush", 32216, "duration", 20 )
        addAura( "war_machine", 215557, "duration", 15 )
        addAura( "wrecking_ball", 215570, "duration", 10 )


        ns.addHook( "gain", function( amount, resource )
            if state.spec.fury and state.talent.frothing_berserker.enabled then
                if state.rage.current == 100 then state.applyBuff( "frothing_berserker" ) end
            end
        end )


        addGearSet( "stromkar_the_warbreaker", 128910 )
        setArtifact( "stromkar_the_warbreaker" )

        addGearSet( "warswords_of_the_valarjar", 128908 )
        setArtifact( "warswords_of_the_valarjar" )

        
        addGearSet( 'tier20', 147187, 147188, 147189, 147190, 147191, 147192 )
            addAura( "raging_thirst", 242300, "duration", 8 ) -- fury 2pc.
            addAura( "bloody_rage", 242952, "duration", 10, "max_stack", 10 ) -- fury 4pc.
            -- arms 2pc: CDR to bladestorm/ravager from colossus smash.
            -- arms 4pc: 2 auto-MS to nearby enemies when you ravager/bladestorm, not modeled.

        addGearSet( 'tier21', 152178, 152179, 152180, 152181, 152182, 152183 )
            addAura( "war_veteran", 253382, "duration", 8 ) -- arms 2pc.
            addAura( "weighted_blade", 253383, "duration", 1, "max_stack", 3 ) -- arms 4pc.
            addAura( "slaughter", 253384, "duration", 4 ) -- fury 2pc dot.
            addAura( "outrage", 253385, "duration", 8 ) -- fury 4pc.

        addGearSet( "ceannar_charger", 137088 )
        addGearSet( "timeless_stratagem", 143728 )
        addGearSet( "kazzalax_fujiedas_fury", 137053 )
            addAura( "fujiedas_fury", 207776, "duration", 10, "max_stack", 4 )
        addGearSet( "mannoroths_bloodletting_manacles", 137107 ) -- NYI.
        addGearSet( "najentuss_vertebrae", 137087 )
        addGearSet( "valarjar_berserkers", 151824 )
        addGearSet( "ayalas_stone_heart", 137052 )
            addAura( "stone_heart", 225947, "duration", 10 )
        addGearSet( "the_great_storms_eye", 151823 )
            addAura( "tornados_eye", 248142, "duration", 6, "max_stack", 6 )
        addGearSet( "archavons_heavy_hand", 137060 )
        addGearSet( "weight_of_the_earth", 137077 ) -- NYI.

        
        addGearSet( "soul_of_the_battlelord", 151650 )
        setTalentLegendary( 'soul_of_the_battlelord', 'arms', 'deadly_calm' )
        setTalentLegendary( 'soul_of_the_battlelord', 'fury', 'massacre' )
        

        addSetting( 'warbreaker_st', true, {
            name = "Warbreaker: Single Target",
            type = "toggle",
            desc = "If |cFF00FF00true|r, the addon will allow Warbreaker to be recommended in single-target situations.",
            width = "full"
        } )

        addSetting( 'forecast_fury', true, {
            name = "Forecast Fury Generation",
            type = "toggle",
            desc = "If |cFF00FF00true|r, the addon will anticipate Fury gains from your auto-attacks.",
            width = "full"
        } )


        -- Abilities

        -- Odyns Fury
        --[[ Unleashes the fiery power Odyn bestowed the Warswords, dealing (270% + 270%) Fire damage and an additional (400% of Attack power) Fire damage over 4 sec to all enemies within 14 yards. ]]

        addAbility( "odyns_fury", {
            id = 205545,
            spend = 0,
            cast = 0,
            gcdType = "melee",
            cooldown = 45,
            min_range = 0,
            max_range = 0,
            equipped = 'warswords_of_the_valarjar',
            toggle = 'artifact'
        } )

        addHandler( "odyns_fury", function ()
            applyDebuff( "target", "odyns_fury" )
            active_dot.odyns_fury = active_enemies
        end )


        -- Avatar
        --[[ Transform into a colossus for 20 sec, causing you to deal 20% increased damage and removing all roots and snares. ]]

        addAbility( "avatar", {
            id = 107574,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            talent = "avatar",
            cooldown = 90,
            min_range = 0,
            max_range = 0,
            toggle = 'cooldowns'
        } )

        addHandler( "avatar", function ()
            applyBuff( "avatar" )
        end )        
        
        
        -- Battle Cry
        --[[ Lets loose a battle cry, granting 100% increased critical strike chance for 5 sec. ]]

        addAbility( "battle_cry", {
            id = 1719,
            spend = 0,
            spend_type = "rage",
            cast = 0,
            gcdType = "off",
            cooldown = 60,
            min_range = 0,
            max_range = 0,
            recheck = function () return cooldown.global_cooldown.remains - 0.4, cooldown.global_cooldown.remains end,
            toggle = 'cooldowns'
        } )

        modifyAbility( "battle_cry", "spend", function( x )
            if talent.reckless_abandon.enabled then return -100 end
            return x
        end )

        addHandler( "battle_cry", function ()
            applyBuff( "battle_cry" )
            if talent.deadly_calm.enabled then applyBuff( "battle_cry_deadly_calm" ) end
            if artifact.corrupted_blood_of_zakajz.enabled then applyBuff( "corrupted_blood_of_zakajz" ) end
            if set_bonus.tier21 > 3 then applyBuff( "outrage" ) end
        end )


        -- Berserker Rage
        --[[ Go berserk, removing and granting immunity to Fear, Sap, and Incapacitate effects for 6 sec.    Also Enrages you for 4 sec. ]]

        addAbility( "berserker_rage", {
            id = 18499,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 60,
            min_range = 0,
            max_range = 0,
            toggle = 'cooldowns'
        } )

        modifyAbility( "berserker_rage", "cooldown", function( x )
            return x - ( talent.outburst.enabled and 15 or 0 )
        end )

        addHandler( "berserker_rage", function ()
            applyBuff( "berserker_rage" )
            if talent.outburst.enabled then 
                applyBuff( "enrage", 4 ) 
                if equipped.ceannar_charger then gain( 8, "rage" ) end
            end
        end )


        -- Bladestorm
        --[[ Become an unstoppable storm of destructive force, striking all targets within 8 yards with both weapons for 67,964 Physical damage over 5.6 sec.    You are immune to movement impairing and loss of control effects, but can use defensive abilities and can avoid attacks. ]]

        addAbility( "bladestorm", {
            id = 46924,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 90,
            min_range = 0,
            max_range = 0,
            talent = nil,
            notalent = "ravager",
            toggle = 'cooldowns'
        }, 227847 )

        modifyAbility( "bladestorm", "id", function( x )
            return spec.arms and 227847 or x
        end )

        modifyAbility( "bladestorm", "talent", function( x )
            if spec.fury then return "bladestorm" end
            return x
        end )

        modifyAbility( "bladestorm", "cast", function( x )
            return x * haste
        end )

        addHandler( "bladestorm", function ()
            applyBuff( "bladestorm", 6 )
            setCooldown( "global_cooldown", 6 * haste )
            if equipped.the_great_storms_eye then addStack( "tornados_eye", 6, 1 ) end
        end )


        -- Bloodbath
        --[[ For 10 sec, your melee attacks and abilities cause the target to bleed for 40% additional damage over 6 sec. ]]

        addAbility( "bloodbath", {
            id = 12292,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            talent = "bloodbath",
            cooldown = 30,
            min_range = 0,
            max_range = 0,
        } )

        addHandler( "bloodbath", function ()
            applyBuff( "bloodbath" )
        end )


        -- Bloodthirst
        --[[ Assault the target in a bloodthirsty craze, dealing 13,197 Physical damage and restoring 4% of your health.    Generates 10 Rage. ]]

        addAbility( "bloodthirst", {
            id = 23881,
            spend = -10,
            spend_type = "rage",
            cast = 0,
            gcdType = "spell",
            cooldown = 4.5,
            min_range = 0,
            max_range = 0,
        } )

        modifyAbility( "bloodthirst", "cooldown", function( x )
            return x * haste
        end )

        addHandler( "bloodthirst", function ()
            if stat.crit + 15 * buff.taste_for_blood.stack >= 100 then
                removeBuff( "taste_for_blood" )
            end
            removeBuff( "meat_cleaver" )
            if equipped.kazzalax_fujiedas_fury then addStack( "fujiedas_fury", 10, 1 ) end
            removeBuff( "bloody_rage" )
        end )

        
        -- Charge
        --[[ Charge to an enemy, dealing 2,675 Physical damage, rooting it for 1 sec and then reducing its movement speed by 50% for 6 sec.    Generates 20 Rage. ]]

        addAbility( "charge", {
            id = 100,
            spend = -20,
            spend_type = "rage",
            cast = 0,
            gcdType = "off",
            cooldown = 20,
            charges = 1,
            recharge = 20,
            min_range = 8,
            max_range = 25,
            passive = true,
            usable = function () return not ( prev_off_gcd.charge or prev_off_gcd.heroic_leap ) and target.maxR <= 25 and target.minR >= 7 end
        } )

        modifyAbility( "charge", "charges", function( x )
            return x + ( talent.double_time.enabled and 1 or 0 )
        end )

        modifyAbility( 'charge', 'cooldown', function( x )
            return x - ( talent.double_time.enabled and 3 or 0 )
        end )

        addHandler( 'charge', function()
            gain( 20, 'rage' )
            if talent.furious_charge.enabled then applyBuff( "furious_charge" ) end
            setDistance( 5 )
        end )

        -- Cleave
        --[[ Strikes all enemies in front of you with a sweeping attack for 13,137 Physical damage. For each target up to 5 hit, your next Whirlwind deals 20% more damage. ]]

        addAbility( "cleave", {
            id = 845,
            spend = 9,
            spend_type = "rage",
            cast = 0,
            gcdType = "spell",
            cooldown = 6,
            min_range = 0,
            max_range = 0,
            spec = "arms"
        } )

        addHandler( "cleave", function ()
            applyBuff( "cleave", 6, active_enemies )
        end )

        
        -- Colossus Smash
        --[[ Smashes the enemy's armor, dealing 42,079 Physical damage, and increasing damage you deal to them by 44% for 8 sec. ]]

        addAbility( "colossus_smash", {
            id = 167105,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 20,
            min_range = 0,
            max_range = 0,
        } )

        addHandler( "colossus_smash", function ()
            applyDebuff( "target", "colossus_smash", 8 )
            if artifact.shattered_defenses.enabled then applyBuff( "shattered_defenses" ) end
            if talent.in_for_the_kill.enabled then
                applyBuff( "in_for_the_kill" )
                stat.haste = state.haste + 0.1
            end
            if set_bonus.tier21 > 1 then applyBuff( "war_veteran" ) end
            if set_bonus.tier20 > 1 then
                if talent.ravager.enabled then setCooldown( "ravager", max( 0, cooldown.ravager.remains - 2 ) )
                else setCooldown( "bladestorm", max( 0, cooldown.bladestorm.remains - 3 ) ) end
            end
        end )        

        -- Commanding Shout
        --[[ Lets loose a commanding shout, granting all party or raid members within 30 yards 15% increased maximum health for 10 sec. After this effect expires, the health is lost. ]]

        addAbility( "commanding_shout", {
            id = 97462,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 180,
            min_range = 0,
            max_range = 0,
        } )

        addHandler( "commanding_shout", function ()
            applyBuff( "commanding_shout" )
        end )


        -- Defensive Stance
        --[[ A defensive combat state that reduces all damage you take by 20%, and all damage you deal by 10%. Lasts until cancelled. ]]

        addAbility( "defensive_stance", {
            id = 197690,
            spend = 0,
            cast = 0,
            gcdType = "off",
            talent = "defensive_stance",
            cooldown = 6,
            min_range = 0,
            max_range = 0,
        }, 212520 )

        modifyAbility( "defensive_stance", "id", function( x )
            if buff.defensive_stance.up then return 212520 end
            return x
        end )

        addHandler( "defensive_stance", function ()
            if buff.defensive_stance.up then removeBuff( "defensive_stance" )
            else applyBuff( "defensive_stance" ) end
        end )
        

         -- Die by the Sword
        --[[ Increases your parry chance by 100% and reduces all damage you take by 30% for 8 sec. ]]

        addAbility( "die_by_the_sword", {
            id = 118038,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 180,
            min_range = 0,
            max_range = 0,
        } )

        addHandler( "die_by_the_sword", function ()
            applyBuff( "die_by_the_sword" )
        end )

        
        -- Dragon Roar
        --[[ Roar explosively, dealing 6,498 damage to all enemies within 8 yards and increasing all damage you deal by 16% for 6 sec. Dragon Roar ignores all armor and always critically strikes. ]]

        addAbility( "dragon_roar", {
            id = 118000,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            talent = "dragon_roar",
            cooldown = 25,
            min_range = 0,
            max_range = 0,
        } )

        addHandler( "dragon_roar", function ()
            applyBuff( "dragon_roar" )
        end )


        -- Enraged Regeneration
        --[[ Reduces damage taken by 30%, and Bloodthirst restores an additional 20% health. Usable while stunned. Lasts 8 sec. ]]

        addAbility( "enraged_regeneration", {
            id = 184364,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 120,
            min_range = 0,
            max_range = 0,
        } )

        addHandler( "enraged_regeneration", function ()
            applyBuff( "enraged_regeneration" )
        end )


        -- Execute
        --[[ Attempt to finish off a wounded foe, causing 30,922 Physical damage. Only usable on enemies that have less than 20% health. ]]
        --[[ Arms: Attempts to finish off a foe, causing 29,484 Physical damage, and consuming up to 30 additional Rage to deal up to 88,453 additional damage. Only usable on enemies that have less than 20% health.    If your foe survives, 30% of the Rage spent is refunded. ]]

        addAbility( "execute", {
            id = 163201,
            spend = 10,
            min_cost = 10,
            spend_type = "rage",
            cast = 0,
            gcdType = "spell",
            cooldown = 0,
            min_range = 0,
            max_range = 0,
            usable = function () return buff.stone_heart.up or target.health_pct < 20 end,
        }, 5308 )

        modifyAbility( "execute", "id", function( x )
            if spec.fury then return 5308 end
            return x
        end )

        modifyAbility( "execute", "spend", function( x )            
            if spec.fury then
                if buff.sense_death.up then return 0 end
                if buff.stone_heart.up then return 0 end
                return 25
            end

            if talent.dauntless.enabled then x = x * 0.9 end
            if talent.deadly_calm.enabled and buff.battle_cry.up then x = x * 0.25 end
            return x
        end )
        
        modifyAbility( "execute", "min_cost", function( x )
            if spec.fury then return 25 end
            return x
        end  )

        addHandler( "execute", function ()
            if spec.arms then
                local addl_cost = 10 * ( talent.dauntless.enabled and 0.9 or 1 ) * ( talent.deadly_calm.enabled and buff.battle_cry.up and 0.25 or 1 )
                if buff.stone_heart.down then                
                    spend( min( addl_cost, rage.current ), "rage" ) 
                end
                removeBuff( "stone_heart" )
                if artifact.executioners_precision.enabled then addStack( "executioners_precision", 30, 1 ) end
                removeBuff( "shattered_defenses" )
                gain( ( action.execute.cost + addl_cost ) * 0.3, "rage" )
            elseif spec.fury then
                if buff.stone_heart.up then removeBuff( "stone_heart" )
                else removeBuff( "sense_death" ) end
            end
        end )


        -- Focused Rage
        --[[ Focus your rage on your next Mortal Strike, increasing its damage by 30%, stacking up to 3 times. Unaffected by the global cooldown. ]]

        addAbility( "focused_rage", {
            id = 207982,
            spend = 20,
            min_cost = 20,
            spend_type = "rage",
            cast = 0,
            gcdType = "off",
            talent = "focused_rage",
            cooldown = 1.5,
            min_range = 0,
            max_range = 0,
        } )

        addHandler( "focused_rage", function ()
            addStack( "focused_rage", 30, 1 )
        end )
        

        -- Furious Slash
        --[[ Aggressively strike with your off-hand weapon for 3,520 Physical damage. Increases your Bloodthirst critical strike chance by 15% until it next deals a critical strike, stacking up to 6 times. ]]

        addAbility( "furious_slash", {
            id = 100130,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 0,
            min_range = 0,
            max_range = 0,
        } )

        addHandler( "furious_slash", function ()
            addStack( "taste_for_blood", 8, 1 )
            addStack( "frenzy", 15, 1 )
        end )


         -- Hamstring
        --[[ Maims the enemy for 15,326 Physical damage, reducing movement speed by 50% for 15 sec. ]]

        addAbility( "hamstring", {
            id = 1715,
            spend = 10,
            spend_type = "rage",
            cast = 0,
            gcdType = "spell",
            cooldown = 0,
            min_range = 0,
            max_range = 0,
        } )

        modifyAbility( "hamstring", "spend", function( x )
            if talent.dauntless.enabled then return x * 0.9 end
            return x
        end )

        addHandler( "hamstring", function ()
            applyDebuff( "target", "hamstring", 15 )
        end )


        -- Heroic Leap
        --[[ Leap through the air toward a target location, slamming down with destructive force to deal 2,385 Physical damage to all enemies within 8 yards. ]]

        addAbility( "heroic_leap", {
            id = 6544,
            spend = 0,
            cast = 0,
            gcdType = "off",
            cooldown = 45,
            charges = 1,
            recharge = 45,
            min_range = 8,
            max_range = 40,
            passive = true,
            usable = function () return not ( target.minR < 7 or target.maxR > 40 ) and not ( prev_gcd.heroic_leap or prev_gcd.charge ) end
        } )

        modifyAbility( "heroic_leap", "cooldown", function( x )
            return x - ( talent.bounding_stride.enabled and 15 or 0 )
        end )

        modifyAbility( "heroic_leap", "charges", function( x )
            return equipped.timeless_stratagem and 3 or x
        end )

        addHandler( "heroic_leap", function ()
            -- This *would* reset CD on Taunt for Prot.
            setDistance( 5 )
            applyBuff( "bounding_stride" )
        end )


        -- Heroic Throw
        --[[ Throws your weapon at the enemy, causing 2,519 Physical damage. Generates high threat. ]]

        addAbility( "heroic_throw", {
            id = 57755,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 6,
            min_range = 8,
            max_range = 30,
        } )

        addHandler( "heroic_throw", function ()
            -- Generates high threat.
        end )


        -- Intimidating Shout
        --[[ Causes the targeted enemy to cower in fear, and up to 5 additional enemies within 8 yards to flee. Targets are disoriented for 8 sec. ]]

        addAbility( "intimidating_shout", {
            id = 5246,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 90,
            min_range = 0,
            max_range = 8,
        } )

        addHandler( "intimidating_shout", function ()
            applyDebuff( "target", "intimidating_shout" )
            active_dot.intimidating_shout = min( 6, active_enemies )
        end )


        -- Mortal Strike
        --[[ A vicious strike that deals 64,077 Physical damage and reduces the effectiveness of healing on the target for 10 sec. ]]

        addAbility( "mortal_strike", {
            id = 12294,
            spend = 20,
            spend_type = "rage",
            cast = 0,
            gcdType = "spell",
            cooldown = 6,
            charges = 1,
            recharge = 6,
            min_range = 0,
            max_range = 0,
        } )

        modifyAbility( "mortal_strike", "spend", function( x )
            x = x * ( talent.dauntless.enabled and 0.9 or 1 ) 
            if equipped.archavons_heavy_hand then x = x - 8 end
            return x
        end )

        addHandler( "mortal_strike", function ()
            applyDebuff( "target", "mortal_strike" )
            removeBuff( "shattered_defenses" )
            if set_bonus.tier21 > 3 then addStack( "weighted_blade", 12, 1 ) end
        end )


       -- Overpower
        --[[ Overpowers the enemy, causing 54,736 Physical damage. Cannot be blocked, dodged or parried, and has a 60% increased chance to critically strike.    Your other melee abilities have a chance to activate Overpower. ]]

        addAbility( "overpower", {
            id = 7384,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            talent = "overpower",
            buff = "overpower",
            cooldown = 0,
            min_range = 0,
            max_range = 0,
        } )

        addHandler( "overpower", function ()
            removeBuff( "overpower" )
        end )


        -- Piercing Howl
        --[[ Snares all enemies within 15 yards, reducing their movement speed by 50% for 15 sec. ]]

        addAbility( "piercing_howl", {
            id = 12323,
            spend = 10,
            min_cost = 10,
            spend_type = "rage",
            cast = 0,
            gcdType = "spell",
            cooldown = 0,
            min_range = 0,
            max_range = 0,
        } )

        addHandler( "piercing_howl", function ()
            applyDebuff( "target", "piercing_howl" )
            active_dot.piercing_howl = active_enemies
        end )


        -- Pummel
        --[[ Pummels the target, interrupting spellcasting and preventing any spell in that school from being cast for 4 sec. ]]

        addAbility( "pummel", {
            id = 6552,
            spend = 0,
            cast = 0,
            gcdType = "off",
            cooldown = 15,
            min_range = 0,
            max_range = 0,
            usable = function() return target.casting end,
            toggle = 'interrupts'
        } )

        addHandler( "pummel", function ()
            interrupt()
        end )


        -- Raging Blow
        --[[ A mighty blow with both weapons that deals a total of 10,204 Physical damage. Only usable while Enraged.    Generates 5 Rage. ]]

        addAbility( "raging_blow", {
            id = 85288,
            spend = -5,
            spend_type = "rage",
            cast = 0,
            gcdType = "spell",
            cooldown = 0,
            min_range = 0,
            max_range = 0,
            buff = nil,
        } )

        modifyAbility( "raging_blow", "buff", function( x )
            if not talent.inner_rage.enabled then return "enrage" end
            return x
        end )

        modifyAbility( "raging_blow", "cooldown", function( x )
            if talent.inner_rage.enabled then return 4.5 * haste end
            return x
        end )

        addHandler( "raging_blow", function ()
            removeBuff( "raging_thirst" )
            if set_bonus.tier21 > 3 then addStack( "bloody_rage", 10, 1 ) end
        end )


        -- Rampage
        --[[ Enrages you and unleashes a series of 5 brutal strikes over 2 sec for a total of 24,668 Physical damage. ]]

        addAbility( "rampage", {
            id = 184367,
            spend = 85,
            spend_type = "rage",
            cast = 0,
            gcdType = "spell",
            cooldown = 1.5,
            min_range = 0,
            max_range = 0,
        } )

        modifyAbility( "rampage", "spend", function( x )
            if buff.massacre.up then return 0 end            
            return x - ( talent.carnage.enabled and 15 or 0 )
        end )

        addHandler( 'rampage', function ()
            removeBuff( "massacre" )
            applyBuff( 'enrage', 4 )
            removeBuff( "meat_cleaver" )
            if set_bonus.tier21 > 1 then applyDebuff( "target", "slaughter" ) end
        end )
        

        -- Ravager
        --[[ Throws a whirling weapon at the target location that inflicts 260,141 damage to all enemies within 8 yards over 6.3 sec.     Generates 7 Rage each time it deals damage. ]]

        addAbility( "ravager", {
            id = 152277,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            talent = "ravager",
            cooldown = 60,
            min_range = 0,
            max_range = 40,
        } )

        addHandler( "ravager", function ()
            if equipped.the_great_storms_eye then addStack( "tornados_eye", 6, 1 ) end
        end )
        

        -- Rend
        --[[ Wounds the target, causing 21,894 Physical damage instantly and an additional 110,116 Bleed damage over 8 sec. ]]

        addAbility( "rend", {
            id = 772,
            spend = 30,
            min_cost = 30,
            spend_type = "rage",
            cast = 0,
            gcdType = "spell",
            talent = "rend",
            cooldown = 0,
            min_range = 0,
            max_range = 0,
        } )

        addHandler( "rend", function ()
            applyDebuff( "target", "rend" )
        end )
        

        -- Shockwave
        --[[ Sends a wave of force in a frontal cone, causing 5,230 damage and stunning all enemies within 10 yards for 3 sec. Cooldown reduced by 20 sec if it strikes at least 3 targets. ]]

        addAbility( "shockwave", {
            id = 46968,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            talent = "shockwave",
            cooldown = 40,
            min_range = 0,
            max_range = 0,
        } )

        modifyAbility( "shockwave", "cooldown", function( x )
            if active_enemies > 2 then return x - 20 end
            return x
        end )

        addHandler( "shockwave", function ()
            applyDebuff( "target", "shockwave" )
            active_dot.shockwave = active_enemies
        end )


        -- Slam
        --[[ Slams an opponent, causing 44,530 Physical damage. ]]

        addAbility( "slam", {
            id = 1464,
            spend = 20,
            spend_type = "rage",
            cast = 0,
            gcdType = "spell",
            cooldown = 0,
            min_range = 0,
            max_range = 0,
        } )

        modifyAbility( "slam", "spend", function( x )
            if talent.dauntless.enabled then return x * 0.9 end
            return x
        end )

        addHandler( "slam", function ()
            removeBuff( "weighted_blade" )
        end )
        
        
        -- Storm Bolt
        --[[ Hurls your weapon at an enemy, causing 4,011 Physical damage and stunning for 4 sec. ]]

        addAbility( "storm_bolt", {
            id = 107570,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            talent = "storm_bolt",
            cooldown = 30,
            min_range = 0,
            max_range = 20,
        } )

        addHandler( "storm_bolt", function ()
            applyDebuff( "target", "storm_bolt" )
        end )


        -- Taunt
        --[[ Taunts the target to attack you, and increases threat that you generate against the target for 3 sec. ]]

        addAbility( "taunt", {
            id = 355,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 8,
            min_range = 0,
            max_range = 30,
        } )

        addAura( "taunt", 355, "duration", 3 )

        addHandler( "taunt", function ()
            applyDebuff( "target", "taunt" )
        end )


        -- Victory Rush
        --[[ Strikes the target, causing 22,022 damage and healing you for 30% of your maximum health.    Only usable within 20 sec after you kill an enemy that yields experience or honor. ]]

        addAbility( "victory_rush", {
            id = 34428,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 0,
            min_range = 0,
            max_range = 0,
            nospec = "fury",
            buff = "victory_rush"
        } )

        addHandler( "victory_rush", function ()
            removeBuff( "victory_rush" )
        end )


        -- Warbreaker
        --[[ Stomp the ground, causing a ring of corrupted spikes to erupt upwards, dealing 44,424 Shadow damage and applying the Colossus Smash effect to all nearby enemies. ]]

        addAbility( "warbreaker", {
            id = 209577,
            spend = 0,
            cast = 0,
            gcdType = "spell",
            cooldown = 60,
            min_range = 0,
            max_range = 100,
            toggle = 'artifact',
            equipped = 'stromkar_the_warbreaker',
            trait = 'warbreaker',
            usable = function () return active_enemies > 1 or settings.warbreaker_st end,
        } )

        addHandler( "warbreaker", function ()
            applyDebuff( "target", "colossus_smash" )
            active_dot.colossus_smash = active_enemies
        end )


        -- Whirlwind
        --[[ Unleashes a whirlwind of steel, striking all enemies within 8 yards for 8,348 Physical damage.    Causes your next Bloodthirst or Rampage to strike up to 4 additional targets for 50% damage. ]]
        --[[ Arms: Unleashes a whirlwind of steel, striking all enemies within 8 yards for 39,410 Physical damage. ]]

        addAbility( "whirlwind", {
            id = 1680,
            spend = 30,
            min_cost = 30,
            spend_type = "rage",
            cast = 0,
            gcdType = "spell",
            cooldown = 0,
            min_range = 0,
            max_range = 0,
        }, 190411 )

        modifyAbility( "whirlwind", "id", function( x )
            if spec.fury then return 190411 end
            return x
        end )

        modifyAbility( "whirlwind", "spend", function( x )
            if spec.fury then return 0 end
            return x
        end )
        
        addHandler( "whirlwind", function ()
            if spec.fury then applyBuff( "meat_cleaver" ) end
            removeBuff( "wrecking_ball" )
            removeBuff( "weighted_blade" )
        end )

    end
   

    storeDefault( [[SimC Arms: single]], 'actionLists', 20180418.215623, [[daeUoaqiuqBIKQrjvQtbfSkuPi7cvnmO0XKKLrv1ZKkX0KkPRbfQTbfIVHcnoQkHZbfswhui18qbUhQuTpQk1brLSquKhIIAIOsrDrsOnIkfCssk3uQANq1prLsTuuYtjMkjARuv8vQkr7v5VsQbtPdlAXa9yHMmvUSQndOptcgnj50s8AOOzl42sz3i(nKHJsDCuPKLJ0Zj10bDDQY2rfFhaJNQs68sfRhvk08bO9tXRAkNGNTprknMnwUOnngTXQlefcFIW(XsgkCJjSGidNXQjSE4P(d3p2kgR8JTl8(XIXyKUY4ejslSHtMWvewqe9uo8QPCIIKemC3yAIePf2WjGEabYdMqy41rAhEp2gR6gB3gR(WAqeXtZdlN6hBDxzhnwFBSynwab0yp3YRWM9D8qvVwb6tyTgIOnD97CJfdt4cSekWotadP7AiI2MOgXvIjerNqqKpPh58jP4z7tMGNTpHPq6UgIOTjSE4P(d3p2kgRWoH11ipA86PCWjmR6rm7rCE7e4aN0JC4z7tgC4(NYjkssWWDJPjsKwydNa6beiVwvcHNExT7aprFnVdbazcxGLqb2zsefqATNUw3sTQjQrCLycr0jee5t6roFskE2(Kj4z7tygfqATN2yLwQvnH1dp1F4(XwXyf2jSUg5rJxpLdoHzvpIzpIZBNah4KEKdpBFYGdVlt5efjjy4UX0ejslSHt62y72yHz4eipWt5GO1iG1Gjego)jjy4oJvDJ1DqpGa5JOasR9016wQvXtFlleTXYaJvHOZyXGXciGgldnwygobYd8uoiAncynycHHZFscgUZyv3y72y72yb9acKxdrKxR6jfY7X2ybeqJnIqbhcacFdrHzOwdPfmpp9TSq0gld4UXgrOGdbaHxHacmd1rek4qaq4PVLfI2yXGXQUXc6beiVwvcHNExT7aprFnVdbaXyXGXIHjCbwcfyNjaKuq6tmpDIAexjMqeDcbr(KEKZNKINTpzcE2(eFzsbPpX80jSE4P(d3p2kgRWoH11ipA86PCWjmR6rm7rCE7e4aN0JC4z7tgC4DDkNOijbd3nMMirAHnCcdnwqpGa5btim86iTtT7Pl0PoMHgVhBJvDJf0diqEGOON(UAAQW51WmIPXYaJTlgR6gldn2icfCiai8ruaP1E6ADl1Q49yBSQBSDBS0uHZh9O0tGgRV5UXw1fSglGaASUd6beiFefqATNUw3sTkEhcaIXciGglmdNa5tIcNw3ssQWBNa5pjbd3zSQBSrek4qaq4btim86iTdp9TSq0gld4UX6lmwmmHlWsOa7mbik6PVRMMk8jQrCLycr0jee5t6roFskE2(Kj4z7t4gqrp9DglRuHpH1dp1F4(XwXyf2jSUg5rJxpLdoHzvpIzpIZBNah4KEKdpBFYGdhJNYjkssWWDJPjsKwydNqFlleTXYaUBSkeDglGaAS03YcrBSmWyXyJvDJnIqbhcacpycHHxhPD4PVLfI2yzGX63yv3y72yJiuWHaGWdgs31qeTXtFlleTXYaJ1VXciGgldnw9H1GiINMhwo1p26UYoAS(2yXASyycxGLqb2zc9e3e1iUsmHi6ecI8j9iNpjfpBFYe8S9jSoXnH1dp1F4(XwXyf2jSUg5rJxpLdoHzvpIzpIZBNah4KEKdpBFYGdhJmLtuKKGH7gttKiTWgojIqbhcacpycHHxhPD4PVLfI2yza3nwfIoJvDJ1DqpGa5JOasR9016wQvXtFlleTX6BJfJmHlWsOa7mHMCsfoDIAexjMqeDcbr(KEKZNKINTpzcE2(ewjNuHtNW6HN6pC)yRySc7ewxJ8OXRNYbNWSQhXShX5TtGdCspYHNTpzWHZ4uorrscgUBmnrI0cB4eqpGa51qe51QEsH8ESNWfyjuGDMCF9rp4NOgXvIjerNqqKpPh58jP4z7tMGNTprrF9rp4NW6HN6pC)yRySc7ewxJ8OXRNYbNWSQhXShX5TtGdCspYHNTpzWH7lMYjkssWWDJPjsKwydNa6beipycHHxhPD4Diait4cSekWotqCoLncGtNOgXvIjerNqqKpPh58jP4z7tMGNTpHBZ5u2iaoDcRhEQ)W9JTIXkStyDnYJgVEkhCcZQEeZEeN3oboWj9ihE2(Kbhog1uorrscgUBmnrI0cB4eqpGa51Qsi807QDh4j6R59yBSacOX6oOhqG83xF0dwqKt11SPpw0feH3HaGmHlWsOa7mPHOWmuRH0cMFIAexjMqeDcbr(KEKZNKINTpzcE2(KEefMbJvG0cMFcRhEQ)W9JTIXkStyDnYJgVEkhCcZQEeZEeN3oboWj9ihE2(KbhEf2PCIIKemC3yAIePf2Wj03YcrBSmG7gRZJMWcIySCtglw(UmHlWsOa7mHEIBIAexjMqeDcbr(KEKZNKINTpzcE2(ewN4m2URWWewp8u)H7hBfJvyNW6AKhnE9uo4eMv9iM9ioVDcCGt6ro8S9jdo8QQPCIIKemC3yAIePf2WjWmCcKh4PCq0AeWAWecdN)KemCNXQUXc6beiFm8KZ5DiaigR6gldn2ZT8kSzFhFsJQsoiIUw1toDQvLe3eUalHcSZKy4jNprnIRetiIoHGiFspY5tsXZ2NmbpBFcZHNC(ewp8u)H7hBfJvyNW6AKhnE9uo4eMv9iM9ioVDcCGt6ro8S9jdo8k)t5efjjy4UX0ejslSHtYiSW51N8w5AJ13gBLXciGglmdNa5bEkheTgbSgmHWW5pjbd3nHlWsOa7mbavfAaGcXnrnIRetiIoHGiFspY5tsXZ2NmbpBFIVuvHgaOqCty9Wt9hUFSvmwHDcRRrE041t5Gtyw1Jy2J482jWboPh5WZ2Nm4WR6YuorrscgUBmnrI0cB4KmclCE9jVvU2y5UXwzSQBSm0yHz4eipWt5GO1iG1Gjego)jjy4oJvDJTBJLMkC(OhLEc0y9n3nwm2VXciGgldnwygobYtpXXFscgUZybeqJLHglmdNa5PjNuHt5pjbd3zSyycxGLqb2zIoKTjQrCLycr0jee5t6roFskE2(Kj4z7tKq2MW6HN6pC)yRySc7ewxJ8OXRNYbNWSQhXShX5TtGdCspYHNTpzWHx11PCIIKemC3yAcxGLqb2zcIZPSraC6e1iUsmHi6ecI8j9iNpjfpBFYe8S9jCBoNYgbWPgB3vyycRhEQ)W9JTIXkStyDnYJgVEkhCcZQEeZEeN3oboWj9ihE2(KbhEfgpLtuKKGH7gttKiTWgoHHgR(WAqeXtZdlN6hBDxzhnwFBSyNWfyjuGDMags31qeTnrnIRetiIoHGiFspY5tsXZ2NmbpBFctH0DnerBgB3vyycRhEQ)W9JTIXkStyDnYJgVEkhCcZQEeZEeN3oboWj9ihE2(KbhCc38bMEb4yAWna]] )

    storeDefault( [[SimC Arms: default]], 'actionLists', 20180418.215623, [[dCK8oaqisQArKuztKGpjQIAuOaNsHQzHcQSlcgMahdcltqEMOkmnskDnsk2gkP6BOqJdLuY5qjLADOKmpfu3dLyFIIoik1cjHEOczIOKIUiLOnIcQ6KIcReLuyMOGCtiANe6NIQidffuSukPNs1ufuxvHs1wfv1BvO4UIQ0Ev9xHmyqhwPfdPhtXKv0Lr2Sq9zs0OfLonPwTcLYRPeMTKUTe7MOFd1WjjlhvpxKPl11PuBxb(UcY4vOKZlQSEuqP5JI2pWhXdFxCl0DxxgbGS5LeRaWjfV21(URIm6TQzy3wJLxKre3TsvAt0fdfGGreHcYdHqbQH1vlJ3DdxRQVFNTP1yz6HViIh(ULYfTsZR4D2O6QUZD3KD5kP7ziNAZ2y(Djws3rIN5VCXTq3VlUf6(OSlxjD3kvPnrxmuacgreC3kLW2CdLE433hLLmwGepGkKSp6DK4P4wO7VVyOh(ULYfTsZR4D3W1Q67maavpa2BLKTWoy7LlqYfTstaKjtae1oowyhS9YfSvbGJdGkaGO2XXcOB3vkYWZjyRcavaaNeQDCSGbxXPKDkkv2uwbBvaitMayVCLul06cf14OPMaWHzbadX63zJQR6o3Dv4wJL3Zqo1MTX87sSKUJepZF5IBHUFxCl0DMM44GaJjoEmmm4wJL5Lj)UvQsBIUyOaemIi4UvkHT5gk9WVVpklzSajEavizF07iXtXTq3FFX84HVBPCrR08kE3nCTQ(oQDCSa62DLIm8Cc2QaqMmbWE5kPwO1fkQXrtnbGdZcaIG1VZgvx1DU7OvmEgfBZZDpd5uB2gZVlXs6os8m)LlUf6(DXTq3vSIXtaKH3MN7UvQsBIUyOaemIi4UvkHT5gk9WVVpklzSajEavizF07iXtXTq3FFr1(W3TuUOvAEfV7gUwvFh1oowaD7UsrgEobBvaitMayVCLul06cf14OPMaWHzbarG4oBuDv35UJs8eXTqlvEpd5uB2gZVlXs6os8m)LlUf6(DXTq3vK4jIBHwQ8UvQsBIUyOaemIi4UvkHT5gk9WVVpklzSajEavizF07iXtXTq3FFr18W3TuUOvAEfV7gUwvFh1oowaD7UsrgEUOjTZAUiZwlct8qsaubaKVkjHjfRn6gaZeavBaaQaaAW46epKuaD7UsrgEobovwTmbGzcGb3zJQR6o39LBwjf1yoNK99mKtTzBm)UelP7iXZ8xU4wO73f3cDNn3SscadJ5Cs23TsvAt0fdfGGreb3TsjSn3qPh(99rzjJfiXdOcj7JEhjEkUf6(7lY6p8DlLlALMxX7UHRv13rTJJfq3URuKHNtWwfaYKja2lxj1cTUqrnoAQjaCywaqeiUZgvx1DU7vTYSDkASzpvwizFpd5uB2gZVlXs6os8m)LlUf6(DXTq3ziTYSDEobGSg2tLfs23TsvAt0fdfGGreb3TsjSn3qPh(99rzjJfiXdOcj7JEhjEkUf6(7lY4dF3s5IwP5v8UB4Av9DdgxN4HKckRy0TgzW46epKuGtLvlta4WayGqi1aGkaGmaarTJJfq3URuKHNtWwfaYKjaAW46epKuaD7UsrgEobovwTmbGddGiudaooaYKja2lxj1cTUqrnoAQjaCywaWqb3zJQR6o39DW2l)EgYP2SnMFxIL0DK4z(lxCl097IBHUZEW2l)UvQsBIUyOaemIi4UvkHT5gk9WVVpklzSajEavizF07iXtXTq3FFrwRh(ULYfTsZR4D3W1Q67maazaa2lxj1cTUqrnoAQjamtwaqgdaqMmbWe1rOyPDsO1epuqKAvzaWmbWaaCCaubaKbaidaqdgxN4HKckRy0TgzW46epKuGtLvlta4WSaGbcQbavaavXPbrkntbec8DWQK4a44aitMaO6bWERKSf47GvjXfi5IwPjaQaaQEa0GX1jEiPGYkgDRrgmUoXdjf4uz1YeaMjagaGkaG9YvsTWKqTJJfm4koLStrPYMYkWPYQLjamtwaq1aGkaGmaavpaAW46epKuaTUtk1yErGtLvltayMayaaYKjaQEamrDekwANeAnXdfePwvgamtamaahhavaazaaQEaS3kjBbojNcKCrR0eazYeaN4wGtYPaNkRwMaWmbq1cGJdGJdGJdGmzcGtc1oowGglYy3ASK4PivCYOtASui1RXcaKfameaQaaIAhhlKYUDtCAgnPysMOKGTkaubau9aObJRt8qsbLvm6wJmyCDIhskWPYQLjamtamaavaavpaMOocflTtcTM4HcIuRkdaMjagCNnQUQ7C3r3URuKHN7EgYP2SnMFxIL0DK4z(lxCl097IBHUR42DLaWr8C3TsvAt0fdfGGreb3TsjSn3qPh(99rzjJfiXdOcj7JEhjEkUf6(7lYA)W3TuUOvAEfV7gUwvFh1oowaD7UsrgEobBvaOca4KqTJJfm4koLStrPYMYkyR6oBuDv35UBNOiDtL09mKtTzBm)UelP7iXZ8xU4wO73f3cDNPjooiWyIJhZypraygnvs5Lj)UvQsBIUyOaemIi4UvkHT5gk9WVVpklzSajEavizF07iXtXTq3FFrebp8DlLlALMxX7UHRv137LRKAHS0w7ScQmnaomlayOaaubaCnTEafrsQOPeaomaQM7Sr1vDN7o3wgTMwJLrvDQVpklzSajEavizF07iXZ8xU4wO73f3cDNPjooiWyIJhJvBjaY20ASeaziDQZlt(D2CLP7YTqSOoxxgbGS5LeRaqASiJDtQJHRxUsQJ0XS0lxj1czPT2zfuz6HzjuGcRP1dOissfnLgwn3TsvAt0fdfGGreb3TsjSn3qPh(99mKtTzBm)UelP7iXtXTq3DDzeaYMxsScaPXIm2n9(Iiq8W3TuUOvAEfV7gUwvFFnTEafrsQOPeaMjlaOAVZgvx1DU7CBz0AAnwgv1P((OSKXcK4buHK9rVJepZF5IBHUFxCl0DMM44GaJjoEmwTLaiBtRXsaKH0PoVm5aidqm(D2CLP7YTqSOoxxgbGS5LeRaq25jlv3DRuL2eDXqbiyerWDRucBZnu6HFFpd5uB2gZVlXs6os8uCl0DxxgbGS5LeRaq25jlFFreHE47wkx0knVI3DdxRQVVMwpGIijv0ucaZKfam0D2O6QUZDNBlJwtRXYOQo13hLLmwGepGkKSp6DK4z(lxCl097IBHUZ0ehheymXXJXQTeazBAnwcGmKo15LjhazqOXVZMRmDxUfIf156YiaKnVKyfaAQ0oGu3DRuL2eDXqbiyerWDRucBZnu6HFFpd5uB2gZVlXs6os8uCl0DxxgbGS5LeRaqtL2b07lIipE47wkx0knVI3DdxRQV3lxj1czPT2zfuzAamtamuWD2O6QUZDNBlJwtRXYOQo13hLLmwGepGkKSp6DK4z(lxCl097IBHUZ0ehheymXXJXQTeazBAnwcGmKo15LjhazqEm(D2CLP7YTqSOoxxgbGS5LeRaWKwQSsQ7UvQsBIUyOaemIi4UvkHT5gk9WVVNHCQnBJ53LyjDhjEkUf6URlJaq28sIvayslvwP3VVZAsXRDTVIV)b]] )

    storeDefault( [[SimC Arms: precombat]], 'actionLists', 20180418.215623, [[b4vmErLxt5uyTvMxtnvATnKFGfKCTnNo(bgCYv2yV1MyHrNxtnfCLnwAHXwA6fgDP9MBE50nX41usvgBLf2CL5LtYatm3eJmWmJlYatn2qZnEn1uJjxAWrNxt51ubngDP9MBZ5fvE5umErLxtvKBHjgBLrMxc51ubjwASLgD551uW9gDP9MBEnvsUrwAJfgDVjNxt52BUvMxt10BKzvyY5uyTvMxt51uofwBL51u8nMzMbdmJnMzMTfuVrxAV5wx8jNxtjvzSvwyZvMxojdmXCtmW41usv2CVvNCJv2CErLx051udHwzJTwtVzxzTvMB05LyEnvtVrMtH1wzEnLx05fDEnfrLzwy1XgDEjKx05Lx]] )

    storeDefault( [[SimC Arms: execute]], 'actionLists', 20180418.215623, [[d8dBlaqAHwVirSjOs7cfBdkL2hsvUm4Xuz2IA(ukUPk58Iu3wvEoQ2js2R0UjSFI(Pku0WGIXPcL8nOIxtv1GPy4iLdcv5uIeoMk15uHclePYsPelwvTCepKsYtjTmQI1PcLAIIevtLs1KfmDLUiLstdkvpdPQUokTrrIYwPQ0MfX2Hs(Uk4RQqLpdv18ejDyf)vfnAQsJNskNKQIdPcvDnOuCpvi)gYXfjsJIsQU31EvQ5bv14ZkPbpYJFSLgWAGJDHQknWfNCmLmBejkfo3vTazy4qP8G5gNBpyOpJhmyd2IDCQQosK2wTkEUnIe8AVu31EvBfZpdHsxv1rI02QF2KeM)SBgoDK0mS0KgCLgRlnCyp)iblNzJaXdMtStZjn0tAWin2yJ0aPu2inAqGz9cN4tGzp5lI84NqAqAsrv8(XCCtx9NNaWxe5v1hri6MfrQkqcO6fk47qOMhuTk18GQ0LNaWxe5v1cKHHdLYdMBCUXu1cWrSehWR9UvTYl48FHWcEGy7V6fkqnpOA3s5P2RARy(ziu6QQosK2w9ZMKWW9o7ceiCgGeqWbotaDqin4knwxA(Sjjm)z3mC6iPzcOdcPXgBKgRlnb4ZMKWawdCSBejac)KgbCrEejy4748lnhjnEKgCLgRlnoekhqhem)z3mC6iPziWBIcU0KQ0Cln2yJ08ztsy(ZUz40rsZWstAsH0KcPjfvX7hZXnDvhkJ4Cw(j)nCVv9reIUzrKQcKaQEHc(oeQ5bvRsnpOQvOmIZz5sJ(gU3QwGmmCOuEWCJZnMQwaoIL4aET3TQvEbN)lewWdeB)vVqbQ5bv7wk6x7vTvm)mekDvvhjsBR6qOCaDqW8qKDYN8Le9dme4nrbxAs9iPXHq5a6GGb)m6p5thcLdOdcgc8MOGln4knF2KegU3zxGaHZaKacoWzcOdcPbxPjaF2KegWAGJDJibq4N0iGlYJibdFhNFP5iPXtv8(XCCtx9Wq(ey8dKQ(icr3SisvbsavVqbFhc18GQvPMhu94gYNaJFGu1cKHHdLYdMBCUXu1cWrSehWR9UvTYl48FHWcEGy7V6fkqnpOA3sH9AVQTI5NHqPRQ6irABvYGpWeGKOlUstQsd9XgPbxP5ZMKWKGCSCiCsg8bg(oo)stQsd9RI3pMJB6QjihlhcNKbFOQpIq0nlIuvGeq1luW3HqnpOAvQ5bvtzihlhcsJLbFOQfiddhkLhm34CJPQfGJyjoGx7DRALxW5)cHf8aX2F1luGAEq1ULcBQ9Q2kMFgcLUQQJePTvjWBIcU0KQ0GnsdUsJdHYb0bbZF2ndNosAgc8MOGlnPknEKgCLgRlnoekhqhem)8ea(Iipgc8MOGlnPknEKgBSrAoEPHd75hjy5mBeiEWCIDAoPHEsdgPjfvX7hZXnDvcicv9reIUzrKQcKaQEHc(oeQ5bvRsnpOQfqeQAbYWWHs5bZno3yQAb4iwId41E3Qw5fC(VqybpqS9x9cfOMhuTBPW2AVQTI5NHqPRQ6irABvhcLdOdcM)SBgoDK0me4nrbxAs9iPbFxqAWvAcWNnjHXHYioNLFYFd3ldbEtuWLg6jnyBv8(XCCtxLmyn4dKQ(icr3SisvbsavVqbFhc18GQvPMhu1YG1GpqQAbYWWHs5bZno3yQAb4iwId41E3Qw5fC(VqybpqS9x9cfOMhuTBPWP2RARy(ziu6QQosK2wnaF2KegWAGJDJibq4N0iGlYJibdFhNFP5iPXJ0GR08ztsy4ENDbceodqci4aNHLwv8(XCCtx9Hi7Kp5lj6hQ6JieDZIivfibu9cf8DiuZdQwLAEq1lezNS0Olj6hQAbYWWHs5bZno3yQAb4iwId41E3Qw5fC(VqybpqS9x9cfOMhuTBPow1EvBfZpdHsxv1rI02Q7KbXYKaeSqKtuY5F2ndmGy(ziin4knF2KeMdqeFVleo)5jam8DC(LMJKg6ln4knb4ZMKW4qzeNZYp5VH7LHLM0GR08ztsy(ZUz40rsZeqhevX7hZXnD1dEJK8HOiu1hri6MfrQkqcO6fk47qOMhuTk18GQhN3ijFikcvTazy4qP8G5gNBmvTaCelXb8AVBvR8co)xiSGhi2(REHcuZdQ2TuhJAVQTI5NHqPRQ6irABvYGpW4yjeqSstQsd2XufVFmh30vrybeAOdaPQpIq0nlIuvGeq1luW3HqnpOAvQ5bvpMybeAOdaPQfiddhkLhm34CJPQfGJyjoGx7DRALxW5)cHf8aX2F1luGAEq1UL6gtTx1wX8ZqO0vvDKiTT6NnjHH7D2fiq4majGGdCMa6GqASXgPHm4dmowcbeR0qVJKgSJrASXgPzNmiwMWWk2mW5mGy(ziin4knKbFGXXsiGyLg6DK0qFSTkE)yoUPRcwdCSlu1hri6MfrQkqcO6fk47qOMhuTk18GQ2AnWXUqvlqggoukpyUX5gtvlahXsCaV27w1kVGZ)fcl4bIT)QxOa18GQDl19DTx1wX8ZqO0vvDKiTT642iwWjiGxe4sd9KMBPbxP54LgoSNFKGLZSrG4bZj2P5Kg6jnyQI3pMJB6Q)8ea(IiVQw5fC(VqybpqS9x9cf8DiuZdQwLAEqv6Yta4lI8KgRFNIQ4rWNxnkwGqyPThDx1cKHHdLYdMBCUXu1cWrSehWR9Uv9reIUzrKQcKaQEHcuZdQ2TB1uoKmS5T01Tf]] )

    storeDefault( [[SimC Arms: AOE]], 'actionLists', 20180418.215623, [[d4Z8laGEeIQnHsyxkLTHsu7dHKBRWPj1SPy(uv4Ms0JP03ue3JQs7uj7vSBuTFK6NieLHPunoec5PqpJQIgmkgUe6qieQtHsQJrvohcbwOIQLIOwmsworpucwfcbTmjL1HqKMicrmvezYuz6axeH6VKOlR66sYRLuTvuQ2mj12jHVRO8vesnnssAEKK6Ws9zsIrJGXtsItIs55eUgkropvvJcLKFd6GkshVqk4QhpiQhfOzMkhcIuAMPezehelERUnAI8gOH8SM4fK8nVfpRA7Et8QT7ZTA7SelRQtcIwPUiiyWPwGgYfHuwEHuqI5nL5UmpiAL6IGGSIMXcHghCgFJY0Ulaq5yRQinJp8bnJfcno4m(gLPDxaGYXM8JwZf0mQ2xAgvSoAgwtZWcAgwrZyHqJdoJVr1aG5kTs)BvfPz8HpOzSqOXbNX3OAaWCLwP)n5hTMlOzuTV0mQyD0mSo4ukTrd8hCwlPKVRFzq24oTTbqzqoK)GLqh7TC1Jhm4Qhpir3sk576xgK8nVfpRA7Et82ds(cyL0ErifqWceUTEjuXhNdcvWsOB1JhmGSQfsbjM3uM7Y8GOvQlccsvPw9gvdaMR0k9VvvKMHf0meX0mG2Coyt2kAvUC78MYCxWPuAJg4piLPDxaGYrq24oTTbqzqoK)GLqh7TC1Jhm4Qhp4Ct7UaaLJGKV5T4zvB3BI3EqYxaRK2lcPacwGWT1lHk(4CqOcwcDRE8GbKLpdPGeZBkZDzEq0k1fbbbT5CWMSv0QC525nL5oAgwqZyHqJdoJVr1aG5kTs)BYpAnxqZOAFPzuX6OzybnJ7uvQvVzHgOqujukgTGWM8JwZf0mefndlhCkL2Ob(dkBfTkxgKnUtBBaugKd5pyj0XElx94bdU6XdsUv0QCzqY38w8SQT7nXBpi5lGvs7fHuablq426LqfFCoiublHUvpEWaYsvdPGeZBkZDzEq0k1fbbPQuREtZvQgkvciCL11gZMdoJtZWcAgqBohSP5kvdLkbeUY6AJz78MYCxWPuAJg4pOfAGcrLqPy0ccbzJ702gaLb5q(dwcDS3YvpEWGRE8GfGgOqujOzWrlieK8nVfpRA7Et82ds(cyL0ErifqWceUTEjuXhNdcvWsOB1JhmGSyPqkiX8MYCxMheTsDrqq3PQuREZcnqHOsOumAbHnhCgNMHf0mTfOvCLN)H(cAgv7lnJ3EWPuAJg4pOfAGcrLqPy0ccblq426LqfFCoiublHo2B5Qhpyq24oTTbqzqoK)GRE8GfGgOqujOzWrliqZWkpwhCQufrqRFR5kbTuLde(6fK8nVfpRA7Et82ds(cyL0ErifqWc(TMtQLQCGiZdwcDRE8GbKflhsbjM3uM7Y8GOvQlcc2wGwXvE(h6lOzikFPzyPGtP0gnWFqR5TIhKnUtBBaugKd5pyj0XElx94bdU6XdwW8wXds(M3INvTDVjE7bjFbSsAViKciybc3wVeQ4JZbHkyj0T6XdgqwtcPGeZBkZDzEq0k1fbbBlqR4kp)d9f0meLV0mSendlOzOQuREZAER4BvfdoLsB0a)bNrqlnZ0Cxq24oTTbqzqoK)GLqh7TC1Jhm4QhpirtqlnZ0CxqY38w8SQT7nXBpi5lGvs7fHuablq426LqfFCoiublHUvpEWaYIikKcsmVPm3L5brRuxeeSTaTIR88p0xqZqu(sZmj4ukTrd8hCgbT0mtZDbzJ702gaLb5q(dwcDS3YvpEWGRE8GenbT0mtZD0mSYJ1bjFZBXZQ2U3eV9GKVawjTxesbeSaHBRxcv8X5GqfSe6w94bdilIGqkiX8MYCxMheTsDrqqQk1Q3eeAa4Y7u6U6ZfxS5GZ4bNsPnAG)GwObkevcLIrlieKnUtBBaugKd5pyj0XElx94bdU6XdwaAGcrLGMbhTGandRQX6GKV5T4zvB3BI3EqYxaRK2lcPacwGWT1lHk(4CqOcwcDRE8GbKL3EifKyEtzUlZdIwPUiiivLA1BcaKFLeElbBvfdoLsB0a)bVQCBf4bzJ702gaLb5q(dwcDS3YvpEWGRE8GeRk3wbEqY38w8SQT7nXBpi5lGvs7fHuablq426LqfFCoiublHUvpEWaYYZlKcsmVPm3L5brRuxeeKQsT6nbHgaU8oLUR(CXfBvfPz8HpOzCNQsT6TRk3wb0q(LcLfL3QfAiFZbNXdoLsB0a)bhqjOnkfaPU(dYg3PTnakdYH8hSe6yVLRE8Gbx94blHsqBOzqGux)bjFZBXZQ2U3eV9GKVawjTxesbeSaHBRxcv8X5GqfSe6w94bdilVAHuqI5nL5UmpiAL6IGGYpAnxqZOAFPzCvYgOHCAgIqAM9nFsZWcAM2c0kUYZ)qFbnJQ9LMXNbNsPnAG)GYZDblq426LqfFCoiublHo2B5Qhpyq24oTTbqzqoK)GRE8GKp3fCQufrqRFR5kbTuLde(6fK8nVfpRA7Et82ds(cyL0ErifqWc(TMtQLQCGiZdwcDRE8GbKLNpdPGeZBkZDzEWPuAJg4pO18wXdYg3PTnakdYH8hSe6yVLRE8Gbx94blyER40mSYJ1bjFZBXZQ2U3eV9GKVawjTxesbeSaHBRxcv8X5GqfSe6w94bdilpvnKcsmVPm3L5bNsPnAG)GZiOLMzAUliBCN22aOmihYFWsOJ9wU6XdgC1JhKOjOLMzAUJMHv1yDqY38w8SQT7nXBpi5lGvs7fHuablq426LqfFCoiublHUvpEWaciirYv3vgqMhqc]] )

    storeDefault( [[SimC Arms: cleave]], 'actionLists', 20180418.215623, [[dSd2haGEuPuBIss7cvSnLKAFusvZwu3KsDAPCBf(MeANs1Ej7MI9ROUSQHPe)gQZtjwMezWkYWrLCqj4WchtsohIQyHsulvPSyewospuewfQu4Xu16quvnruPOPQunzQmDixer8ArYZqu56sQnIOQSvePnlI2oQQVRK4ROsLPHkvnpkP8zrQdHOknAuLXtjvojIYZr5Akj5Eus8uWFvsnouPKvL2f0JXfaTrI5Pc0bJ8pp5Zp4Fbax33ICJBhOg2OEXkbBp)GD1lTuvSQ0c54uAzvRM7lka80gxibck4rnSHPD1R0Uasmbr(ovwa4PnUqciQtMKdrGq5V2tTWPMR5jRoprENNqr(gehAWpsFkNBcI8Dckq0YnKfbe5WDgcthciZ4A(aHPcmyZfyJDKg0EmUab9yCbLZH7meMoeS98d2vV0svXQfbBNHRP(Z0UqcsW7(u2y(FCdsecSXUEmUaHuVK2fqIjiY3PYcapTXfsakY3G4qd(r6t5CtqKVBEYQZtEmo7WRy4qeiu(R9ulCOFendBEYAwzEkT3npz15j3jQtMKJhNXmwnBnBemECOFendBEY6NNwTGceTCdzran4hPpvazgxZhimvGbBUaBSJ0G2JXfiOhJlyl4hPpvW2Zpyx9slvfRweSDgUM6pt7cjibV7tzJ5)XniriWg76X4cesDYPDbKycI8DQSaWtBCHe4orDYKC84mMXQzRzJGXJJdVIrqbIwUHSiWJZygRMTMncgpbj4DFkBm)pUbjcb2yhPbThJlqazgxZhimvGbBUGEmUGe4mMXQzZtWiy8euGMMjWBXN)AuqtFeZkvc2E(b7QxAPQy1IGTZW1u)zAxibjS4ZFpOPpIPYcSXUEmUaHuN71Uasmbr(ovwa4PnUqciQtMKdJxGqNE3A3tEd7moo8kgbfiA5gYIGvckb9rQtfqMX18bctfyWMlWg7inO9yCbc6X4c4UGsqFK6ubBp)GD1lTuvSArW2z4AQ)mTlKGe8UpLnM)h3GeHaBSRhJlqi1xL2fqIjiY3PYcapTXfsansFoUNS5BO5jRnprUvnpz15jI6Kj5Ke7Rz3TMgPphgk8PMNS28e5euGOLBilcsI91S7wtJ0xazgxZhimvGbBUaBSJ0G2JXfiOhJlG8H91S7MN2I0xW2Zpyx9slvfRweSDgUM6pt7cjibV7tzJ5)XniriWg76X4ces9vRDbKycI8DQSaWtBCHeq)iAg28K1SY8KRMgOg2mpXnMNw4qobfiA5gYIa6nobj4DFkBm)pUbjcb2yhPbThJlqazgxZhimvGbBUGEmUGTBCckqtZe4T4ZFnkOPpIzLkbBp)GD1lTuvSArW2z4AQ)mTlKGew85Vh00hXuzb2yxpgxGqQxu7ciXee57uzbfiA5gYIGbMII8AgI2sDbKzCnFGWubgS5cSXosdApgxGGEmUaBmff55jarBPUGTNFWU6LwQkwTiy7mCn1FM2fsqcE3NYgZ)JBqIqGn21JXfiK6ClTlGetqKVtLfuGOLBilcU1DFn6ciZ4A(aHPcmyZfyJDKg0EmUab9yCbKyD3xJUGTNFWU6LwQkwTiy7mCn1FM2fsqcE3NYgZ)JBqIqGn21JXfiK6KhTlGetqKVtLfuGOLBilc85h8VaYmUMpqyQad2Cb2yhPbThJlqqpgxqI8d(xW2Zpyx9slvfRweSDgUM6pt7cjibV7tzJ5)XniriWg76X4ces9QfTlGetqKVtLfuGOLBilcwHxJMxPzCciZ4A(aHPcmyZfyJDKg0EmUab9yCbChVgnVsZ4eS98d2vV0svXQfbBNHRP(Z0UqcsW7(u2y(FCdsecSXUEmUaHesa38jJ6msLfsc]] )

    storeDefault( [[SimC Fury: three targets]], 'actionLists', 20171203.205647, [[dOZweaGEsj1Maf2LG2gPu2hrvmBHMVeYnLOBdyNszVu7gX(HYOaLmmj53eEoixwzWq1Wjkheu1PafDmbESQAHsWsvLwmqlhPhcHEkQLrkwhPenrIQ0uHutwQMUkxeICEi4zKs11jvBucvBLOYMjsBNiCAs(kPK8zi57quhw0FbvgTQy8sOCsIOPbk11iLW9iQQ(MKYHiQkVws1oWOn3sGzMvaiIHxCDkcAjg(9q3WWVKIAhKzw2(QmQ068ucIB10y(DXLqZnnvb1c0uP9WaTbByxPnZ8NQKDMnd))uccKr7wGrBgjscgx3fmZFQs2zguxQ0qOtqgCplPxOUmZWdQIQdbZRy7RFZSKKU6NNGAMiiZCPOlxsBjWmBULaZmsfBF9BMFxCj0CttvqTGkZVdsOt)dYO9zgXN9RxkKyaJCg0CPO3sGz2NBAmAZirsW46UGz(tvYoZG6sLgcS8G7hxkXOH6YWWHbgoSWWHfgoOUuPHJqtulSlqMGHddmC5dd)Y4ixOuQ4EueuWbok0O1hnCKemUogomXWlQimCyHHttul8RtPJCy4YJ8JHhuvHHddm8lJJCHsPI7rrqbh4OqJwF0WrsW46y4WedhMy4fvegoOUuPHajeu(PluxMz4bvr1HGzAcilrnZss6QFEcQzIGmZLIUCjTLaZS5wcmZVjGSe1m)U4sO5MMQGAbvMFhKqN(hKr7ZmIp7xVuiXag5mO5srVLaZSp30UrBgjscgx3fmZFQs2z(Y4ixOIqgfoAIAHJKGX1ndpOkQoemttukck4aJcKnljPR(5jOMjcYmxk6YL0wcmZMBjWm)MOueuy4fIcKn)U4sO5MMQGAbvMFhKqN(hKr7ZmIp7xVuiXag5mO5srVLaZSp3GTrBgjscgx3fmdpOkQoemdgfI(9OOqNzjjD1ppb1mrqM5srxUK2sGz2ClbM5crHOFpkk0z(DXLqZnnvb1cQm)oiHo9piJ2NzeF2VEPqIbmYzqZLIElbMzFUPfgTzKijyCDxWm8GQO6qWmYpkAezfPBwssx9ZtqnteKzUu0LlPTeyMn3sGzwREu0iYks387IlHMBAQcQfuz(DqcD6FqgTpZi(SF9sHedyKZGMlf9wcmZ(8zwEN0upEUGpBa]] )

    storeDefault( [[SimC Fury: single target]], 'actionLists', 20171203.205647, [[d4dQjaGAbsTEfcBIcAxO02acTpfspxOztvZxPQBQuUns(gq5Yq7eWEL2TQ2pHrbunmvQXjqKZlGttPbt0WPIoifYPashtqNtGkluHAPivlwjlhvpKIYtjTmQK1jqutuGetLImzfnDqxKc1JvXZui66OyJabBLIQnRGTtfmpbk9vbsAAar9DLkhw0FPsnAvY4fO4KuH(ms5AarUNavDibcVMc8Be3WAQkqsHvvlLzcjiWWdeKfYO9P5rHeMCAiSQ6ep20BhrcTKVaG5QkD0JzelGR7qWcDDps2qqeKb5BqSQE4wNWQvn6aTKpwtfiSMQA8Nlpo74Q6HBDcRUyggyhycAloZO7bgEawgNcPHc5IzyGDGjOT4mJUhy4by5ivA)OqgScPRQgTSElmq1LNqMWllpcR64pTNes4vFYJv3itZtoqsHvRcKuy1XEczcVS8iSkD0JzelGR7qWcVRshJeg(bJ1uHvn7cpgSrCaPWh2v1nYeiPWQfwax1uvJ)C5XzhxvpCRtyvy6XhYoWXFebyXpxECkKgkKGlKlMHb2bo(Jia7KS7fY97fYfZWa7ah)reGLJuP9JczWg8cPlHe0QgTSElmq1bgULWeDh9z8QQJ)0EsiHx9jpwDJmnp5ajfwTkqsHvbbgULWefs1NXRQ0rpMrSaUUdbl8UkDmsy4hmwtfw1Sl8yWgXbKcFyxv3itGKcRwybgznv14pxEC2Xv1d36ewDXmmWIppPHSmofsdfsy6XhYA)h5U5jnKf)C5XzvJwwVfgOkpPzFAUxEYUQo(t7jHeE1N8y1nY08KdKuy1QajfwLEsZ(0eYXEYUQ0rpMrSaUUdbl8UkDmsy4hmwtfw1Sl8yWgXbKcFyxv3itGKcRwyba5AQQXFU84SJRQhU1jSkm50qi7fME4fRZduihviDfkKgkKGlK8KgYEy4C8Hc5ObVqgEFlK73lKbHqctp(q2bobEzFAUxipICdqol(5YJtHeuH0qHeCHeCHeCH8qi(jz3ZUsi0JUp8aSCKkTFuihvibjHC)EH8qi(jz3ZU8eYCLWlwosL2pkKJkKGKqcQqAOqgecjm94dzpj)tAil(5YJtHeuHC)EHeCHeCH8qi(jz3ZUsi0JUp8aSCKkTFuihvihPqUFVqEie)KS7zxEczUs4flhPs7hfYrfYrkKGkKgkKW0JpK9K8pPHS4NlpofsqfsqfY97fYfZWalvgJ5HJSmoRA0Y6TWav5jLZKgw1XFApjKWR(KhRUrMMNCGKcRwfiPWQ0tkNjnSkD0JzelGR7qWcVRshJeg(bJ1uHvn7cpgSrCaPWh2v1nYeiPWQfwaqQMQA8Nlpo74Q6HBDcRUyggyJqYJUVWKdzzCkKgkKGlKGlKW0JpK1(pYDZtAil(5YJtH0qH8qi(jz3ZYtA2NM7LNSJLJuP9Jc5OczOqcQqUFVqUyggyXNN0qwgNcjOvnAz9wyGQyWGhgiw1XFApjKWR(KhRUrMMNCGKcRwfiPWQghm4HbIvPJEmJybCDhcw4Dv6yKWWpySMkSQzx4XGnIdif(WUQUrMajfwTWcaI1uvJ)C5Xzhx1OL1BHbQU8eYeEz5ryvh)P9KqcV6tES6gzAEYbskSAvGKcRo2tit4LLhHcj4HGwLo6XmIfW1DiyH3vPJrcd)GXAQWQMDHhd2ioGu4d7Q6gzcKuy1clay1uvJ)C5XzhxvpCRty1icDViptKfArEyW52LZJqoQqElKgkKbHqctp(qw7)i3npPHS4NlpoRA0Y6TWavhy4wct0D0NXRQo(t7jHeE1N8y1nY08KdKuy1Qajfwfey4wctuivFgVesWdbTkD0JzelGR7qWcVRshJeg(bJ1uHvn7cpgSrCaPWh2v1nYeiPWQfwGGunv14pxEC2Xv1d36ewDXmmWUJJhdSpn3R07zzCkKgkKlMHbw85jnKLXzvJwwVfgO6Ull3VZ(ZQo(t7jHeE1N8y1nY08KdKuy1QajfwnOEz5(D2FwLo6XmIfW1DiyH3vPJrcd)GXAQWQMDHhd2ioGu4d7Q6gzcKuy1clqWvtvn(ZLhNDCvJwwVfgOkpPzFAUxEYUQo(t7jHeE1N8y1nY08KdKuy1QajfwLEsZ(0eYXEYoHe8qqRsh9ygXc46oeSW7Q0XiHHFWynvyvZUWJbBehqk8HDvDJmbskSAHfi8UMQA8Nlpo74QgTSElmq1bgULWeDh9z8QQJ)0EsiHx9jpwDJmnp5ajfwTkqsHvbbgULWefs1NXlHeCxGwLo6XmIfW1DiyH3vPJrcd)GXAQWQMDHhd2ioGu4d7Q6gzcKuy1clSAqbhsgpSJlSf]] )

    storeDefault( [[SimC Fury: default]], 'actionLists', 20180311.093117, [[duepCaqiaQweLO2erXOafNcqDlqPq7cPggO6yGyzcQNbqzAsiDnIsSnqPY3OuACuIW5Kq06eeMNeQ7bkzFcIoiawisQhcitKse5Iuk2irPgjLiQtkintjeUjrSts8tqPKHckfTukPNs1uPuDvqPGTcq2l0FLObRYHfTyGESqtwHlJAZevFMinAb60KA1GsPEnLWSP42sA3i(TsdhKoorjTCcpxrtxQRtsBxc(osY4bLQopsSEkrA(cy)QAecAhDLSYO76kq)jBvbLq83GLNQMgDhkh1PrBPzRxcQyBy0TYgoNmQegoelbCadoSJoCyzbUSuu09OqdTrhDaITEjt0oQabTJUnKe0WdKA09OqdTrhDR8CvfrEI2XgDaa1gDtbDOQ1kBqpuYqhZEfOtwcJUv2W5KrfiORKvgDyt1ALnyJkHr7OBdjbn8aPgDaa1gDtb9yWuiLrpuYqhZEfOtwcJUKDaOuOKvgD0vYkJoqbtHugDRSHZjJkHHdXwiWr3kpxvrKNODSrhOGC0cjBbUYKgbrxYouYkJo2OcGH2r3gscA4bsn6EuOH2O3Pqk30d9StsK)lK)jlOdaO2OBkOhtJPmJTEjLg9SrpuYqhZEfOtwcJUKDaOuOKvgD0vYkJoqPX8haXwVK)kc9SrhaH0j6KSYWYYUUc0FYwvqje)v3cCLjTLr3kB4CYOsy4qSfcC0TYZvve5jAhB0bkihTqYwGRmPrq0LSdLSYO76kq)jBvbLq8xDlWvM0yJkffTJUnKe0WdKA09OqdTrhDaa1gDtb9GSy1XsdNqrpuYqhZEfOtwcJUKDaOuOKvgD0vYkJULmlwD8VIGtOOBLnCozujmCi2cbo6w55QkI8eTJn6afKJwizlWvM0ii6s2Hswz0XgvKf0o62qsqdpqQr3Jcn0gDqv5YPbZUnCzuqHwf6FY8hm)bQkxoDwi7uqRc9Vab(dW)RtdtA6Sq2PGMjjOHh)bm6aaQn6Mc6q3wVe0dLm0XSxb6KLWOlzhakfkzLrhDLSYOdBUTEjOdGq6eDswzyz51mkPkfwgDRSHZjJkHHdXwiWr3kpxvrKNODSrhOGC0cjBbUYKgbrxYouYkJ(AgLuLcSrfyhAhDBijOHhi1O7rHgAJom)XYQQgkuEqhxsbwiLjrUCLxkpBE(Nm)f31mwQi0Gz3gUmkOql4AQjZ)k(VW)b8Fbc8hG)hlRQAOq5bDCjfyHuMe5YvEP8S55FY8hm)b4)f31mwQi0Gz3gUmkOql4AQjZ)kgw)bb(Fbc8xCxZyPIqdMDB4YOGcTGRPMm)R4)c)hW)fiWFW8xNgM00GMDhGzhKMjjOHh)jZFW8xCxZyPIqdA2DaMDqAbxtnz(xX)b5Vab(duvUCAqZUdWSdsRc9pG)dy0bauB0nf0hIu6skfBkqpuYqhZEfOtwcJUKDaOuOKvgD0vYkJULKiLUK)SUPaDRSHZjJkHHdXwiWr3kpxvrKNODSrhOGC0cjBbUYKgbrxYouYkJo2OITOD0THKGgEGuJUhfAOn6XDnJLkcny2THlJck0cUMAY8VI)dYFY8xCxZyPIqdA2DaMDqAbxtnz(xX)b5pz(RtHuUPdYPPdsdn2)fY)cdhDaa1gDtbDrwHMsz0dLm0XSxb6KLWOlzhakfkzLrhDLSYOBnRqtPm6wzdNtgvcdhITqGJUvEUQIipr7yJoqb5Ofs2cCLjncIUKDOKvgDSrflbAhDBijOHhi1O7rHgAJENgM00YfmXsPqZKe0WJ)K5py(duvUCA5cMyPuONDgT4VI)dW(lqG)avLlNwUGjwkfAbxtnz(xX)by)fiWFW8xCxZyPIqdMDB4YOGcTGRPMm)R4)G8Nm)bQkxoTCbtSuk0cUMAY8VI)Ri)d4)agDaa1gDtbD5Qc9QolNMCge9qjdDm7vGozjm6s2bGsHswz0rxjRm6YwvOx15FUjNbr3kB4CYOsy4qSfcC0TYZvve5jAhB0bkihTqYwGRmPrq0LSdLSYOJnQuKOD0THKGgEGuJUhfAOn6SSQQHcLh0QvqrAkR7sKAsDbE(Nm)bZFXDnJLkcny2THlJck0cUMAY8Vq(N044pz(lURzSurObZUnCzuqHwW1utM)v8FH)lqG)I7AglveAWSBdxgfuOfCn1K5FW6p4)bm6aaQn6Mc6QvqrAkR7sKAsDbEIEOKHoM9kqNSegDj7aqPqjRm6ORKvgDydvqrA(tYUePMuxGNOdGq6eDswzyPwbfPPSUlrQj1f4j6wzdNtgvcdhITqGJUvEUQIipr7yJoqb5Ofs2cCLjncInQaboAhDBijOHhi1O7rHgAJolRQAOq5bTfPLAPPjH9LYvHT18iNLYvfu(tM)avLlNwUkSTMh5SuUQGc9yPIGoaGAJUPGoOz3rhulMn6Hsg6y2RaDYsy0LSdaLcLSYOJUswz0P2S7OdQfZgDRSHZjJkHHdXwiWr3kpxvrKNODSrhOGC0cjBbUYKgbrxYouYkJo2OceiOD0THKGgEGuJUhfAOn6W8hm)bQkxony2THlJck0cUMAY8Vq(NS8xGa)f31mwQi0Gz3gUmkOql4AQjZ)k(piH)d4)K5Vofs5MU1vUS3YHM)lK)zjG)hW)fiWFW8hm)1Pqk30TUYL9wo08Ff)xrH)hW)jZFW8hOQC50Gz3gUmkOql4AQjZ)c5FWU)ce4V4UMXsfHgm72WLrbfAbxtnz(xX)bj8Fbc8hm)1Pqk30TUYL9wo08Ff)xy4)b8Fa)hWOdaO2OBkONfYofOhkzOJzVc0jlHrxYoaukuYkJo6kzLrhGczNc0TYgoNmQegoeBHahDR8CvfrEI2XgDGcYrlKSf4ktAeeDj7qjRm6yJkqcJ2r3gscA4bsn6EuOH2Oh31mwQi0snlyAkJ7AglveAbxtnz(hS(d(FY8xNgM00coAHHNZYemjJLqZKe0WJ)K5pa)VonmPPbn7oaZointsqdp(tM)G5pwwv1qHYdA1kOinL1DjsnPUap)tM)G5pOcUq5kxEP04GwTckstzDxIutQlWZ)ce4py(RfAIfCth31mwQi0cUMAY8Vq(hG9Nm)1cnXcUPJ7AglveAbxtnz(xX)vKW)d4)a(Vab(dW)JLvvnuO8GwTckstzDxIutQlWZ)agDaa1gDtbDWSBdxgfuqpuYqhZEfOtwcJUKDaOuOKvgD0vYkJo1z3g(pGeuq3kB4CYOsy4qSfcC0TYZvve5jAhB0bkihTqYwGRmPrq0LSdLSYOJnQabWq7OBdjbn8aPgDpk0qB0J7AglveAPMfmnLXDnJLkcTGRPMm)dw)b)pz(RtdtAAqto4zVIkntsqdp(tM)G5Vm26cCjt4QMN)fY)G8hWOdaO2OBkOdMDB4YOGc6Hsg6y2RaDYsy0LSdaLcLSYOJUswz0Po72W)bKGYFWaby0TYgoNmQegoeBHahDR8CvfrEI2XgDGcYrlKSf4ktAeeDj7qjRm6yJkqkkAhDBijOHhi1O7rHgAJECxZyPIql1SGPPmURzSurOfCn1K5FW6p4)jZFGQYLtpeP0Luk2uqRc9pz(dM)I7AglveAqZUJoOwmBAbxtnz(hS(d(Fbc8hOQC50mrKszAbxtnz(xi)lURzSurObn7o6GAXSPfCn1K5FaJoaGAJUPGoy2THlJckOhkzOJzVc0jlHrxYoaukuYkJo6kzLrN6SBd)hqck)btyGr3kB4CYOsy4qSfcC0TYZvve5jAhB0bkihTqYwGRmPrq0LSdLSYOJnQarwq7OBdjbn8aPgDpk0qB0H5V4UMXsfHwQzbttzCxZyPIql4AQjZ)G1FW)lqG)I7AglveAPMfmnLXDnJLkcTGRPMm)Ryy9hC6I(Nm)bvWfkLgh0qOfzfAkL)d4)K5py(lURzSurObn7oaZoiTGRPMm)dw)b)Vab(duvUCAqZUdWSdsRc9Vab(dW)RtdtAAqZUdWSdsZKe0WJ)ce4py(RtHuUPBDLl7TCO5)k(piH)d4)a(pz(dM)yzvvdfkpOvRGI0uw3Li1K6c88pz(dM)Gk4cLRC5LsJdA1kOinL1DjsnPUap)lqG)G5VwOjwWnDCxZyPIql4AQjZ)c5Fa2FY8xl0el4MoURzSurOfCn1K5Ff)xrc)pG)d4)ce4pa)pwwv1qHYdA1kOinL1DjsnPUap)dy0bauB0nf0bZUnCzuqb9qjdDm7vGozjm6s2bGsHswz0rxjRm6uNDB4)asq5pyamGr3kB4CYOsy4qSfcC0TYZvve5jAhB0bkihTqYwGRmPrq0LSdLSYOJnQab2H2r3gscA4bsn6kzLr3QMi9Vv(FaTgtcvtK(NSvBvbpr3kpxvrKNODSrhaqTr3uqxOjslx5LX1ysOtnrAPC1wvWt0dLm0XSxb6KLWOBLnCozujmCi2cbo6EuOH2OdQkxony2THlJck0Qq)tM)avLlNMjIuktRc9pz(dW)duvUC6MRq7S1lHwfk2OceBr7OBdjbn8aPgDpk0qB0bvLlNgm72WLrbfAvO)fiWFW8xNcPCt36kx2B5qZ)v8Fqk6Fa)xGa)bZFXDnJLkcny2THlJck0cUMAY8VI)l8FY8hubxOuACqdHwKvOPu(pGrhaqTr3uqh0S7am7GOhkzOJzVc0jlHrxYoaukuYkJo6kzLrNAZUdWSdIUv2W5KrLWWHyle4OBLNRQiYt0o2OduqoAHKTaxzsJGOlzhkzLrhBubILaTJUnKe0WdKA09OqdTrhuvUCAWSBdxgfuOvHIoaGAJUPGoOz3rPCvbf0dLm0XSxb6KLWOlzhakfkzLrhDLSYOtTz3XFYwvqbDRSHZjJkHHdXwiWr3kpxvrKNODSrhOGC0cjBbUYKgbrxYouYkJo2OcKIeTJUnKe0WdKA09OqdTrhM)avLlNgm72WLrbfAvO)jZFW8hOQC50zHStbTk0)ce4pa)VonmPPZczNcAMKGgE8hW)b8Fbc8hm)bQkxony2THlJck0Qq)tM)6uiLB6wx5YElhA(VI)ROW)dy0bauB0nf0bzXKfwOjsrpuYqhZEfOtwcJUKDaOuOKvgD0vYkJo1SyYcl0ePOBLnCozujmCi2cbo6w55QkI8eTJn6afKJwizlWvM0ii6s2Hswz0XgvcdhTJUnKe0WdKA09OqdTrxKsz6OQqWK(VI)tKsz6Ac7)d24Fffo6aaQn6Mc6PiMeUSxHGjn6Hsg6y2RaDYsy0LSdaLcLSYOJUswz0bqetc)N9viysJUv2W5KrLWWHyle4OBLNRQiYt0o2OduqoAHKTaxzsJGOlzhkzLrhBujme0o62qsqdpqQr3Jcn0gDqv5YPbZUnCzuqHwfk6aaQn6Mc6X0ykZyRxsPrpB0dLm0XSxb6KLWOlzhakfkzLrhDLSYOBvL8haXwVK)kc9S)dgiaJoacPt0jzLHLLDDfO)KTQGsi(lURzSurMwgDRSHZjJkHHdXwiWr3kpxvrKNODSrhOGC0cjBbUYKgbrxYouYkJURRa9NSvfucXFXDnJLkYeBujCy0o62qsqdpqQr3Jcn0g9ofs5MoiNMoin0y)xi)lm8)K5py(lJTUaxYeUQ55FW6pa7Vab(lJTUaxYeUQ55FW6VI(hWOdaO2OBkOlujLzS1lP0ONn6Hsg6y2RaDYsy0LSdaLcLSYOJUswz0TQs(dGyRxYFfHE2)btyGrhaH0j6KSYWYYUUc0FYwvqje)1bfm)xNcPCpTm6wzdNtgvcdhITqGJUvEUQIipr7yJoqb5Ofs2cCLjncIUKDOKvgDxxb6pzRkOeI)6GcM)RtHuUNyJkHbm0o62qsqdpqQr3Jcn0g9m26cCjt4QMN)fY)kk6aaQn6Mc6cvszgB9skn6zJEOKHoM9kqNSegDj7aqPqjRm6ORKvgDRQK)ai26L8xrON9FWayaJoacPt0jzLHLLDDfO)KTQGsi(daylBSm6wzdNtgvcdhITqGJUvEUQIipr7yJoqb5Ofs2cCLjncIUKDOKvgDxxb6pzRkOeI)aa2YgSrLWffTJUnKe0WdKA09OqdTrVtHuUPdYPPdsdn2)v8FHHJoaGAJUPGUqLuMXwVKsJE2OhkzOJzVc0jlHrxYoaukuYkJo6kzLr3Qk5paITEj)ve6z)hmffy0bqiDIojRmSSSRRa9NSvfucXFmSNJQnBz0TYgoNmQegoeBHahDR8CvfrEI2XgDGcYrlKSf4ktAeeDj7qjRm6UUc0FYwvqje)XWEoQ2m2OsyzbTJUnKe0WdKA09OqdTrVtHuUPdYPPdsdn2)fY)cdhDaa1gDtbDHkPmJTEjLg9SrpuYqhZEfOtwcJUKDaOuOKvgD0vYkJUvvYFaeB9s(Ri0Z(pyKfGrhaH0j6KSYWYYUUc0FYwvqje)n1ePg(Vofs52YOBLnCozujmCi2cbo6w55QkI8eTJn6afKJwizlWvM0ii6s2Hswz0DDfO)KTQGsi(BQjsn8FDkKYn2yJULelpvnnsn2ic]] )

    storeDefault( [[SimC Fury: precombat]], 'actionLists', 20171203.205647, [[b4vmErLxt5uyTvMxtnvATnKFGzuDYLNo(bgCYv2yV1MyHrNxtnfCLnwAHXwA6fgDP9MBE50nY41usvgBLf2CL5LtYatm3eJmWmJlXydn0aJnEn1uJjxAWrNxt51ubngDP9MBZ5fvE5umErLxtvKBHjgBLrMxc51ubjwASLgD551uW9gDP9MBEnvsUrwAJfgDVjNxt52BUvMxt10BKzvyY5uyTvMxt51uofwBL51uq9gDP9MBEnvqYD2CEnLBH1wz9iYBSr2x3fMCI41usvgBLf2CL5LtYatm3edmEnLuLn3B1j3yLnNxu5fDEn1qOv2yR10B2vwBL5gDEjMxt10BK5uyTvMxt9gBK91DHjNx05fDEnfrLzwy1XgDEjKx05Lx]] )

    storeDefault( [[SimC Fury: cooldowns]], 'actionLists', 20171203.205647, [[dae4laqisH2eQQ(KsLKrjO6ukvSlsmmL4yKQLrsEgkuMgPGRHcvTnuQY3uQACkvkoNsLQwNsLsZdfs3dfI2hkvoikYcfKhIQYerHWfrPSruQQtII6MkLDQk)uPsQLQQ8uIPIsUQsLOTsk1xvQe2R0FfWGPYHfTyf9yinzfUmyZQQ(SsA0OkNMIxJcMnvDBi2nu)gPHtsTCepxOPRY1rLTtk57KIgpku58c06vQuz(ck7Nsx9YQYlrGkIbHpRJ95ib3TwhkL6hunXXkIAa1KEZUlpdf33Evv(apKrOpvl671vTWyk6SNg0Wc7vrqjg1xLkmHEgkoww9PxwvydNtpmAOkckXO(Qm5()vqYymrjGcNARJFRBY9)RaysUckeajn4O1XOwNEfMMgV5cwHKiQZvOcZ4HbnpkPcMIHkB0H2j5LiqLkVebQ8LiQZvOYh4Hmc9PArFV(sLpis5iOqSS6vHpEakdBuTaeaFDwzJoEjcuPxFQkRkSHZPhgnufbLyuFvUKScNcpi9hpf1ON1XOwNQfRJFRBY9)RaysUckeajn4O1XOwNEfMMgV5cwz6P0XXZqIxfMXddAEusfmfdv2OdTtYlrGkvEjcujKNshhpdjEv(apKrOpvl671xQ8brkhbfILvVk8XdqzyJQfGa4RZkB0XlrGk96JXkRkSHZPhgnufMMgV5cwbyCak3bvygpmO5rjvWumuzJo0ojVebQu5Liqf2yCak3bv(apKrOpvl671xQ8brkhbfILvVk8XdqzyJQfGa4RZkB0XlrGk96tdLvf2W50dJgQYlrGkmcsYTY7So6V1juoFScZ4HbnpkPcMIHkmnnEZfSYGKCR8Ua0)arkNpw5dIuockelREv(apKrOpvl671xQiOeJ6RYK7)xzM35HaOKGkeajn4O1XoRtL1XV1n5()vamjxbfcGKgC06yN1PY6436c36c36U0d4tzqYvkoaHMefaNtpmSo(TUj3)VYGKRuCacnjkeajn4O1XogP1Xyw3owxyHzDA06U0d4tzqYvkoaHMefaNtpmSUD61hJVSQWgoNEy0qvEjcuzxgbRJ5dqIvygpmO5rjvWumuHPPXBUGv4IqaZbiXkFqKYrqHyz1RYh4Hmc9PArFV(sfbLyuFv61h7vwvydNtpmAOkckXO(QCPhWNIbJbsasUckaoNEyyD8BDtU)FfatYvqHtDfMMgV5cwHKRg8AGPNQzfMXddAEusfmfdv2OdTtYlrGkvEjcu5lxn4vRlKNQzLpWdze6t1I(E9LkFqKYrqHyz1RcF8aug2OAbia(6SYgD8seOsV(2xwvydNtpmAOkckXO(QeU1rYvqbLJqa8zDSJrAD6llwh)w3LEaFk)e6XZGxdmbseimaefaNtpmSo(TonADr4cmPyUOYzaIk9aAqnQ1XoRBX62X6clmRlcxGjfZfvodquPhqdQrTo2zDlwxyHzDA06U0d4t5NqpEg8AGjqIaHbGOa4C6HrfMMgV5cwHKiQZvOcZ4HbnpkPcMIHkB0H2j5LiqLkVebQ8LiQZvW6cxFNkFGhYi0NQf996lv(GiLJGcXYQxf(4bOmSr1cqa81zLn64LiqLE9TBkRkSHZPhgnufbLyuFvMC))kaMKRGcNARJFRlCRdLs9dQMyfsUAWRbMEQMkeajn4O1XoRBX6clmRtJw3LEaFkgmgibi5kOa4C6HH1TtfMMgV5cwHocIJb(5ibRWmEyqZJsQGPyOYgDODsEjcuPYlrGk76rq8UkADSphjyLpWdze6t1I(E9LkFqKYrqHyz1RcF8aug2OAbia(6SYgD8seOsV(29Lvf2W50dJgQIGsmQVkx6b8Pq5UjhjEkaoNEyyD8BDtU)FfatYvqzq1eBD8BDtU)FLzENhcGscQWPUcttJ3CbRmbseimaKaKCfQWmEyqZJsQGPyOYgDODsEjcuPYlrGkHaseimaeR7lxHkFGhYi0NQf996lv(GiLJGcXYQxf(4bOmSr1cqa81zLn64LiqLE9PVuwvydNtpmAOkckXO(QeU1n5()vamjxbfcGKgC06yuRt364360O1DPhWNcL7MCK4Pa4C6HH1TJ1fwywNgTUl9a(umymqcqYvqbW50dJkmnnEZfSY0tPJJNHeVkmJhg08OKkykgQSrhANKxIavQ8seOsipLooEgs8SUW13PYh4Hmc9PArFV(sLpis5iOqSS6vHpEakdBuTaeaFDwzJoEjcuPxF66Lvf2W50dJgQIGsmQVktU)Ffnjakdg8AGz69kCQTo(TUj3)VcGj5kOWPUcttJ3CbROjpdXRPbpQWmEyqZJsQGPyOYgDODsEjcuPYlrGk7cEgIxtdEu5d8qgH(uTOVxFPYhePCeuiww9QWhpaLHnQwacGVoRSrhVebQ0RpDvLvf2W50dJgQcttJ3CbRqYvdEnW0t1ScZ4HbnpkPcMIHkB0H2j5LiqLkVebQ8LRg8Q1fYt106cxFNkFGhYi0NQf996lv(GiLJGcXYQxf(4bOmSr1cqa81zLn64LiqLE9PZyLvf2W50dJgQcttJ3CbRm9u644ziXRcZ4HbnpkPcMIHkB0H2j5LiqLkVebQeYtPJJNHepRlCv7u5d8qgH(uTOVxFPYhePCeuiww9QWhpaLHnQwacGVoRSrhVebQ0RpDnuwvydNtpmAOkmnnEZfSYphXq5IbI(mYRcZ4HbnpkPcMIHkB0H2j5LiqLkVebQW(CedLlADIpJ8Q8bEiJqFQw03RVu5dIuockelREv4JhGYWgvlabWxNv2OJxIav61RcJa(to)1q9Ab]] )

    storeDefault( [[SimC Fury: movement]], 'actionLists', 20171203.205647, [[b4vmErLxt5uyTvMxtnvATnKFGzuDYLNo(bwBVzxzTvMB051utbxzJLwySLMEHrxAV5MxoDJmEnLuLXwzHnxzE5KmWeZnXidmZ4sm2qdnWyJxtn1yYLgC051uEnvqJrxAV52CErLxofJxu51uf5wyIXwzK5LqEnvqILgBPrxEEnfALj3BPn2xSvwyW51uj5gzPnwy09MCEnLBV5wzEnvtVrMvHjNtH1wzEnLxt5uyTvMxtHuzY9wAJ5hymvwyW51usvgBLf2CL5LtYatm3edmEnLuLn3B1j3yLnNxu5fDEn1qOv2yR10B2vwBL5gDEjMxt10BK5uyTvMxt5fDErNxtruzMfwDSrNxc5fDE5f]] )

    storeDefault( [[SimC Fury: AOE]], 'actionLists', 20171203.205647, [[dWdffaGEjf1Muu1UKKTreSpsvmBjMpr0nfX3ue3wupwP2Pc7LA3e2VQ8tjfzyc1Vr5WsDEOObRsdNO6qKQItjPQJrkNJuv1cjvwku1Ivvlhvpuf1trwgrzDKQutKuvAQqLjly6qUiu40KCzW1fPnkPqBLizZqPTlKEUs(QKsnnIqFxiEMKs(SIYOvH5jPGtsKAusQCnsvY9ivv(RIkVwf5GksBnJZ0OZGjsLp)U1ykht9(DNwtyyIKdBvxu1CJumHhtKzcpuGEbEilwBIMS4AvPjbjkXyjyI2CLCKjtt3iftSmop0motyi6FbcwNjAZvYrM(PyXwbcEpdQcSiI3vsjFxEpdQ2PCoiqVBn8U6FSPPFvrHW00VWyb0HIVqMKweu7gX4MembykHfKQ5JodMmn6mysxHXcOdfFHmHhkqVapKfRnrl2eEyXs5ByzCgz68bSpLWIczqG83uclm6myYipKzCMWq0)ceSot0MRKJm9tXITce8EguXHCReR3vpVRS3D(3TU3T3ivuyoqazfSEx98UAVB9MM(vffctt)shGfIXZMKweu7gX4MembykHfKQ5JodMmn6mysxPdWcX4zt4Hc0lWdzXAt0InHhwSu(gwgNrMoFa7tjSOqgei)nLWcJodMmYJAzCMWq0)ceSot0MRKJm9tXITkdnAUDb6OaVkWIimn9RkkeMMICO4LikrWK0IGA3ig3KGjatjSGunF0zWKPrNbt1(qXlruIGj8qb6f4HSyTjAXMWdlwkFdlJZitNpG9PewuidcK)MsyHrNbtg5Henotyi6FbcwNjAZvYrM(PyXwLHgn3UaDuGxLk)DN)DR7D)PyXwbcEpdQcSiI3D(3vFExuxabQclNHouIzZ9b(c4NaEfi6FbcVRKs(U)uSyRY9A1BouLk)DLuY3L3ZGQDkNdc07Qh97D1IJF36nn9RkkeMM4DwEpdmjTiO2nIXnjycWuclivZhDgmzA0zWe(olVNbMWdfOxGhYI1MOfBcpSyP8nSmoJmD(a2NsyrHmiq(BkHfgDgmzKh6LXzcdr)lqW6mn9RkkeMM(fglGou8fYK0IGA3ig3KGjatjSGunF0zWKPrNbt6kmwaDO4l07wNw9MWdfOxGhYI1MOfBcpSyP8nSmoJmD(a2NsyrHmiq(BkHfgDgmzKhsW4mHHO)fiyDMM(vffcttrou8seLiysArqTBeJBsWeGPewqQMp6myY0OZGPAFO4Likr4DRtREt4Hc0lWdzXAt0InHhwSu(gwgNrMoFa7tjSOqgei)nLWcJodMmYit6lGTtliRZiBa]] )

    storeDefault( [[SimC Fury: execute]], 'actionLists', 20171203.205647, [[d8dVhaGAuG1RIOnrIQDPsTnve2hjs52k65KA2kz(cfUPqUm4BsfNhLANszVu7MW(rv)KernmPQXrIGtl4Xk1GrLHlsoOQItPI0XiPZrIsluOAPQWIvLLt0dvr9uOLrcRJejMijs1uvjtwHPJ4IsLEnkPNrIIRlQnQQKTIIAZIy7OettOuZtOOpls9DHs8xuOdlz0QQgVQsDsuKdjusxJeHUhjs6tKiYVrAuOG2Q(YyRMGrmmpZZ9vwYwPWZbFd7mbmIPGDOwHtwKav4whfgpGfuAWnf9QDuv0Rm3QNi2XU)egXTmKIy04NnjqfAF5MQVm2vuVfmCCJ4wgsrm(Yjj3jzgeGrPzmjlzFNtXZPCEUxoj5ojZGamknJjzj7BjmRGqZZftEofg)8cRaHTX3IshK)GutmYKye2fHknkOcWyeDWCjB1emASvtWy8fLoi)bPMy8awqPb3u0R2rT34bOPz5g0(YeJN)HnRruwGjii(zmIoA1emAIBk8LXUI6TGHJBe3YqkIXsscj1MCZGC60GuuzYniQ3cg8CkNNJH8CXkp3lNKCZGC60GuuzYDofpxmIbp3lNKCZGC60GuuzYTeMvqO55IjpNcEUt55Irm45E5KKBnHkag)HssUZPm(5fwbcBJW3WotaJmjgHDrOsJcQamgrhmxYwnbJgB1em29ByNjGXdybLgCtrVAh1EJhGMMLBq7ltmE(h2SgrzbMGG4NXi6OvtWOjUPm(Yyxr9wWWXnIBzifXiPwGGCNibXjzFdI6TGbpNY55E5KK7ejioj7BjmRGqZZftLkpNcJFEHvGW2yswgOznJ6vP)nYKye2fHknkOcWyeDWCjB1emASvtW4xzzGM18C4Q0)gpGfuAWnf9QDu7nEaAAwUbTVmX45FyZAeLfyccIFgJOJwnbJM4wS9LXUI6TGHJBe3YqkIXxoj5EwADTLWDofpNY55E5KKBqiR0WTeMvqO55IjpNQXpVWkqyBuwZuvAWitIryxeQ0OGkaJr0bZLSvtWOXwnbJh1mvLgmEalO0GBk6v7O2B8a00SCdAFzIXZ)WM1iklWeee)mgrhTAcgnXnLOVm2vuVfmCCJFEHvGW2i8nSZeWitIryxeQ0OGkaJr0bZLSvtWOXwnbJD)g2zcWZXq1tnEalO0GBk6v7O2B8a00SCdAFzIXZ)WM1iklWeee)mgrhTAcgnXTt4lJDf1Bbdh34NxyfiSnshSfAgtYs2gzsmc7IqLgfubymIoyUKTAcgn2QjyujpylusAEUVYs2gpGfuAWnf9QDu7nEaAAwUbTVmX45FyZAeLfyccIFgJOJwnbJM4whFzSROEly44g)8cRaHTX3IshK)GutmYKye2fHknkOcWyeDWCjB1emASvtWy8fLoi)bPMWZXq1tnEalO0GBk6v7O2B8a00SCdAFzIXZ)WM1iklWeee)mgrhTAcgnXnLGVm2vuVfmCCJ4wgsrmQbcJpQiRVjbqQQSmQi1MNtPXZ1B8ZlSce2gtYYanRzuVk9VrMeJWUiuPrbvagJOdMlzRMGrJTAcg)kld0SMNdxL(NNJHQNA8awqPb3u0R2rT34bOPz5g0(YeJN)HnRruwGjii(zmIoA1emAIBkRVm2vuVfmCCJFEHvGW2OSshePz8TOXIrMeJWUiuPrbvagJOdMlzRMGrJTAcgpQ0brAEU4lASy8awqPb3u0R2rT34bOPz5g0(YeJN)HnRruwGjii(zmIoA1emAIBQ9(Yyxr9wWWXn(5fwbcBJjzzGM1mQxL(3itIryxeQ0OGkaJr0bZLSvtWOXwnbJFLLbAwZZHRs)ZZXqfNA8awqPb3u0R2rT34bOPz5g0(YeJN)HnRruwGjii(zmIoA1emAIjgv6qsLxeh3eBa]] )


    storeDefault( [[Fury Primary]], 'displays', 20180208.182201, [[d4dliaGELQEjss7IiP2gsI6XOyMerFdjHzRKRrf6MeP8AaPBRIEoL2jf7vSBc7Nk5NQWWKQghrcxwXqjQbtvmCu5GsXNrQoMs54kvwOuzPeHftvTCsEivQNcTmQO1rKOjciMkctwLmDvDrvQRIKQNrKQRd0grITIKiBgvTDKYhPk5RuLIPHKY3LsJKkySuLsJgLgpG6KaClQs1Pj15r0HLSwIK8BqNTqeKP4EnuqbkE8jxtWdQtijaZDqMI71qbfO4r9(jMnNbvLG(4MDyaA6c6V07371c2g)GKh8825DxCVgkSX0he4dEE78UlUxdf2y6dUdCaNlamqbQ3pX4yFqllSTbuvae8W4hCh4aoxUlUxdf20feys3qbTr9Zv6csEWZBNNOu0N3gtFqllSfB1pdBZD6cAzHTnGpmDbplGrIy2c(LI(8ncgwOky3bbXH0KaGxoqeKmgV70PJbbogVlfodsEWZBNhiZQiJPpiWh8825bYSkYy6dAzHTeLI(820feO(ncgwOkiXHSea8YbIGxZQiPafpQ3pXS5miNsFwksamqHdJMo7hJJ9b1Ilnt9qvJGHfQckbaVCGi4Pw0a(Wy6dYuCVgkAemSqvWUdcIdPf8AwfjfO4dkt4YdwcRlpMsPGTbrUHrxl9(61qrmuHZGwwylsKUG7ahWbiA1W8AOiOea8YbIGcWtamqHngQfKtPplfjagOWB0xpBmo2huZafixXOf0JHAbTCZArzvww3WfufIGvmBb9Jzli9y2cQIzlFqllS1DX9AOWg)GaFWZBNVbuvX0hSavfbj3e0hKNpipu8bLjC5blH1LhtPuW2GxZQiPafp(KRj4b1jKeG5o4zbCd4dJPpO)sVFVxlyBZAf)G1IJTqwyRmT7y2cwlo2Yn80VEzA3XSfeidFbU(0fe4dEE78aexAM6HkBm9bRvBrALPjNUG00wTVEPFscsUjOFqMI71qrZstxe09TH4wIGxAl3Qiji5MGvWcuvae8qcsUjOpipFqvjOpeKCtWYxV0pzWcuvstlM0fCh4aoncgwOkOea8YbIGa1Ncu8OE)eZMZG7ahW5cadu4WOPZ(X4yFWAXXweLI(8Y0KJzlOAwbDFBiULiOLf2cKzvKbjU9wIGwUzTOSklB8dwlo2IOu0NxM2DmBb3boGZfaXLMPEOYMUGa1Ncu84tUMGhuNqsaM7GuDgUgl3W8suVgMUGM6Ccsbur6YJSsFwkYGFPOppfO4XNCnbpOoHKam3bVg(cC9nYsge1NUD5HcOIukD55A4lW1hCh4ao4tUMGsaWlhicsEWZBNNQD2y8(wWAXXwnR2I0kttoMTGaFWZBNNQD2y2cYP0NLIKcu8OE)eZMZGCQHbE6xFJSKbr9PBxEOaQiLsxE4udd80V(G1IJTCdp9RxMMCmBbplGBUJPpOLf2IT6NHTb8HPl4xk6Zlt7o(bTSWwzAYPlOeZAk7eJZ(nQyZzV0LAN9osLPgve0YcBP6q6RfxAbDB6cYap9RxM2D8d(LI(8Y0KJFWAXXwnR2I0kt7oMTGa1Ncu8bLjC5blH1LhtPuW2GwwylaXLMPEOYMUGKh8825Bavvm9bRvBrALPDNUGwwyBZD6cAzHTY0Utxqg4PF9Y0KJFWcuvncgwOky3bbXH0K8McrWAXXwilSvMMCmBb3bQzakvsBXNCnbRGNAbsetFWVu0NNcu8OE)eZMZG7ahWPrWWcvh8825JHAbzkUxdfuGIpOmHlpyjSU8ykLc2gSavfYnRfaGetFWBr5VMR0f0Qp5wtZXDmodkzzF3qbTrz1qrmo73KI(TnQj1spiWh8825jkf95TX0h8lf95PafFqzcxEWsyD5XukfSn4oWbCAwA6IZr8bzcYP0NLIeaduG69tmo2hK8GN3opaXLMPEOYgtFWtTO5ogPhuQGWt3qbTr9Zv6cQzGcPccpJr69b3boGZffO4r9(jMnNb3boGZfagOWB0xpBmo2hCh4aoxuTZMUGxZQiBemSqvqIdzjVPqeSavf1f6pi3Qihv(ea]] )

    storeDefault( [[Fury AOE]], 'displays', 20180208.182201, [[d4dkiaGELQEjQs2fQQyBijQdlzMOQCBvQzRKNHQQUjLcpgP(gLIonP2jf7vSBc7Ns1pvkdtQACsfXZPYqPKbtvmCu5GuvFgfoMuCCLkluLSuKulMOwojpKQ0tHwMuP1HQknraXuryYQOPRQlQcxfjPlR46aTrKyRijYMjY2rrFKsPVIQuMMur9DP0iLkmwPI0OrPXdOoja3cjHRHQ48i61asRfvP63GonHiiDX9AOGcu84tUMGBuLGpaMJGFPymVftRihuvcgJx2HgO5k4oWbC8xAgI7r8bPdsUjj5M3BX9AOWftFqG3KKCZ7T4Enu4IPpiNsFxksa0qbQ3pXWtFWBTW)ig(hCh4aoNElUxdfUCfeysVqbZr9ZzUcsUjj5MNOumM3ftFqhlSfB1pnR)rKd6yHT(GpmYbVlGrIyAcwGQcGqcsqYnbLbLKcsgdv0ytEckbfFqlc7EWs4S7XukfSni5MKKBEGmRImM(GaVjj5MhiZQiJPpOJf2sukgZ7YvqGk7lOzHQGeBwudW2oicEoRIKcu8OE)ett3GCk9DPibqdfDmAgSFm80hulo101dv(cAwOki1aSTdIGNJubUEFl(cI6BV29qburYV29Cosf46dsxCVgk8f0SqvWRncInBe8CwfjfO4dAry3dwcNDpMsPGTbrUHwxl9(61qrm2SBqhlSfjYvWDGd4aeTAOFnueKAa22brqb4naAOWftNdYP03LIeanuWB6ZNngE6d6yHTyR(Pz9bFyUc64M1IYQCSEHlOkebRyAcQIPjiJyAckhtt(GowyR3I71qHlYbbEtsYnVpOQIPpi5MKKBEFqvftFWDGd4CcGgk4n95Zgdp9bpNvrsbkE8jxtWnQsWhaZrW7cyFWhgtFq5LE)EBxWw)1kYbRfhBHSWwlMhX0eSwCSLx4TC9wmpIPjiqgPcC95kiWXqfDs3G1QTiDwmTYvqMANwwV0pjbj3euoiDX9AOWFPzic69WqCqDWtTJBvKeKCtq6GNZQi9f0SqvqInl(oOqeuvcgdbj3eSK1l9tgSavLn0Ijxb3boGJVGMfQcsnaB7GiiqLPafpQ3pX00n4oWbCobqdfDmAgSFm80hSwCSfrPymVftRyAcQMvqVhgIdQd6yHTazwfzqIJoLiOJBwlkRYXg5G1IJTikfJ5TyEettWDGd4CcqCQPRhQC5kiqLPafp(KRj4gvj4dG5iiVMHZ3Xn0p11RH5kOPUNGuavK294VDe8lfJ5Pafp(KRj4gvj4dG5iiWBssU551LlMMG7ahWbFY1eKAa22brqnnuGCfTwWigEcwlo2YF1wKolMwX0eCh4aoNaOHcuVFIHN(GCk9DPiPafpQ3pX00niNAOH3Y17BXxquF71UhkGks(1Uho1qdVLRpybQkKBwlaajM(G3fW(hX0h0XcBTyALRGFPymVfZJihK6znLBIPBFJnB62ZF(PBppu5oBZGowylVgszT4uly4Yvq5LE)EBxW2ihe4njj38aeNA66Hkxm9bj3KKCZdqCQPRhQCX0h8lfJ5PafFqlc7EWs4S7XukfSniWBssU5jkfJ5DX0h0XcBbio101dvUCf0XcB9bvfaHemYbRvBr6SyEKRGowyRfZJCf0XcB9pICqA4TC9wmTICWcuv(cAwOk41gbXMn47GcrqnnuW7q4Dm8Vp4oqnnqPsAh(KRjOCWBTajIPp4xkgZtbkEuVFIPPBWDGd44lOzHQnjj38XWtq6I71qbfO4dAry3dwcNDpMsPGTbRfhB5fElxVftRyAcEik51CMRGo9n3A83oIPBq(k37fkyokNgkIPBFtN0300z(H)bj3KKCZZRlxmurtq6I71qbfO4r9(jMMUbV1cFWhgtFqGktbk(Gwe29GLWz3JPukyBWVumM3xqZcvbV2ii2Sb1aSTdIG1IJT8xTfPZI5rmnb5Di82luWCu)CMRG1IJTqwyRftRyAcUdCaNtkqXJ69tmnDdsdVLR3I5rKdUdCaNtED5YvWcuveKCtqzqjPGfOQOQq)b5wf5OYNa]] )

    storeDefault( [[Arms Primary]], 'displays', 20180208.182201, [[d4dliaGEvOxIizxePyBic5XizMOuDBP0Sv01isUPcHxds8nfsEof7Ks7vSBc7NQ4NQOHPGXPqKlR0qjQbtvA4OYbPsFgLCmP44QGfkvwkkLftvTCsEiv0tHwMc16isPjcsAQGAYQutxvxuLCvePEgIORJWgjITIiuBgvTDe1hPc(krQAAkK67svJKk0yviQrJuJhK6KG4wiconPopkoSK1sKk)g40e4Guf3RbcjaXJpZCdEsAy2HyVcsvCVgiKaepQpUX2moOQeSwN0lfusxq)P(4rhMG(4hK5KN3SVZI71aHj2HGqFYZB23zX9AGWe7qWdelXEdHciq9XnwPgcAOb9UeQcIGhe)GhiwI92zX9AGWKUGqZ4eiiVQFVtxqMtEEZ(WLI1(MyhcAOb9yV(PODVsxqdnO3L4bPlyBbnchBtWVuS23vqrdub7oHHphbBqCWr4GmXscJj5qqOJLegPXbzo55n7d1DwmXoee6tEEZ(qDNftSdbn0GE4sXAFt6ccfFxbfnqfe(uMnio4iCW7DwmsaIh1h3yBghKtPBlfdekGWXvZI(JvQHGAXTMQEGYvqrdubzdIdochSvlCjEqSdbPkUxdeUckAGky3jm85icEVZIrcq8bLH94flHXJxBPuG(Gi3sPRP(y9AGi2r1e0qd6r40f8aXsSqvRwQxdebzdIdochuq0cHcimXo6GCkDBPyGqbesV((PJvQHGAkGa5kkTGvSsf0WTZPKzzODcMavGdwX2e0p2MGSITjOk2M8bn0GENf3Rbct8dc9jpVzFxcvf7qWIqvWmCBqFcE(G8aXhug2JxSegpETLsb6dEVZIrcq84Zm3GNKgMDi2RGTf0Uepi2HG(t9XJomb9UZz8dwto6cPb9YKVITjyn5OlNGw)6LjFfBtqOU8fX8txqOp55n7drCRPQhOmXoeSM9fJrMSC6cswB0(6P(zGz42G(bPkUxdeUtnlrqNxw4l2cERnCZIbMHBdwblcvbrWdGz42G(e88bvLG1cZWTblF9u)mblcvncTytxWdelX6kOObQGSbXbhHdcfFjaXJ6JBSnJdEGyj2BiuaHJRMf9hRudbRjhDbxkw7ltwo2MGQDg05Lf(ITGgAqpu3zXee(AKHdA425uYSm0Xpyn5Ol4sXAFzYxX2e8aXsS3qe3AQ6bkt6ccfFjaXJpZCdEsAy2HyVcsQD5CnCl1Zw9Aq6cAR2nORQ14XRSs3wkMGFPyTVeG4XNzUbpjnm7qSxbVx(Iy(UYShe1To941v1AKwpEVx(Iy(bpqSel(mZniBqCWr4GmN88M9jvNjwsOjyn5Ol3zFXyKjlhBtqOp55n7tQotSnb5u62sXibiEuFCJTzCqo1sbA9R3vM9GOU1PhVUQwJ06XlNAPaT(1hSMC0LtqRF9YKLJTjyBbT7vSdbn0GESx)u0UepiDb)sXAFzYxXpOHg0ltwoDbzBNBz2yhp0mQMXdKuAgpifjA0JkOHg0tQLXxlU1cwM0fKc06xVm5R4h8lfR9Ljlh)G1KJUCN9fJrM8vSnbHIVeG4dkd7XlwcJhV2sPa9bn0GEiIBnv9aLjDbzo55n77sOQyhcwZ(IXit(kDbn0GE3R0f0qd6LjFLUGuGw)6Ljlh)GfHQCfu0avWUty4ZrW(Le4G1KJUqAqVmz5yBcEGqtbfsS2GpZCdwbB1ceo2HGFPyTVeG4r9Xn2MXbpqSeRRGIgOo55n7hRubPkUxdesaIpOmShVyjmE8AlLc0hSiufYTZjeOg7qWlr5p370f0OB5MR75vSJdYEzENab5vz0arSJhAgPHMMrlnKmi0N88M9HlfR9nXoe8lfR9LaeFqzypEXsy841wkfOp4bILyDNAwI2v8bPcYP0TLIbcfqG6JBSsneK5KN3SpeXTMQEGYe7qWwTW9kwsgu6aGwNab5v97D6cQPacPdaAJLKdbpqSe7TeG4r9Xn2MXbpqSe7nekGq613pDSsne8aXsS3KQZKUG37SyCfu0avq4tz2VKahSiufPf6pi3Sywv(e]] )

    storeDefault( [[Arms AOE]], 'displays', 20180208.182201, [[d4dkiaGEjPxIIYUqrLTjjspgrZKizCePy2k6AOi3KivVwfLBRqpNu7Kk7vSBc7NQYpLudtb)g4YknuIAWuvnCu5GuQpJchtchxfzHQulfjAXuYYj5HuLEk0YajRJiLMOkQMkOMSkz6Q6IQWvrc9mQcUocBKi2ksq2mQA7iPpkj8vuu10qc8DjAKufnwKGA0i14bPojiULKOonfNhLoSuRvseFJQqNIahKS5EdqibiE8zNBWAkclfe3rqYM7naHeG4rt1nUcOcQAbJ1l9sEwUdAnnvRwXeugRGS1886992CVbi0Xnee6AEE9(EBU3ae64gcEIyj2liKabAQUXX0qqnnO0Mq1qe8Gyf8eXsSxEBU3ae6CheAwVab1v97vUdYwZZR3hUvm2xh3qqnnOelnpjT9rScQPbL2epiwbhBOr44kc(TIX(2csAGk4DnmCT0PesfEchKnUkx4rMccDCvwAGkiBnpVE)Z3zZg3qqOR5517F(oB24gcQPbLWTIX(6Ch8mlBbjnqfeUwMsiv4jCWRD2SsaIhnv34kGkiNYm2kwiKaHNRHb9hhtdbnIldz)aLTGKgOcsjKk8eo4Oryt8G4gcs2CVbiSfK0avW7Ay4APh8ANnReG4dkd7Zp2cTp)UwPaLbrUL00tt1(narCESiOMguIW5o4jILyp3OwY3aebPesfEchuqmcHei0Xrbb5uMXwXcHeiyEZ1thhtdbnKabY1KgbJ4ykOMBNtjZwt7fmbQahSJRiOvCfbzexrqvCf5dQPbLEBU3ae6yfe6AEE9(2eQoUHGnHQHz52Gwe88b5bIpOmSp)yl0(87ALcug8ANnReG4XNDUbRPiSuqChbhBOTjEqCdbTMMQvRyckTNZyfSNC0nsdkLPEexrWEYr3EbJw9lt9iUIGNV8nX8ZDqOR5517drCzi7hO0XneSNLnRwMQCUds1OnwMP5zHz52GwbjBU3ae2tddrqVho4dkdEz0CZMfMLBdsgSjunebpaMLBdArWZhu1cglml3gSTmtZZgSjuT0nIn3bprSeRTGKgOcsjKk8eo4zwsaIhnv34kGk4jILyVGqceEUgg0FCmneSNC0nCRySVmv54kcQ2zqVho4dkdQPbLNVZMni8bfgoOMBNtjZwthRG9KJUHBfJ9LPEexrWtelXEbrCzi7hO05o4zwsaIhF25gSMIWsbXDeKz7YzR5wYNY(nGCh01JBqB1O2NF76JGFRySVeG4XNDUbRPiSuqChbVw(My(2YsfenJE953wnQLwF(Vw(My(bprSel(SZniLqQWt4GS18869z2ToUkxeSNC0T9SSz1YuLJRii018869z2ToUIGCkZyRyLaepAQUXvavqo1scgT63wwQGOz0Rp)2QrT06ZpNAjbJw9hSNC0TxWOv)YuLJRi4ydT9rCdb10GsS08K02epi3b)wXyFzQhXkOMguktvo3bPCNBR34GAOWJfqn4bMdQbMQukWJb10GsMTSwgXLrWqN7GKGrR(LPEeRGFRySVmv5yfSNC0T9SSz1YupIRi4zwsaIpOmSp)yl0(87ALcugutdkHiUmK9du6ChKTMNxVVnHQJBiyplBwTm1JChutdkTpIvqnnOuM6rUdscgT6xMQCSc2eQ2wqsdubVRHHRLUuhsGd2to6gPbLYuLJRi4jcd5zuiJgF25g0k4OrGWXne8BfJ9LaepAQUXvavWtelXAliPbQAEE9(XXuqYM7naHeG4dkd7Zp2cTp)UwPaLbBcvJC7Cc584gcEiAR5EL7GAZi3CTRpIdQGs163lqqDvAdqehudfsZqrbfWCEii018869HBfJ91Xne8BfJ9LaeFqzyF(XwO9531kfOm4jILyTNggIXv8bjdYPmJTIfcjqGMQBCmneKTMNxVpeXLHSFGsh3qWrJW(iopeSsaGrVab1v97vUdAibIkbagJZddbprSe7LeG4rt1nUcOcEIyj2liKabZBUE64yAi4jILyVy2To3bV2zZAliPbQGW1YsDiboytOAkkmFqUzZUQ8ja]] )


end
