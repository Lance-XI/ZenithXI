-----------------------------------
-- Jug Pet Ready TP Requirement
-- Restores the pre-2014 rule that a Beastmaster jug pet must be at 1000 TP (100%)
-- before it can perform a Ready move.
--
-- Sic already waits for 1000 TP in xi.job_utils.beastmaster.useSic, but the individual
-- Ready moves never checked pet TP, so a jug pet could fire TP moves at 0 TP until its
-- charges ran out. onAbilityCheck runs in CAbilityState::CanUseAbility before
-- CCharEntity::OnAbility, so a blocked attempt costs no Ready charge.
--
-- Scoped by player:hasJugPet(), so SMN avatars, DRG wyverns and PUP automatons are unaffected.
-- Custom modifications for ZenithXI
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('a-j_jug_ready_tp')

local petAbilityDir = './scripts/actions/abilities/pets/'

-- luautils::OnAbilityCheck resolves scripts/actions/abilities/pets/<abilityName>.lua per ability,
-- so there is no single chokepoint to hook -- every Ready move is overridden individually.
--
-- A move with no base script (not implemented upstream yet) has no onAbilityCheck to hook. It still
-- passes CanUseAbility and the pet still performs it, with no effect but a Ready charge spent, so
-- it needs the gate too. Its (empty) table is created below so the override has something to
-- attach to.
--
-- That is done ONLY when the script file is absent at startup. Ability scripts load after
-- modules, and LoadLuaObjectFromFile installs with sol::update_if_empty, so a table created for a
-- move whose script exists would silently discard the real script. The file is checked on every
-- start, so a move switches to the normal deferred override by itself once upstream implements
-- it. Nothing to maintain here.
local function petAbilityScriptExists(abilityName)
    local file = io.open(petAbilityDir .. abilityName .. '.lua', 'r')

    return file ~= nil and io.close(file)
end

-----------------------------------
-- Every Ready move, in ability id order:
--     SELECT name FROM abilities WHERE recastId = 102 AND abilityId >= 672 ORDER BY abilityId;
--
-- Sic (72) and Ready (251) share recast id 102 but are not pet abilities
-- (CAbility::isPetAbility requires id >= 512), so they are not listed here.
-----------------------------------
local readyMoves =
{
    'foot_kick', 'dust_cloud', 'whirl_claws', 'head_butt', 'dream_flower', 'wild_oats', 'leaf_dagger',
    'scream', 'roar', 'razor_fang', 'claw_cyclone', 'tail_blow', 'fireball', 'blockhead', 'brain_crush',
    'infrasonics', 'secretion', 'lamb_chop', 'rage', 'sheep_charge', 'sheep_song', 'bubble_shower',
    'bubble_curtain', 'big_scissors', 'scissor_guard', 'metallic_body', 'needleshot', 'random_needles',
    'frogkick', 'spore', 'queasyshroom', 'numbshroom', 'shakeshroom', 'silence_gas', 'dark_spore',
    'power_attack', 'hi-freq_field', 'rhino_attack', 'rhino_guard', 'spoil', 'cursed_sphere', 'venom',
    'sandblast', 'sandpit', 'venom_spray', 'mandibular_bite', 'soporific', 'gloeosuccus', 'palsy_pollen',
    'geist_wall', 'numbing_noise', 'nimble_snap', 'cyclotail', 'toxic_spit', 'double_claw', 'grapple',
    'spinning_top', 'filamented_hold', 'chaotic_eye', 'blaster', 'suction', 'drainkiss', 'snow_cloud',
    'wild_carrot', 'sudden_lunge', 'spiral_spin', 'noisome_powder', 'acid_mist', 'tp_drainkiss',
    'scythe_tail', 'ripper_fang', 'chomp_rush', 'charged_whisker', 'purulent_ooze', 'corrosive_ooze',
    'back_heel', 'jettatura', 'choke_breath', 'fantod', 'tortoise_stomp', 'harden_shell', 'aqua_breath',
    'wing_slap', 'beak_lunge', 'intimidate', 'recoil_dive', 'water_wall', 'sensilla_blades',
    'tegmina_buffet', 'molting_plumage', 'swooping_frenzy', 'sweeping_gouge', 'zealous_snort',
    'pentapeck', 'tickling_tendrils', 'stink_bomb', 'nectarous_deluge', 'nepenthic_plunge', 'somersault',
    'foul_waters', 'pestilent_plume', 'pecking_flurry', 'sickle_slash', 'acid_spray', 'spider_web',
    'infected_leech', 'gloom_spray', 'disembowel', 'extirpating_salvo', 'venom_shower', 'mega_scissors',
    'frenzied_rage', 'rhinowrecker', 'fluid_toss', 'fluid_spread', 'digest', 'crossthrash',
    'predatory_glare', 'hoof_volley', 'nihility_song',
}

for _, moveName in ipairs(readyMoves) do
    local abilityPath = fmt('xi.actions.abilities.pets.{}', moveName)

    if not petAbilityScriptExists(moveName) then
        xi.module.ensureTable(abilityPath)
    end

    m:addOverride(fmt('{}.onAbilityCheck', abilityPath), function(player, target, ability)
        if player:hasJugPet() then
            local pet = player:getPet()

            if pet and pet:getTP() < 1000 then
                return xi.msg.basic.PET_NOT_ENOUGH_TP
            end
        end

        return super(player, target, ability)
    end)
end

return m
