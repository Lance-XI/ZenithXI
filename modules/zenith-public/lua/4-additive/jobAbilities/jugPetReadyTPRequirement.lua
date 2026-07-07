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

-----------------------------------
-- The query returns 120 moves. The 26 below are omitted because they have no base script
-- in scripts/actions/abilities/pets/. Without a script neither onAbilityCheck nor
-- onPetAbility resolves, so they are already no-ops that burn a charge and do nothing.
-- there is nothing to gate. Add them here if upstream ever implements them:
--
--     acid_spray, digest, disembowel, extirpating_salvo, fluid_spread, fluid_toss,
--     foul_waters, gloom_spray, infected_leech, mega_scissors, molting_plumage,
--     nectarous_deluge, nepenthic_plunge, pecking_flurry, pentapeck, pestilent_plume,
--     sensilla_blades, sickle_slash, spider_web, stink_bomb, sweeping_gouge,
--     swooping_frenzy, tegmina_buffet, tickling_tendrils, venom_shower, zealous_snort
-----------------------------------
local readyMoves =
{
    'foot_kick', 'dust_cloud', 'whirl_claws', 'head_butt', 'dream_flower', 'wild_oats', 'leaf_dagger',
    'scream', 'roar', 'razor_fang', 'claw_cyclone', 'tail_blow', 'fireball', 'blockhead',
    'brain_crush', 'infrasonics', 'secretion', 'lamb_chop', 'rage', 'sheep_charge', 'sheep_song',
    'bubble_shower', 'bubble_curtain', 'big_scissors', 'scissor_guard', 'metallic_body', 'needleshot',
    'random_needles', 'frogkick', 'spore', 'queasyshroom', 'numbshroom', 'shakeshroom', 'silence_gas',
    'dark_spore', 'power_attack', 'hi-freq_field', 'rhino_attack', 'rhino_guard', 'spoil',
    'cursed_sphere', 'venom', 'sandblast', 'sandpit', 'venom_spray', 'mandibular_bite', 'soporific',
    'gloeosuccus', 'palsy_pollen', 'geist_wall', 'numbing_noise', 'nimble_snap', 'cyclotail',
    'toxic_spit', 'double_claw', 'grapple', 'spinning_top', 'filamented_hold', 'chaotic_eye',
    'blaster', 'suction', 'drainkiss', 'snow_cloud', 'wild_carrot', 'sudden_lunge', 'spiral_spin',
    'noisome_powder', 'acid_mist', 'tp_drainkiss', 'scythe_tail', 'ripper_fang', 'chomp_rush',
    'charged_whisker', 'purulent_ooze', 'corrosive_ooze', 'back_heel', 'jettatura', 'choke_breath',
    'fantod', 'tortoise_stomp', 'harden_shell', 'aqua_breath', 'wing_slap', 'beak_lunge', 'intimidate',
    'recoil_dive', 'water_wall', 'somersault', 'frenzied_rage', 'rhinowrecker', 'crossthrash',
    'predatory_glare', 'hoof_volley', 'nihility_song',
}

for _, moveName in ipairs(readyMoves) do
    m:addOverride(fmt('xi.actions.abilities.pets.{}.onAbilityCheck', moveName), function(player, target, ability)
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
