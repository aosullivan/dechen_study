#!/usr/bin/env python3
"""Generate section_clues.json for the Guess the Chapter quiz.

Clues reference the COMMENTARY's structural outline (section topics,
parent topics) — never the verse content itself, which the user already sees.
"""

import re
import json

# ---------------------------------------------------------------------------
# Clue pools per chapter, organised by verse-number ranges.
# Each entry: (start_verse, end_verse, [clue_variations])
#
# KEY RULE: never paraphrase or reference what the verse says.
# Instead, reference the commentary topic: "Which chapter has a section
# about [X]?" where X comes from the structural outline.
# ---------------------------------------------------------------------------

CHAPTER_CLUES = {
    # ===================================================================
    # CHAPTER 1 – In Praise of Bodhicitta
    # ===================================================================
    1: [
        (1, 3, [
            "This section covers the purposes of the composition: homage, commitment to compose, and discarding pride.",
            "Which chapter opens with the author explaining the purposes and structure of the text?",
            "The commentary places this under 'the purposes of the composition'.",
            "Which chapter begins with homage to the Three Jewels and a commitment to compose?",
        ]),
        (4, 5, [
            "The commentary calls this section 'the primary basis: the individual person'.",
            "Which chapter has a section on the bodily and mental bases for practice?",
            "This falls under the commentary heading 'the difficulty of acquiring the freedoms and endowments'.",
        ]),
        (6, 8, [
            "The commentary places this under the 'ordinary benefits' of bodhicitta — invisible and visible.",
            "Which chapter has a section on how bodhicitta overcomes nonvirtue?",
            "This section discusses the 'productive cause': the generation of bodhicitta and its power.",
        ]),
        (9, 14, [
            "The commentary calls this section 'specific examples' illustrating the benefits through a series of analogies.",
            "Which chapter illustrates the benefits of bodhicitta through a sequence of elaborate analogies?",
            "This falls under the commentary heading on the visible benefits of bodhicitta.",
            "Which chapter has a section using analogies to show how bodhicitta overcomes evil and produces inexhaustible virtue?",
        ]),
        (15, 19, [
            "The commentary calls this section the 'characteristics' and 'extraordinary benefits' of the two types of bodhicitta.",
            "Which chapter explains the divisions of bodhicitta and their respective benefits?",
            "This section falls under the heading on distinguishing and praising the two types of bodhicitta.",
            "Which chapter has a section on the extraordinary benefits of aspiration and application bodhicitta?",
        ]),
        (20, 27, [
            "The commentary calls this 'the reasons for the benefits' — established through scripture and reasoning.",
            "Which chapter has a section establishing the benefits through the vastness of intent and rarity?",
            "This falls under the heading on why the benefits are so great — the intent's vastness and unprecedented nature.",
            "Which chapter argues through reasoning that the greatness of the intent explains the greatness of the benefit?",
            "The commentary identifies three reasons: vastness of intent, rarity, and greatness of goodness.",
        ]),
        (28, 36, [
            "The commentary places this under 'reasons for the benefits of application bodhicitta'.",
            "Which chapter has a section on why the bodhisattva's practice is superior to ordinary generosity?",
            "This falls under the heading on the particularly powerful field — both harmful and beneficial consequences.",
            "Which chapter concludes its opening section with praise and offerings to the sources of refuge?",
        ]),
    ],

    # ===================================================================
    # CHAPTER 2 – Confession of Faults
    # ===================================================================
    2: [
        (1, 9, [
            "The commentary calls this 'offerings of unowned worldly substances' to the Three Jewels.",
            "Which chapter has a section on outer offerings of material goods?",
            "This falls under the first of the seven branches — surpassable material offerings.",
            "Which chapter includes a structured sequence of outer and inner offerings to the Three Jewels?",
        ]),
        (10, 16, [
            "The commentary places this under inner offerings — bathing, robes, scented oils, incense, food.",
            "Which chapter includes bathing offerings, offering of robes, and offering of specific substances like incense and lamps?",
            "This section covers the inner material offerings — personal and elaborate.",
            "Which chapter has a section on inner offerings as part of the seven-branch prayer?",
        ]),
        (17, 25, [
            "The commentary calls this section 'unsurpassable offerings' and 'offering of homage' — praise and prostration.",
            "Which chapter includes the offering of homage — both praise and prostration?",
            "This falls under the final material offerings and the offering of service.",
            "Which chapter has a section on praise with melodious words and prostration to the Three Jewels?",
        ]),
        (26, 31, [
            "The commentary places this under 'taking refuge' and the beginning of 'confession of faults'.",
            "Which chapter has a section on taking refuge and considering one's past nonvirtues?",
            "This falls under the seven-point summary of taking refuge and the power of regret.",
            "Which chapter begins the actual confession — examining objects, nature, and motivation of nonvirtues?",
        ]),
        (32, 42, [
            "The commentary calls this 'longing to be freed swiftly' — through ceasing reliance on the unreliable.",
            "Which chapter has a section on the urgency of confession driven by the fear of death?",
            "This falls under the heading on fearing the results of nonvirtue and the aspects of suffering.",
            "Which chapter reflects on impermanence and the inevitable approach of death as motivation for purification?",
        ]),
        (43, 52, [
            "The commentary calls this 'the power of reliance' — taking refuge in specific bodhisattvas.",
            "Which chapter has a section on taking refuge in particular bodhisattvas as supports?",
            "This falls under the heading on taking hold of both general and particular supports.",
            "Which chapter invokes individual bodhisattvas by name as part of a purification practice?",
        ]),
        (53, 59, [
            "The commentary calls this 'the power of the antidote' — with analogies of illness and precipices.",
            "Which chapter has a section on applying antidotes, illustrated by analogies of serious illness?",
            "This falls under the heading on the reasons to persevere in the antidote.",
            "Which chapter uses the examples of illness and precipices to establish urgency?",
        ]),
        (60, 65, [
            "The commentary calls this 'the power of desisting' — restraint for the future.",
            "Which chapter has a section on the intention to abandon nonvirtue going forward?",
            "This falls under the heading on fearing consequences and definitively giving up worldly interests.",
            "Which chapter concludes its purification sequence with a pledge of future restraint?",
        ]),
    ],

    # ===================================================================
    # CHAPTER 3 – Fully Holding Bodhicitta
    # ===================================================================
    3: [
        (1, 6, [
            "The commentary places this under 'rejoicing' — one of the seven branches — and requesting the dharma wheel.",
            "Which chapter continues the seven-branch prayer with rejoicing, requesting teachings, and supplicating?",
            "This falls under the heading on rejoicing in worldly virtue, liberation, and enlightenment.",
            "Which chapter has a section on rejoicing in the virtue of Buddhas, bodhisattvas, and ordinary beings?",
        ]),
        (7, 10, [
            "The commentary calls this 'dedicating roots of merit' — toward eliminating sickness, hunger, and poverty.",
            "Which chapter has a section on dedicating merit toward specific forms of suffering?",
            "This falls under the heading on the dedication branch of the seven-branch prayer.",
        ]),
        (11, 20, [
            "The commentary calls this 'the main part' — aspirations and the actual taking of the vow.",
            "Which chapter has a section on aspiring to give up everything for the sake of beings?",
            "This falls under the heading on four aspirations leading to the bodhisattva vow.",
            "Which chapter includes aspirations to be sustenance, protector, and guide for all beings?",
            "The commentary identifies four aspirations here: to give up all, to create inexhaustible causes, to be sustenance, and to recite the vow.",
        ]),
        (21, 24, [
            "The commentary calls this 'reciting the words of the vow' — the pivotal formal moment.",
            "Which chapter has a section on the actual recitation of the bodhisattva commitment?",
            "This falls under the heading on formally adopting the vow in the presence of protectors.",
        ]),
        (25, 34, [
            "The commentary calls this 'generating joy in the attainment' — both benefit of self and benefit of others.",
            "Which chapter has a section on celebrating what has been attained — the meaning of one's life?",
            "This falls under the heading on the power to dispel suffering and obscurations and to establish happiness.",
            "Which chapter concludes with the power of the newly-generated bodhicitta to benefit self and others?",
        ]),
    ],

    # ===================================================================
    # CHAPTER 4 – Concern
    # ===================================================================
    4: [
        (1, 3, [
            "The commentary calls this the 'brief statement' of concern — never neglecting the training.",
            "Which chapter opens with a brief exhortation to examine everything with wisdom before acting?",
            "This falls under the heading on the general cause of practice: concern.",
        ]),
        (4, 11, [
            "The commentary calls this 'the faults of abandoning bodhicitta' — deceiving beings and obstructing the bhūmis.",
            "Which chapter has a section on the consequences of abandoning one's commitment?",
            "This falls under the heading on concern for bodhicitta — reasons not to abandon it.",
            "Which chapter warns that abandoning the vow amounts to deceiving all sentient beings?",
        ]),
        (12, 20, [
            "The commentary calls this 'concern to abandon nonvirtue' — repeatedly taking lower rebirths.",
            "Which chapter has a section on the near-impossibility of returning from the lower realms?",
            "This falls under the heading on concern for the training — accomplishing the path.",
            "Which chapter stresses that without virtue there is no higher rebirth, and without that, no opportunity?",
        ]),
        (21, 27, [
            "The commentary calls this 'concern to cultivate virtue' — many nonvirtues accumulated over lifetimes.",
            "Which chapter has a section on the faults of not striving — in this life and future lives?",
            "This falls under the heading on the accumulation of nonvirtue and the urgency of striving.",
        ]),
        (28, 42, [
            "The commentary calls this 'concern to abandon the defilements' — examining them as enemies.",
            "Which chapter has a section examining the defilements as enemies that have occupied the mind?",
            "This falls under the heading on identifying the defilements and their control over us.",
            "Which chapter has a section on the loss of autonomy caused by the defilements?",
            "The commentary describes a systematic examination of the defilements: their nature, their harm, and the resolve to fight them.",
            "Which chapter analyses how the defilements rob beings of freedom?",
        ]),
        (43, 48, [
            "The commentary calls this 'the means of devoting oneself to the application' — dedication, antidotes, and the nature of defilements.",
            "Which chapter concludes with the resolve to fight the defilements and the essential nature of the defilements?",
            "This falls under the heading on the means of combating the defilements through antidotes.",
            "Which chapter has a section on applying mindfulness and clear comprehension as weapons against the defilements?",
        ]),
    ],

    # ===================================================================
    # CHAPTER 5 – Clear Comprehension
    # ===================================================================
    5: [
        (1, 5, [
            "The commentary calls this 'guarding the mind as the means of guarding the training'.",
            "Which chapter has a section establishing that everything — all dangers and virtues — depends on the mind?",
            "This falls under the heading on the forward and reverse pervasion of mind as the basis of all.",
        ]),
        (6, 17, [
            "The commentary calls this section 'everything depends on the mind' — all the perfections included.",
            "Which chapter derives the importance of all the perfections from the single practice of guarding the mind?",
            "This falls under the heading on how giving, ethics, patience, energy, meditation, and wisdom all depend on mind.",
        ]),
        (18, 22, [
            "The commentary calls this 'making effort to guard the mind' — the skill and perspective needed.",
            "Which chapter has a section on the perspective needed for protecting the mind?",
            "This falls under the heading on protecting mindfulness with all one's might.",
        ]),
        (23, 33, [
            "The commentary calls this 'guarding mindfulness and clear comprehension'.",
            "Which chapter has a section on the faults of lacking mindfulness and its causes?",
            "This falls under the heading on how mindfulness is the means of guarding clear comprehension.",
            "Which chapter has a section on the causes of mindfulness — relying on teachers and proper mental attitude?",
        ]),
        (34, 47, [
            "The commentary calls this 'training in the conduct of guarding the mind' — in relation to body and mind.",
            "Which chapter has a section on training in vows — remaining undiverted and examining motivation?",
            "This falls under the heading on training in conduct relating to body and mind.",
            "Which chapter has a section on examining root and secondary defilements before every action?",
            "The commentary describes training in relation to body (sight, movements) and mind (tying the mind firmly).",
        ]),
        (48, 70, [
            "The commentary calls this 'guarding against damage to vows' and 'accomplishing non-attachment to the body'.",
            "Which chapter has a section on holding the mind firmly with antidotes like faith, steadfastness, and respect?",
            "This falls under the heading on the body as inanimate, impure, and essenceless.",
            "Which chapter has a section on applying the body to good use rather than pampering it?",
            "The commentary analyses the body to reduce attachment — examining its impurity and uselessness.",
        ]),
        (71, 83, [
            "The commentary calls this 'training in means of accomplishing virtue' — ordinary conduct and conduct toward others.",
            "Which chapter has a section on ordinary virtuous conduct — cheerful demeanour, quiet behaviour, accepting advice?",
            "This falls under the heading on conduct of action — speech, looking, and virtuous action.",
            "Which chapter has a section on praising the merit of others and gathering with wealth and dharma?",
        ]),
        (84, 97, [
            "The commentary calls this 'training in the conduct of benefitting sentient beings'.",
            "Which chapter has a section on increasing activities for others through gathering with wealth and dharma?",
            "This falls under the heading on protecting the minds of sentient beings and teaching to proper vessels.",
            "Which chapter has a section on daily conduct — eating, sleeping, movements — dedicated to others' benefit?",
        ]),
        (98, 109, [
            "The commentary calls this 'factors which enhance the training' — study, reliance on a teacher, application.",
            "Which chapter has a section on the cause of purifying faults and becoming knowledgeable through sūtras?",
            "This falls under the heading on the basis of training, the aim, and the teacher.",
            "Which chapter concludes with a summary of the training and the instruction to apply everything to practice?",
        ]),
    ],

    # ===================================================================
    # CHAPTER 6 – Patience
    # ===================================================================
    6: [
        (1, 6, [
            "The commentary calls this 'developing motivation' — the problems caused by anger, both invisible and visible.",
            "Which chapter opens with the invisible and visible results of one particular destructive emotion?",
            "This falls under the heading on developing the motivation to practise one specific quality.",
            "Which chapter has a section on how one emotion destroys merit and causes visible harm to mind and body?",
        ]),
        (7, 21, [
            "The commentary calls this 'preventing the characteristics of anger' — examining its causes and skilful means.",
            "Which chapter has a section on tolerating suffering by examining its nature, benefits, and through habituation?",
            "This falls under the heading on averting anger by examining unhappiness and its non-benefit.",
            "Which chapter has a section on the skilful means for accepting hardship?",
            "The commentary describes examining the benefits of renunciation and the qualities of practice as reasons not to resist hardship.",
        ]),
        (22, 34, [
            "The commentary calls this 'definitive consideration of the lack of autonomy' of anger and the angry person.",
            "Which chapter has a section arguing that both the angry person and the anger arise from conditions, not choice?",
            "This falls under the heading on stopping impatience through understanding that conditions lack autonomy.",
            "Which chapter has a section on not thinking of harm-doers as the true cause of harm?",
        ]),
        (35, 51, [
            "The commentary calls this 'examining one's own faults as the cause' and 'stopping impatience with disrespect'.",
            "Which chapter has a section on how your own karma contributed to the conditions for harm?",
            "This falls under the heading on the harm-doer being driven by delusion and examining disrespect.",
            "Which chapter has a section arguing that disrespect does not actually harm body or possessions?",
        ]),
        (52, 70, [
            "The commentary calls this 'stopping impatience with harm toward one's own side' — the Three Jewels, teachers, friends.",
            "Which chapter has a section on patience even when the objects of refuge or one's teacher are harmed?",
            "This falls under the heading on patience with harm-doers and examining one's own faults.",
            "Which chapter has a section on putting up with harm-doers by examining the marks of anger?",
        ]),
        (71, 100, [
            "The commentary calls this 'keeping in mind the results of patience' — reframing harm-doers as beneficial.",
            "Which chapter has a section on recasting harm-doers as essential opportunities for practice?",
            "This falls under the heading on the consequences of anger versus the benefits of patience.",
            "Which chapter has a section arguing that without harm-doers, this particular quality cannot be developed?",
            "The commentary argues that harm-doers are fields of merit — just as beggars are for generosity.",
        ]),
        (101, 134, [
            "The commentary calls this the summary of benefits — good fortune, reputation, beauty, health, long life.",
            "Which chapter concludes by cataloguing the worldly and spiritual benefits of one specific practice?",
            "This falls under the heading on compassion for the harm-doer and the concluding benefits.",
            "Which chapter has a section listing benefits like prosperity, beauty, health, and rebirth as results of practice?",
        ]),
    ],

    # ===================================================================
    # CHAPTER 7 – Effort
    # ===================================================================
    7: [
        (1, 2, [
            "The commentary defines this quality as 'joy in what is virtuous' and introduces its opposing factors.",
            "Which chapter opens by defining a perfection and identifying its three opposing factors?",
            "This falls under the heading on the nature of one particular perfection.",
        ]),
        (3, 5, [
            "The commentary calls this 'abandoning the laziness of non-application' — its cause and how to avert it.",
            "Which chapter has a section on three kinds of laziness?",
            "This falls under the heading on summarising the opposing factors.",
        ]),
        (6, 15, [
            "The commentary calls this section about overcoming laziness through reflecting on the sufferings of future lives.",
            "Which chapter has a section using awareness of death to overcome the laziness of non-application?",
            "This falls under the heading on the faults of this life and the sufferings of future lives.",
            "Which chapter has a section on exhortation to practise by reflecting on death and future suffering?",
        ]),
        (16, 30, [
            "The commentary calls this 'abandoning the laziness of despondency' — the antidote to thinking one lacks the ability.",
            "Which chapter has a section on overcoming the belief that you can't do it?",
            "This falls under the heading on the antidote to impatience with the application.",
            "Which chapter has a section reframing the difficulties of practice as trivial compared to saṃsāra's sufferings?",
            "The commentary argues that since even lesser beings can attain the goal, humans should not lose heart.",
        ]),
        (31, 46, [
            "The commentary calls this 'fully developing effort' through four powers: motivation, steadfastness, joy, and rest.",
            "Which chapter has a section on the power of motivation — contemplating the ripening of karma?",
            "This falls under the heading on the four powers of effort.",
            "Which chapter has a section on the cause and object of the power of motivation?",
        ]),
        (47, 60, [
            "The commentary calls this 'the power of steadfastness' and 'the power of joy' in practice.",
            "Which chapter has a section on stable preparation and stable engagement — not being deterred once committed?",
            "This falls under the heading on taking pride in one's actions, ability, and power over defilements.",
            "Which chapter has a section on the power of joy — finding delight in virtuous action?",
        ]),
        (61, 76, [
            "The commentary calls this 'the power of rest' and the chapter's conclusion on self-control.",
            "Which chapter has a section on the power of rest — temporary rest and finishing rest?",
            "This falls under the heading on dedication, concern, mindfulness, and self-control.",
            "Which chapter concludes with instructions on dedication to concern and preventing opposing circumstances?",
        ]),
    ],

    # ===================================================================
    # CHAPTER 8 – Meditation
    # ===================================================================
    8: [
        (1, 4, [
            "The commentary calls this 'abandoning contradictory factors' — isolation of body and mind for samādhi.",
            "Which chapter opens by prescribing isolation of body and mind as a prerequisite?",
            "This falls under the heading on the causes of not abandoning the world and their antidote.",
        ]),
        (5, 16, [
            "The commentary calls this 'establishing non-attachment toward sentient beings' — the faults of attachment.",
            "Which chapter has a section on the faults of attachment to sentient beings?",
            "This falls under the heading on why attachment to others destroys benefits and obstructs liberation.",
            "Which chapter has a section on how the desired object is unreliable, never satisfying, and leads to faults?",
        ]),
        (17, 37, [
            "The commentary calls this 'qualities of non-distraction' — friends, places, livelihood, and discriminations.",
            "Which chapter has a section on the qualities of solitude — dwelling places, companions, and livelihood?",
            "This falls under the heading on the ideal conditions for non-distraction.",
            "Which chapter has a section describing the ideal dwelling, companions, and way of life for practice?",
            "The commentary identifies friends, places, livelihood, and discriminations as qualities of non-distraction.",
        ]),
        (38, 70, [
            "The commentary calls this 'giving up conceptual discrimination' — examining impurity and the body's nature.",
            "Which chapter has a section on examining the impurity of the body, both living and dead?",
            "This falls under the heading on how results are destroyed by attachment and the impure nature of the body.",
            "Which chapter has a section on reasoning about impurity and how harm is abandoned by its cause?",
        ]),
        (71, 90, [
            "The commentary calls this 'developing joy in solitude' — its preeminence and unique happiness.",
            "Which chapter has a section on the preeminence and unique happiness of solitude?",
            "This falls under the heading on the introduction to equalising self and others.",
            "Which chapter has a section establishing the equality of self and others as a preliminary?",
        ]),
        (91, 110, [
            "The commentary calls this 'equalising self and others' — since all are equally subject to suffering.",
            "Which chapter has a section on equalising self and other through extensive analysis?",
            "This falls under the heading on focusing the mind on śamatha through equalising self and others.",
            "Which chapter has a section analysing why the continuum of suffering does not respect self/other boundaries?",
        ]),
        (111, 140, [
            "The commentary calls this 'exchanging self and others' — the actual practice of reversal.",
            "Which chapter has a section on the practice of exchanging self and other?",
            "This falls under the heading on practising mind control through the exchange.",
            "Which chapter has a section on contemplating envy, competitiveness, and pride from the reversed perspective?",
            "The commentary describes specific contemplations for the exchange practice.",
            "Which chapter has a section arguing that all suffering comes from self-cherishing and all happiness from cherishing others?",
        ]),
        (141, 160, [
            "The commentary continues the exchange practice with detailed meditation instructions.",
            "Which chapter has a section on detailed meditation instructions for the exchange of self and other?",
            "This falls under the heading on specific scenarios for contemplation from the other's perspective.",
        ]),
        (161, 187, [
            "The commentary calls this the conclusion — abandoning incompatible factors and relying on conducive ones.",
            "Which chapter concludes with instructions on sustaining practice — solitude, few wants, contentment?",
            "This falls under the heading on abandoning incompatible factors and focusing on meditation.",
            "Which chapter has a section on the final practical instructions for sustaining concentration?",
        ]),
    ],

    # ===================================================================
    # CHAPTER 9 – Wisdom
    # ===================================================================
    9: [
        (1, 5, [
            "The commentary calls this 'explaining that wisdom is the principal' — all factors were taught for its sake.",
            "Which chapter opens by establishing that everything taught so far serves one final quality?",
            "This falls under the heading on the two truths — relative and ultimate.",
            "Which chapter has a section introducing the framework of two truths?",
        ]),
        (6, 15, [
            "The commentary calls this 'abandoning objections of the Vaibhāṣikas and Sautrāntikas'.",
            "Which chapter has a section refuting the Vaibhāṣika and Sautrāntika positions on external objects?",
            "This falls under the heading on establishing the object as empty of intrinsic nature.",
            "Which chapter has a section debating whether the objects of perception truly exist as they appear?",
        ]),
        (16, 29, [
            "The commentary calls this 'abandoning objections of the Vijñaptimātrins (Mind Only school)'.",
            "Which chapter has a section refuting the Mind Only position?",
            "This falls under the heading on whether all experience can be reduced to consciousness alone.",
            "Which chapter has a section on whether the mind can be aware of itself?",
        ]),
        (30, 39, [
            "The commentary calls this 'establishing the subject as the path' — how illusion-like understanding ends suffering.",
            "Which chapter has a section on how understanding the illusion-like nature of things is itself the antidote?",
            "This falls under the heading on engaging in activity without effort after realisation.",
            "Which chapter has a section on how awakened beings continue to benefit others even without a self?",
        ]),
        (40, 49, [
            "The commentary calls this 'abandoning objections of the śrāvakas' — defending the Mahāyāna.",
            "Which chapter has a section establishing the Mahāyāna as the authentic word of the Buddha?",
            "This falls under the heading on establishing Mahāyāna scriptures as definitive meaning.",
            "Which chapter has a section addressing the objection that the Mahāyāna is not genuine Buddha-word?",
        ]),
        (50, 70, [
            "The commentary calls this the analysis of the self — searching among the aggregates, elements, and sense bases.",
            "Which chapter has a section searching for the self among the aggregates and elements?",
            "This falls under the heading on the result of meditation on emptiness.",
            "Which chapter has a section analysing whether physical form can be found among its elements?",
            "The commentary systematically examines each aggregate and finds none to be the self.",
        ]),
        (71, 85, [
            "The commentary calls this the analysis of mind — whether it can be located anywhere.",
            "Which chapter has a section examining where the mind resides?",
            "This falls under the heading on whether mind exists in sense organs, objects, or the space between.",
            "Which chapter has a section addressing the question: if there is no self, who experiences suffering?",
        ]),
        (86, 100, [
            "The commentary calls this the analysis of particles, contact, and perception at the fundamental level.",
            "Which chapter has a section examining the nature of contact and perception at the atomic level?",
            "This falls under the heading on whether partless particles can make contact.",
            "Which chapter has a section distinguishing conventional designation from ultimate reality?",
        ]),
        (101, 120, [
            "The commentary calls this section about navigating between nihilism and realism.",
            "Which chapter has a section on how emptiness is compatible with conventional function?",
            "This falls under the heading on how the four noble truths function within emptiness.",
            "Which chapter has a section addressing the objection that emptiness negates everything?",
            "The commentary argues that the freedom of not clinging to any view is the result of this analysis.",
        ]),
        (121, 140, [
            "The commentary calls this a section on how karma and transmigration function without inherent existence.",
            "Which chapter has a section on what continues from life to life in the absence of a self?",
            "This falls under the heading on examining cyclic existence — what keeps it going and what stops it.",
            "Which chapter has a section on how merit and nonvirtue still function despite emptiness?",
            "The commentary uses the analogy of illusion to explain how things function yet lack essence.",
        ]),
        (141, 155, [
            "The commentary calls this a section on whether emptiness undermines compassion.",
            "Which chapter has a section arguing that emptiness actually strengthens rather than weakens compassion?",
            "This falls under the heading on the compatibility of emptiness and the motivation to help beings.",
            "Which chapter has a section arguing that even illusory suffering deserves compassion?",
        ]),
        (156, 167, [
            "The commentary calls this the conclusion — how this understanding enables crossing the ocean of suffering.",
            "Which chapter concludes by pointing to this realisation as the cure for the root cause of suffering?",
            "This falls under the heading on the final benefits of realising emptiness.",
            "Which chapter reaches its climax with the promise that suffering can be ended through this understanding?",
        ]),
    ],
}


