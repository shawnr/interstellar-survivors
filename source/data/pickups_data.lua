-- Pickups Data
-- Random sci-fi themed pickup collectibles that float through the playfield
-- Each gives HP and/or RP on collection

PickupsData = {
    -- Space Vessels & Probes
    { id = "stray_shipping_cube", name = "Stray Shipping Cube", visual = "box", hpMin = 5, hpMax = 15, rpMin = 10, rpMax = 25 },
    { id = "voyager_probe", name = "Voyager Probe", visual = "pod", hpMin = 0, hpMax = 0, rpMin = 20, rpMax = 40 },
    { id = "event_horizon_drive", name = "Event Horizon Drive", visual = "diamond", hpMin = 10, hpMax = 20, rpMin = 5, rpMax = 15 },
    { id = "nostromo_flight_recorder", name = "Nostromo Flight Recorder", visual = "box", hpMin = 5, hpMax = 10, rpMin = 15, rpMax = 30 },
    { id = "discovery_pod", name = "Discovery Pod", visual = "pod", hpMin = 10, hpMax = 15, rpMin = 10, rpMax = 20 },
    { id = "eagle_transporter_crate", name = "Eagle Transporter Crate", visual = "box", hpMin = 5, hpMax = 15, rpMin = 10, rpMax = 25 },
    { id = "gunstar_fragment", name = "Gunstar Fragment", visual = "crystal", hpMin = 0, hpMax = 0, rpMin = 25, rpMax = 50 },
    { id = "valley_forge_biodome", name = "Valley Forge Biodome", visual = "circle", hpMin = 15, hpMax = 25, rpMin = 0, rpMax = 0 },
    { id = "planet_express_crate", name = "Planet Express Crate", visual = "box", hpMin = 5, hpMax = 10, rpMin = 15, rpMax = 30 },
    { id = "serenity_catalyzer", name = "Serenity Catalyzer", visual = "canister", hpMin = 5, hpMax = 15, rpMin = 10, rpMax = 20 },

    -- Devices & Technology
    { id = "babel_fish_tank", name = "Babel Fish Tank", visual = "canister", hpMin = 10, hpMax = 20, rpMin = 5, rpMax = 15 },
    { id = "holocron", name = "Holocron", visual = "diamond", hpMin = 0, hpMax = 0, rpMin = 25, rpMax = 45 },
    { id = "carbonite_block", name = "Carbonite Block", visual = "box", hpMin = 10, hpMax = 20, rpMin = 5, rpMax = 10 },
    { id = "ansible_relay", name = "Ansible Relay", visual = "diamond", hpMin = 0, hpMax = 0, rpMin = 20, rpMax = 40 },
    { id = "heighliner_fuel_cell", name = "Heighliner Fuel Cell", visual = "canister", hpMin = 5, hpMax = 10, rpMin = 15, rpMax = 30 },
    { id = "stillsuit_reservoir", name = "Stillsuit Reservoir", visual = "canister", hpMin = 15, hpMax = 25, rpMin = 0, rpMax = 0 },
    { id = "holtzman_shield_unit", name = "Holtzman Shield Unit", visual = "diamond", hpMin = 10, hpMax = 20, rpMin = 5, rpMax = 15 },
    { id = "sonic_screwdriver", name = "Sonic Screwdriver", visual = "canister", hpMin = 5, hpMax = 10, rpMin = 15, rpMax = 35 },
    { id = "tardis_coral", name = "TARDIS Coral", visual = "crystal", hpMin = 10, hpMax = 15, rpMin = 10, rpMax = 25 },
    { id = "psychic_paper", name = "Psychic Paper", visual = "box", hpMin = 0, hpMax = 0, rpMin = 20, rpMax = 40 },
    { id = "flux_capacitor", name = "Flux Capacitor", visual = "diamond", hpMin = 5, hpMax = 15, rpMin = 15, rpMax = 30 },

    -- Containers & Artifacts
    { id = "bacta_tank", name = "Bacta Tank", visual = "canister", hpMin = 20, hpMax = 35, rpMin = 0, rpMax = 0 },
    { id = "stasis_unit", name = "Stasis Unit", visual = "pod", hpMin = 15, hpMax = 25, rpMin = 5, rpMax = 10 },
    { id = "cryopod_fragment", name = "Cryopod Fragment", visual = "pod", hpMin = 10, hpMax = 20, rpMin = 5, rpMax = 15 },
    { id = "zero_point_module", name = "Zero-Point Module", visual = "diamond", hpMin = 5, hpMax = 15, rpMin = 15, rpMax = 35 },
    { id = "naquadah_generator", name = "Naquadah Generator", visual = "canister", hpMin = 5, hpMax = 10, rpMin = 20, rpMax = 40 },
    { id = "stargate_chevron", name = "Stargate Chevron", visual = "crystal", hpMin = 0, hpMax = 0, rpMin = 25, rpMax = 45 },
    { id = "tesseract_shard", name = "Tesseract Shard", visual = "crystal", hpMin = 5, hpMax = 15, rpMin = 15, rpMax = 30 },
    { id = "unobtainium_sample", name = "Unobtainium Sample", visual = "crystal", hpMin = 10, hpMax = 15, rpMin = 10, rpMax = 25 },
    { id = "dilithium_crystal", name = "Dilithium Crystal", visual = "crystal", hpMin = 0, hpMax = 0, rpMin = 30, rpMax = 50 },
    { id = "bio_neural_gel_pack", name = "Bio-Neural Gel Pack", visual = "circle", hpMin = 15, hpMax = 25, rpMin = 5, rpMax = 10 },
    { id = "self_sealing_stem_bolt", name = "Self-Sealing Stem Bolt", visual = "canister", hpMin = 5, hpMax = 10, rpMin = 10, rpMax = 25 },
    { id = "transparent_aluminum_sheet", name = "Transparent Aluminum Sheet", visual = "box", hpMin = 5, hpMax = 15, rpMin = 10, rpMax = 20 },

    -- Biological & Organic
    { id = "xenomorph_resin", name = "Xenomorph Resin", visual = "circle", hpMin = 10, hpMax = 20, rpMin = 5, rpMax = 15 },
    { id = "soylent_ration", name = "Soylent Ration", visual = "box", hpMin = 15, hpMax = 25, rpMin = 0, rpMax = 0 },
    { id = "spice_melange_canister", name = "Spice Melange Canister", visual = "canister", hpMin = 5, hpMax = 15, rpMin = 15, rpMax = 35 },
    { id = "tribble", name = "Tribble", visual = "circle", hpMin = 10, hpMax = 15, rpMin = 10, rpMax = 20 },
    { id = "nutrient_brick", name = "Nutrient Brick", visual = "box", hpMin = 10, hpMax = 20, rpMin = 5, rpMax = 10 },

    -- Computers & AI
    { id = "hal_9000_memory_core", name = "HAL 9000 Memory Core", visual = "diamond", hpMin = 0, hpMax = 0, rpMin = 25, rpMax = 50 },
    { id = "mu_th_ur_databank", name = "MU-TH-UR Databank", visual = "box", hpMin = 5, hpMax = 10, rpMin = 15, rpMax = 35 },
    { id = "colossus_logic_module", name = "Colossus Logic Module", visual = "diamond", hpMin = 0, hpMax = 0, rpMin = 20, rpMax = 40 },

    -- Miscellaneous Iconic
    { id = "soylent_cola", name = "Soylent Cola", visual = "canister", hpMin = 10, hpMax = 15, rpMin = 5, rpMax = 15 },
    { id = "slurm_can", name = "Slurm Can", visual = "canister", hpMin = 10, hpMax = 15, rpMin = 5, rpMax = 15 },
    { id = "brawndo_canister", name = "Brawndo Canister", visual = "canister", hpMin = 5, hpMax = 15, rpMin = 10, rpMax = 20 },
    { id = "nuka_cola", name = "Nuka Cola", visual = "canister", hpMin = 10, hpMax = 15, rpMin = 5, rpMax = 15 },
    { id = "cure_for_space_madness", name = "Cure for Space Madness", visual = "circle", hpMin = 20, hpMax = 30, rpMin = 0, rpMax = 0 },
    { id = "turbo_encabulator", name = "Turbo Encabulator", visual = "diamond", hpMin = 5, hpMax = 10, rpMin = 20, rpMax = 40 },
    { id = "illudium_q36_space_modulator", name = "Illudium Q-36 Space Modulator", visual = "box", hpMin = 0, hpMax = 0, rpMin = 30, rpMax = 50 },
    { id = "ringworld_scrith_shard", name = "Ringworld Scrith Shard", visual = "crystal", hpMin = 5, hpMax = 15, rpMin = 15, rpMax = 30 },
    { id = "monolith_sliver", name = "Monolith Sliver", visual = "box", hpMin = 5, hpMax = 10, rpMin = 15, rpMax = 35 },
}

return PickupsData
