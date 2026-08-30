module ProcGen

    CONDITIONS = [
        "cracked",
        "weathered",
        "polished",
        "dust-covered",
        "chipped",
        "remarkably well preserved"
    ]

    MATERIALS = [
        "wood",
        "pottery",
        "jade",
        "copper",
        "obsidian",
        "bone"
    ]

    TYPES = [
        "ring",
        "brooch",
        "figurine",
        "coin",
        "idol",
        "amulet",
        "tablet"
    ]

    DETAILS = [
        "depicting a coiled serpent",
        "engraved with tiny runes",
        "bearing a mark of unknown meaning",
        "decorated with spirals and dots",
        "showing a starburst",
        "carved with an all-seeing eye"
    ]

    RULERS = [
        "serpent king",
        "sun priest",
        "obsidian queen",
        "keeper of the gate",
        "lord of the deep halls"
    ]

    DISASTERS = [
        "endless night",
        "the devouring darkness",
        "the silent plague",
        "the cracking earth",
        "the falling sun"
    ]

    RELICS = [
        "the sacred gate",
        "the golden idol",
        "the heart of the mountain",
        "the buried throne",
        "the eternal flame"
    ]

    def self.generate_find
        {
            condition: CONDITIONS.sample,
            material: MATERIALS.sample,
            type: TYPES.sample,
            detail: DETAILS.sample,
            studied: false
        }
    end

    def self.describe_find(find)
        "A #{find[:condition]} #{find[:material]} #{find[:type]} #{find[:detail]}."
    end

    def self.generate_myth
        {
            ruler: RULERS.sample,
            disaster: DISASTERS.sample,
            relic: RELICS.sample
        }
    end

    def self.generate_inscription(myth)
        lines = [
            "The #{myth[:ruler]} sealed away #{myth[:disaster]}.",
            "The #{myth[:ruler]} guarded #{myth[:relic]}.",
            "Only #{myth[:relic]} could stop #{myth[:disaster]}.",
            "When #{myth[:relic]} falls, #{myth[:disaster]} returns.",
            "The priests served the #{myth[:ruler]}.",
            "#{myth[:relic]} lies beneath the temple."
        ]

        lines.sample
    end

    def self.damaged_inscription inscription
        words = inscription.split

        words.map! do |w|
            rand < 0.25 ? "[...]" : w
        end

        words.join(" ")
    end

end