def parse_ref_number(ref_str):
    """Extract the verse number (part after the dot) as an integer."""
    parts = ref_str.split('.')
    if len(parts) != 2:
        return None
    num_str = re.sub(r'[a-z]+$', '', parts[1])
    try:
        return int(num_str)
    except ValueError:
        return None


def get_clue(chapter, verse_num, counters):
    """Get a clue for the given chapter and verse number, cycling through pools."""
    ranges = CHAPTER_CLUES.get(chapter)
    if not ranges:
        return None

    for start, end, clues in ranges:
        if start <= verse_num <= end:
            key = (chapter, start, end)
            idx = counters.get(key, 0)
            clue = clues[idx % len(clues)]
            counters[key] = idx + 1
            return clue

    # Fallback: use the last range's pool
    _, _, clues = ranges[-1]
    key = (chapter, 'fallback')
    idx = counters.get(key, 0)
    clue = clues[idx % len(clues)]
    counters[key] = idx + 1
    return clue


def main():
    with open('texts/verse_commentary_mapping.txt', 'r') as f:
        content = f.read()

    with open('texts/bcv_parsed.json', 'r') as f:
        parsed = json.load(f)

    refs_set = set(parsed['refs'])
    lines = content.split('\n')
    section_header = re.compile(r'^\[\d+\.')
    ref_extract = re.compile(r'(?:\[|-)(\d+\.\d+[a-z]*)')
    segment_suffix = re.compile(r'[a-z]+$')

    seen_refs = set()
    ref_entries = []

    i = 0
    while i < len(lines):
        line = lines[i]
        if not section_header.match(line):
            i += 1
            continue
        raw_refs = [m.group(1) for m in ref_extract.finditer(line)]
        if not raw_refs:
            i += 1
            continue
        seen_norm = set()
        normalized = []
        for r in raw_refs:
            base = segment_suffix.sub('', r)
            if base not in seen_norm and base in refs_set:
                seen_norm.add(base)
                normalized.append(base)
        i += 1
        while i < len(lines) and not section_header.match(lines[i]):
            i += 1

        if normalized:
            first_ref = normalized[0]
            if first_ref not in seen_refs:
                seen_refs.add(first_ref)
                chapter = int(first_ref.split('.')[0])
                verse_num = parse_ref_number(first_ref)
                if verse_num is not None:
                    ref_entries.append((first_ref, chapter, verse_num))

    counters = {}
    clue_map = {}
    missing = []

    for first_ref, chapter, verse_num in ref_entries:
        clue = get_clue(chapter, verse_num, counters)
        if clue:
            clue_map[first_ref] = clue
        else:
            missing.append(first_ref)

    with open('texts/section_clues.json', 'w') as f:
        json.dump(clue_map, f, indent=2, ensure_ascii=False)

    print(f"Generated {len(clue_map)} clues")
    print(f"Missing: {len(missing)} refs: {missing}")

    from collections import Counter
    ch_counts = Counter()
    for ref in clue_map:
        ch = int(ref.split('.')[0])
        ch_counts[ch] += 1
    for ch in sorted(ch_counts):
        print(f"  Chapter {ch}: {ch_counts[ch]} clues")


if __name__ == '__main__':
    main()
