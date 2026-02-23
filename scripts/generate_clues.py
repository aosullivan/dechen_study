#!/usr/bin/env python3
"""Generate section_clues.json for the Guess the Chapter quiz."""

import re
import json

# ---------------------------------------------------------------------------
# Clue pools per chapter, organised by verse-number ranges.
# Each entry: (start_verse, end_verse, [clue_variations])
# A section whose first ref falls in [start, end] picks from that pool.
# "start" and "end" are verse numbers (the part after the dot).
# ---------------------------------------------------------------------------

CHAPTER_CLUES = {
    # ===================================================================
    # CHAPTER 1 – In Praise of Bodhicitta
    # ===================================================================
    1: [
        (1, 3, [
            "Śāntideva hasn't started the heavy lifting yet — he's still warming up.",
            "We're still in the opening pages — the author is introducing himself.",
            "The author is being humbly self-deprecating about what he's about to write.",
            "This is the overture — Śāntideva is setting the stage for what follows.",
            "Think prologues and promises — the real argument hasn't begun.",
        ]),
        (4, 5, [
            "This is about why you're lucky to even be reading this right now.",
            "The rarity of the present opportunity is being emphasised.",
            "Lightning and darkness feature here — think fleeting chances.",
            "Śāntideva is reminding you not to waste what's hard to find.",
        ]),
        (6, 14, [
            "Elixirs, jewels, trees, warriors, cosmic fire — Śāntideva is reaching for every analogy he can find.",
            "This verse uses a vivid image to illustrate the power of one specific mind state.",
            "Think of a section where everything is compared to something miraculous.",
            "Śāntideva is still selling you on why this one thing matters above all else.",
            "The author is piling up metaphors — each grander than the last.",
            "Great evils being consumed, prisons being escaped — the imagery is dramatic.",
            "A single mental quality is being praised as though it could change the universe.",
            "Plantain trees, alchemical elixirs, and fires at the end of time — all in service of one point.",
            "Limitless benefits are being enumerated — this section reads like an advertisement.",
        ]),
        (15, 19, [
            "A distinction is being drawn between wishing and doing — both valuable, but differently.",
            "Two varieties of the same precious thing are being compared.",
            "This is about the difference between wanting to go somewhere and actually setting off.",
            "Aspiration and application — the text is distinguishing two modes of the same quality.",
            "Even while sleeping, something remarkable happens for those who have taken this on.",
        ]),
        (20, 30, [
            "Even parents, gods, and sages are being compared unfavourably here.",
            "The intention to help all beings is being exalted above every other virtue.",
            "This part reads like a love letter to a particular state of mind.",
            "Śāntideva is arguing that even wanting to cure headaches generates boundless merit.",
            "The text is making the case that this intention has never arisen before — not even in dreams.",
            "A treasure of mind is being described as unprecedented and immeasurable.",
            "The mere wish to help is being ranked above offerings to all the Buddhas.",
            "Beings chase suffering while longing to escape it — the irony is deliberate.",
        ]),
        (31, 36, [
            "Śāntideva is wrapping up his opening argument with crescendo praise.",
            "The author is near the end of the beginning — the great advertisement.",
            "Malevolent thoughts toward certain beings are said to carry aeon-long consequences.",
            "Worldly generosity — even done contemptuously — earns respect. This is about something far greater.",
            "We're approaching a chapter boundary — the praise is reaching its peak.",
            "The sons of the conquerors are praised — harming them carries heavy consequences.",
        ]),
    ],

    # ===================================================================
    # CHAPTER 2 – Confession of Faults
    # ===================================================================
    2: [
        (1, 11, [
            "Think incense, jewels, and lotus ponds — an elaborate display of generosity.",
            "Śāntideva is visualising gifts fit for the entire universe.",
            "This verse is part of an imagined feast for enlightened beings.",
            "Mountains, forests, and wish-granting trees are being mentally offered.",
            "Bejewelled mountains and lakes adorned with lotus — the visualisation is lavish.",
            "The author is offering everything beautiful he can imagine — and then some.",
            "Crystal floors, pearl canopies, precious vases — this is ritual at its most elaborate.",
            "Flowers, fruits, fragrances — the senses are all engaged in this offering.",
            "Every conceivable beauty in the universe is being gathered and presented.",
            "These offerings aren't physical — they're the products of a generous imagination.",
        ]),
        (12, 25, [
            "Bodies are being offered, bathing rituals described — a personal act of devotion.",
            "The finest cloths and fragrant robes are being offered to holy beings.",
            "Scented oils, parasols, and melodious praise — the ritual continues.",
            "This is a structured devotional sequence — think of the branches of a prayer.",
            "Prostrations and praise are being made with great formality.",
            "The author is physically bowing — not just with body but with the full weight of his voice.",
            "Jewel lamps, golden lotuses, and palaces — offered in imagination.",
            "Songs of praise are being composed to the sages and their sons.",
            "Taking refuge is being pledged — until a very specific endpoint.",
        ]),
        (26, 40, [
            "This is a very personal moment — the author is facing his own failures.",
            "Śāntideva is not being philosophical here — he's being brutally honest about himself.",
            "The tone shifts from grand offerings to raw vulnerability.",
            "Impermanence is making the confession urgent — death could come at any time.",
            "The author is terrified of what his actions have set in motion.",
            "Friends, family, possessions — all will be left behind. Only karma remains.",
            "The Lord of Death is approaching and there is nowhere to hide.",
            "Fear of consequences is motivating a desperate honesty.",
            "Past nonvirtues are being recalled with genuine regret.",
            "The confession is powered by a visceral awareness of mortality.",
            "Śāntideva is asking to be freed from his own accumulated negativity.",
            "The author realises his body will be cremated — but his karma will follow him.",
        ]),
        (41, 55, [
            "Specific bodhisattvas are being called upon by name for protection.",
            "The author is taking refuge in particular enlightened beings — Mañjughoṣa, Avalokiteśvara and others.",
            "An analogy with illness or a precipice is being used to establish urgency.",
            "If ordinary dangers demand such caution, how much more so for these?",
            "The power of reliance — turning to protectors in a time of need.",
            "Śāntideva is reaching out to compassionate beings for help with his predicament.",
        ]),
        (56, 65, [
            "The seven-branch prayer is nearing completion.",
            "Restraint for the future is being pledged alongside confession of the past.",
            "Think of what you do at the end of an elaborate ritual sequence.",
            "The author is wrapping up a structured devotional practice with distinct steps.",
            "Purification of former lives and a vow of restraint — the confession concludes.",
            "The closing acts of a multi-part prayer are underway.",
        ]),
    ],

    # ===================================================================
    # CHAPTER 3 – Fully Holding Bodhicitta
    # ===================================================================
    3: [
        (1, 6, [
            "Rejoicing is happening — in others' virtue, liberation, and enlightenment.",
            "The seven-branch prayer continues here — this is one of its middle branches.",
            "The author is celebrating others' good deeds with genuine delight.",
            "Buddhas are being asked not to disappear — to keep teaching.",
            "The dharma wheel is being requested to turn — a formal supplication.",
            "Rejoicing in virtue at every level — from worldly goodness to the bhūmis.",
        ]),
        (7, 15, [
            "Merit is being dedicated toward removing all forms of suffering.",
            "Something irreversible is happening — a point of no return.",
            "The author is giving away everything — body, pleasures, all accumulated merit.",
            "Think of a solemn ceremony — formal words are being spoken.",
            "The aspiration here is total: to be a bridge, a boat, a lamp for others.",
            "Śāntideva aspires to be whatever beings need — medicine, food, sustenance.",
            "This verse has the feeling of a ceremony — think vows and celebrations.",
        ]),
        (16, 24, [
            "The bodhisattva vow is being taken — the actual words are being recited.",
            "The author is no longer just talking about the path — he's stepping onto it.",
            "Witnesses are being called — something formal and irreversible is happening.",
            "All beings are being invited to a feast of temporary and ultimate happiness.",
            "In the presence of the protectors, a commitment is being made.",
            "The vow itself is being spoken aloud — this is the pivotal moment.",
        ]),
        (25, 34, [
            "The joy here comes from a specific moment of commitment — it's celebratory.",
            "The author has just done something momentous and is revelling in it.",
            "Birth into the Buddha family is being celebrated — the author feels transformed.",
            "A blind person finding a jewel in a heap of refuse — that kind of astonishment.",
            "Śāntideva is calling on all beings to share in his happiness.",
            "The power to dispel suffering, ignorance, and bad rebirths is now in hand.",
            "Life has just become meaningful — the author knows it and is exultant.",
        ]),
    ],

    # ===================================================================
    # CHAPTER 4 – Concern
    # ===================================================================
    4: [
        (1, 6, [
            "Śāntideva is essentially saying: 'Do you realise what you just promised?'",
            "This is the 'but seriously though' moment after the celebration.",
            "Having taken the vow, the stakes of failure are now terrifyingly clear.",
            "The commitment must never be neglected — the consequences of doing so are spelled out.",
            "Deceiving all sentient beings — that's what abandoning this commitment amounts to.",
            "If you promise to free beings from prison and then abandon them — what follows?",
        ]),
        (7, 16, [
            "The faults of breaking one's word are being laid out with mathematical precision.",
            "Even beings who give up lesser commitments fall — how much worse for this one?",
            "The text is describing a terrifying cycle of rebirth that follows from carelessness.",
            "The rarity of the right conditions is emphasised — they may never come again.",
            "This reads like a stern warning label attached to a powerful commitment.",
            "Lower realms, no opportunity for virtue, no way back — the stakes are existential.",
            "The tone here is urgent — like a warning on the edge of a cliff.",
        ]),
        (17, 27, [
            "The defilements are being described as adversaries in a battle you can't afford to lose.",
            "Nonvirtues have been accumulated over many lives and they don't exhaust themselves.",
            "The enemy here isn't external — it lives in the mind and has been there a long time.",
            "Śāntideva is cataloguing the ways the defilements ruin everything — systematically.",
            "Without striving now, despondency and regret will come — but too late.",
            "The author is reflecting on how much negativity has been accumulated over lifetimes.",
            "Time is running out — and the defilements are getting stronger, not weaker.",
            "These enemies have no beginning and no end — unless you take action.",
            "The 'honeyed lip of the poisoned cup' — pleasures that lead to destruction.",
        ]),
        (28, 42, [
            "The defilements are being examined as though Śāntideva were a general studying the enemy.",
            "These are not ordinary foes — they've occupied the mind since beginningless time.",
            "Loss of autonomy is the key theme — the defilements are the ones in control.",
            "The author is building resolve — identifying exactly what must be overcome.",
            "If you'd fight an ordinary enemy to the death, why tolerate this one?",
            "Even banished enemies regroup and return — but these ones never left.",
            "The defilements have stolen your freedom and you didn't even notice.",
            "Śāntideva is arguing that tolerating this internal occupation is madness.",
        ]),
        (43, 48, [
            "The final resolve is being made — this battle must be fought to the end.",
            "Dedication, antidotes, and unwavering commitment — the chapter's practical conclusion.",
            "Bears and bees pursue their goals single-mindedly — why can't you?",
            "The essential nature of the defilements is being examined — they're not as solid as they seem.",
            "The chapter closes with a rallying cry — no more passivity toward the real enemy.",
            "Śāntideva grips his weapons of mindfulness and clear comprehension.",
        ]),
    ],

    # ===================================================================
    # CHAPTER 5 – Clear Comprehension
    # ===================================================================
    5: [
        (1, 10, [
            "The mind is being identified as the root of all troubles — and all virtues.",
            "If just one thing is guarded, everything else falls into place.",
            "Śāntideva is arguing that an unguarded mind is more dangerous than any external threat.",
            "All the sufferings of the hells were created by the mind — not by anyone else.",
            "Weapons, snakes, enemies — none compare to the danger of your own undisciplined mind.",
            "When the elephant of the mind is bound, all fears are bound.",
        ]),
        (11, 22, [
            "The perfections themselves — giving, ethics, patience — all depend on mental training.",
            "The subject here is how to pay attention — not what to pay attention to.",
            "Guarding the mind is presented as the single most important practice.",
            "Like protecting a wound in a jostling crowd — that's the level of vigilance needed.",
            "It's better to let everything else degenerate than to lose control of the mind.",
            "All the dangers in the world were created by mind alone — this is the central argument.",
        ]),
        (23, 33, [
            "Mindfulness and clear comprehension are the gatekeepers being introduced.",
            "Without these two, learning won't help — knowledge leaks like water from a cracked pot.",
            "The text is describing what happens when awareness lapses — defilements rush in.",
            "Think of someone standing guard at the doorway of the mind — that's the practice here.",
            "Mindfulness is the sentinel — clear comprehension follows naturally when it's present.",
            "Teachers, a sense of proper mental attitude — these are presented as causes.",
        ]),
        (34, 58, [
            "This reads more like a rulebook than a poem — very practical instructions.",
            "Śāntideva sounds like a mindfulness teacher giving moment-by-moment instructions.",
            "How to look, how to sit, how to walk — the instructions are startlingly specific.",
            "The elephant of the mind is being tied to the great pillar of practice.",
            "Every bodily action is being brought under the scope of awareness.",
            "Before acting, check your motivation — that's the essential message.",
            "Root defilements, secondary defilements — the mind is being examined at granular level.",
            "Stand firm like a tree — don't move without clear purpose.",
            "The gaze, the posture, the speech — everything is being regulated.",
            "This is the most practical, day-to-day section of the entire text.",
            "Think of someone following you around all day saying 'are you paying attention?'",
        ]),
        (59, 83, [
            "The body is being described as essentially useless — impure, inanimate, without essence.",
            "Why protect this body so carefully when it will be food for vultures?",
            "The body should be put to good use — not pampered as though it were precious.",
            "Cheerful faces, quiet voices, accepting advice — practical guidelines for daily conduct.",
            "Praising others' merit, speaking gently — the instructions are interpersonal now.",
            "This is about how to behave around other people — very grounded advice.",
            "The body is like a boat — useful for crossing, not for worshipping.",
            "Actions, speech, looking at others — all are being brought under mindful regulation.",
        ]),
        (84, 109, [
            "Benefitting sentient beings is the focus — how to teach, share, and protect others' minds.",
            "The text is talking about how to give dharma teachings — to suitable recipients.",
            "Eating, sleeping, moving — even these are being dedicated to others' benefit.",
            "The training is being summarised — the key point is to apply everything to practice.",
            "Śāntideva recommends reading the Sutra of Three Heaps three times daily.",
            "Becoming knowledgeable through study, then applying it — that's the instruction.",
            "Everything you do should benefit beings — directly or indirectly.",
            "The chapter is wrapping up with a call to learn from the teacher and the sūtras.",
        ]),
    ],

    # ===================================================================
    # CHAPTER 6 – Patience
    # ===================================================================
    6: [
        (1, 10, [
            "One instant of this emotion can destroy the merit of a thousand aeons.",
            "Think of the one emotion that undoes everything good in an instant.",
            "No peace, no happiness, no sleep — the visible consequences are being listed.",
            "Friends become enemies and even those who are helped turn against you.",
            "The cause of this destructive state is being identified: unhappiness of mind.",
            "If you remove the fuel, the fire cannot burn — that's the logic here.",
        ]),
        (11, 21, [
            "Suffering is being examined — and the conclusion is that getting angry about it doesn't help.",
            "The text asks: if you can fix it, why be upset? If you can't, why be upset?",
            "Habituation is key — even what seems unbearable becomes tolerable with practice.",
            "Renunciation is described as having a beneficial quality — not a punishing one.",
            "Śāntideva is using logic to cool down a very hot emotion.",
            "The analogy of gradually increasing tolerance — from small pains to great ones.",
        ]),
        (22, 34, [
            "Neither the angry person nor the anger itself chose to arise — both lack autonomy.",
            "Conditions produce the harm — no one actually decides to be harmful.",
            "This verse asks: if you wouldn't be angry at bile for causing pain, why be angry at a person?",
            "Sticks and weapons don't anger you — so why be angry at the hand that wields them?",
            "The opponent being analysed here is not a person — it's a feeling everyone recognises.",
            "Śāntideva is arguing that the real culprit is the defilements, not the person.",
            "Anger itself is compelled by conditions — even the angry person is a victim.",
        ]),
        (35, 51, [
            "The harm-doer is driven by delusion — understanding this changes everything.",
            "Like a hallucination causing someone to attack — the anger isn't truly their own.",
            "Your own karma brought this situation about — why blame the other person?",
            "This chapter asks: if you wouldn't kick a stick, why kick the one who swung it?",
            "Praise and reputation are being examined — do they actually benefit you?",
            "Getting angry about insults makes as much sense as getting angry at an echo.",
            "Disrespect doesn't harm the body or possessions — so what exactly is threatened?",
            "The analysis here is forensic — every reason for anger is being dismantled.",
        ]),
        (52, 70, [
            "Even when the Three Jewels are harmed, patience is the response — they don't need your anger.",
            "Obstacles to getting what you want are examined — and anger is shown to be pointless about them.",
            "Someone harming your teacher or friend? Even then, patience is prescribed.",
            "The faults of others should make you think of your own faults first.",
            "Examining the results of actions — anger's consequences are worse than the original harm.",
            "Whether the harm is to yourself or those you love, the analysis points the same way.",
        ]),
        (71, 100, [
            "Enemies are being recast as teachers — they provide the opportunity to practise.",
            "Without someone to forgive, there would be no patience — harm-doers are essential.",
            "Merit from patience is limitless — and it requires an adversary to arise.",
            "If beggars are fields of merit for generosity, enemies are fields of merit for this practice.",
            "The suffering that motivates renunciation is itself a form of benefit.",
            "Śāntideva is making the radical argument that harm-doers deserve gratitude.",
            "Someone is being harmed — and Śāntideva is arguing they shouldn't react.",
            "The text is examining whether the 'enemy' is really an enemy at all.",
            "Patience brings good fortune, beauty, health, long life — the benefits are listed.",
            "If you truly want to help others, losing your temper is the worst thing you can do.",
        ]),
        (101, 134, [
            "The benefits of patience are being catalogued — from reputation to good rebirth.",
            "Compassion for the harm-doer is the unexpected conclusion of this analysis.",
            "The chapter is nearing its close — patience has been thoroughly established as supreme.",
            "Anger is being compared to other austerities — and found to be the only one that matters.",
            "Good fortune, prosperity, beauty — all fruits of mastering this one practice.",
            "The final verses read like a summation — every reason not to give in to this emotion.",
            "Śāntideva asks: if patience brings all this, why would you choose its opposite?",
            "The person who harmed you is now being viewed with something close to tenderness.",
        ]),
    ],

    # ===================================================================
    # CHAPTER 7 – Effort
    # ===================================================================
    7: [
        (1, 2, [
            "A new pāramitā is being introduced — built on the foundation of the previous one.",
            "The definition is deceptively simple: joy in what is virtuous.",
            "This is the one quality without which all the others remain theoretical.",
        ]),
        (3, 15, [
            "Śāntideva is essentially giving himself a pep talk about getting off the couch.",
            "Three kinds of laziness are being identified — and none of them look like what you'd expect.",
            "The obstacle here isn't anger or attachment — it's plain old inertia.",
            "Death is mentioned here not to scare you, but to light a fire under you.",
            "Think of someone who knows exactly what to do but just... can't get started.",
            "The Yama's messengers are approaching — and you're lying there distracted.",
            "Like a buffalo with a butcher — that's how unaware you are of what's coming.",
            "If someone sentenced to have their hand cut off could be freed by losing a finger — they'd rejoice.",
            "Distractions and idle pleasures are being identified as forms of laziness.",
            "The suffering ahead is being used to generate urgency now.",
        ]),
        (16, 30, [
            "Despondency — thinking 'I can't do this' — is being systematically dismantled.",
            "Even insects and animals can attain the goal — how much more a human with faculties?",
            "The text is building motivation — like a coach's halftime speech.",
            "Difficulties on the path are reframed as trivial compared to the sufferings of saṃsāra.",
            "A doctor cutting to heal causes less suffering than the disease — that's the logic.",
            "The Buddha himself said it could be done by anyone — Śāntideva takes him at his word.",
            "Don't be discouraged by giving away hands and feet — you haven't understood emptiness yet.",
            "Present comforts from past virtue will run out — future suffering awaits the idle.",
        ]),
        (31, 46, [
            "Four powers are being introduced as the engine of sustained practice.",
            "Motivation, steadfastness, joy, and rest — the recipe for sustained application.",
            "Contemplating karma's ripening is prescribed — to generate the will to act.",
            "The power of motivation is built through reflecting on what actions lead to.",
            "Preparing to act without hesitation — testing your strength before committing.",
            "Taking pride in one's ability to practise — not arrogance, but confident resolve.",
            "Like an elephant entering a lake — plunging into virtue with delight.",
            "Actions should not be started and abandoned — better to prepare well first.",
        ]),
        (47, 60, [
            "Steadfastness in action — not wavering once committed.",
            "The defilements should be looked down upon, not feared — you have the advantage.",
            "A crow encountering a dying snake puffs up with confidence — act the same way with defilements.",
            "Pride in one's actions, one's capability, and one's power over defilements — three forms of healthy confidence.",
            "Joy in virtuous action should be like a child's joy in play — effortless and absorbing.",
            "Worldly people work so hard for uncertain results — why not apply the same to certain ones?",
            "Never satisfied with virtue — that's the attitude being cultivated.",
        ]),
        (61, 76, [
            "Rest when needed — like a soldier between engagements — then return to the fight.",
            "An experienced warrior sidesteps the sword — that's how to handle the defilements.",
            "Drop what's failing like a dropped sword in battle — pick up another weapon immediately.",
            "Mindfulness, concern, and self-control — the chapter's concluding triad.",
            "Light as cotton — that's how responsive the body and mind should become.",
            "The chapter closes with practical advice on maintaining sustained enthusiasm.",
            "Like cotton moved by the wind — effortless, responsive, and always in motion.",
        ]),
    ],

    # ===================================================================
    # CHAPTER 8 – Meditation
    # ===================================================================
    8: [
        (1, 16, [
            "Śāntideva is making a case for leaving everything behind.",
            "This verse suggests that other people might be the biggest obstacle.",
            "Attachment to beings is identified as the primary distraction.",
            "Friends are unreliable, hard to please, and will eventually leave — why cling?",
            "Getting close to others leads to disappointment — that's the argument being made.",
            "Desire for companionship is presented as a subtle chain.",
            "The text is warning that even well-meaning relationships can derail practice.",
            "Childish people — neither satisfied nor satisfying — are best kept at a distance.",
            "If you praise them, they're pleased; if you speak truthfully, they're angry.",
        ]),
        (17, 37, [
            "Forests and graveyards sound appealing in this section.",
            "Caves, abandoned shrines, and the foot of trees — the ideal dwelling is being described.",
            "Deer, birds, and trees as companions — the author is serious about this.",
            "Living with nothing to protect and no one to please — that's the vision.",
            "The body will be left behind at death — why not leave everything else behind now?",
            "A meagre robe and a begging bowl — all that's needed.",
            "Solitude is being presented not as deprivation but as freedom.",
            "No mourners at your funeral, no one to be missed — that's the preferred situation.",
            "The natural world is described with genuine longing — a place of peace.",
            "This section reads like a love letter to the forest.",
        ]),
        (38, 70, [
            "The body's impurity is being examined — in vivid, unflinching detail.",
            "Burial grounds and decomposition feature prominently here.",
            "What is so attractive about a body? Śāntideva systematically takes it apart.",
            "Bones, flesh, and skin — the object of desire is being disassembled.",
            "The analysis is visceral — what lies beneath the surface of what we find attractive.",
            "Attraction is being examined forensically — what exactly are you attached to?",
            "A body wrapped in skin versus unwrapped — the difference is only concealment.",
            "The living body is no different from the dead one — just warmer.",
            "Desire for bodies is being described as fundamentally confused.",
            "Even your own body — why pamper something that's essentially a walking corpse?",
        ]),
        (71, 90, [
            "Joy in solitude — this section describes its incomparable happiness.",
            "Free from disputes, free from defilements — the meditator's life is being praised.",
            "Others' bodies will never bring lasting happiness — the logic is relentless.",
            "Thinking about impermanence here — everything that seems solid will dissolve.",
            "Cool moonlight, silence, vast spaces — the contemplative life at its most appealing.",
            "Equality of self and others is being introduced — a pivotal concept.",
            "Happiness and suffering are distributed equally — that's the starting premise.",
        ]),
        (91, 120, [
            "Śāntideva is asking you to imagine being someone else — literally trading places.",
            "The logic here is radical: what if 'self' and 'other' could be swapped?",
            "This verse is part of the most psychologically daring section of the text.",
            "If my foot's pain bothers me because it's 'mine' — why not extend that to others?",
            "The boundary between self and other is being philosophically dissolved.",
            "Protecting others from suffering should be as natural as protecting yourself.",
            "The continuum of suffering doesn't respect the borders we draw around 'me'.",
            "Self-cherishing is the source of all suffering — cherishing others is the source of all happiness.",
            "The hands protect the feet not because they're the same, but because they belong to one body.",
            "An imagined rival and an imagined inferior — Śāntideva is roleplaying both perspectives.",
            "Look at the faults of cherishing yourself — look at the virtues of cherishing others.",
            "What you fear for yourself, wish away from others. What you wish for yourself, give to others.",
        ]),
        (121, 160, [
            "The exchange is becoming practical — specific contemplations are being prescribed.",
            "Envy, competitiveness, and pride are being examined from the reversed perspective.",
            "Imagine taking on the suffering of others and giving them your happiness — that's the practice.",
            "The self is being turned inside out — what was 'mine' becomes 'theirs' and vice versa.",
            "This section describes the actual meditation technique — not just the philosophy.",
            "Your own body should be used for others' benefit — that's the conclusion being drawn.",
            "Looking at yourself through others' eyes — the text is painfully honest about what they'd see.",
            "The reversal is complete — self-interest has been redirected outward.",
            "Specific scenarios of rivalry and condescension are being examined — from the other side.",
            "Whatever happiness exists in the world comes from wishing others well.",
            "The contemplation here is deeply interior — think cushion, not classroom.",
            "Giving away your merit, taking on others' suffering — the practice is being described in detail.",
        ]),
        (161, 187, [
            "The meditation instructions are reaching their conclusion.",
            "Body, speech, and mind are being yoked to the service of others.",
            "Abandoning incompatible factors, relying on conducive ones — the final practical advice.",
            "Eyes should never wander without purpose — the instructions are precise.",
            "The body should be like a wish-fulfilling tree for other beings.",
            "This section wraps up with specific advice on how to sustain the practice.",
            "Solitude, few wants, contentment — the conditions for deep practice are being established.",
            "Life is short — don't waste it. That's the chapter's closing note.",
        ]),
    ],

    # ===================================================================
    # CHAPTER 9 – Wisdom
    # ===================================================================
    9: [
        (1, 5, [
            "You might need a philosophy degree for this section — it's about to get dense.",
            "The text shifts from practice to theory — sharp analysis begins here.",
            "Two truths are being introduced — the framework for everything that follows.",
            "All the previous chapters were taught for the sake of this one.",
            "Relative and ultimate — a distinction is being drawn that changes everything.",
            "Śāntideva is putting on his philosopher hat — and it's staying on.",
        ]),
        (6, 15, [
            "An objection is being raised and systematically demolished.",
            "A particular Buddhist school's position is being challenged.",
            "The debate is about whether external objects truly exist — or only appear to.",
            "This is a classic Indian philosophical exchange — objection, response, counter-response.",
            "The text is dismantling a realist position with surgical precision.",
            "Tiny particles and their relationships are being examined — do they hold up?",
            "If atoms have parts, they can be divided. If they don't, nothing is composed of them.",
        ]),
        (16, 29, [
            "Mind-only — the position is being examined and found wanting.",
            "If everything is just mind, who's perceiving whom?",
            "The text is arguing against reducing all experience to consciousness alone.",
            "Even the Buddha said 'mind only' for a specific purpose — not as final truth.",
            "One school of thought is being dismantled piece by piece.",
            "The question of whether illusions can perceive themselves is being raised.",
            "Self-awareness of mind is being analysed — can a sword cut itself?",
        ]),
        (30, 49, [
            "If everything is like an illusion, how does that help end suffering?",
            "The path is being established — understanding illusion-nature is itself the antidote.",
            "Śāntideva is defending the Mahāyāna against those who question its scriptural authority.",
            "The objection is that Mahāyāna is not the Buddha's word — the response is methodical.",
            "Like fire not being truly fire — even the antidote is ultimately empty.",
            "Activities of awakened beings continue even without a self — like a wish-fulfilling tree.",
            "Offerings still matter even though the recipient is beyond concepts — an important point.",
            "Things are being taken apart to see if anything is really there.",
        ]),
        (50, 77, [
            "The analysis is getting more granular — the self is being looked for and not found.",
            "Earth, water, fire, wind, space, consciousness — where is the self among these?",
            "If 'I' is the aggregate of parts, which part is doing the aggregating?",
            "Physical form is being reduced to its elements — and none of them is 'body'.",
            "The mind is being examined — is it in the sense organs? The objects? The space between?",
            "Feelings, perceptions, formations, consciousness — each is examined and found to be not-self.",
            "The analysis is relentless — nothing survives the search for inherent existence.",
            "If there's no self, who suffers? The question is being addressed head-on.",
            "The reasoning here follows a pattern: look for the thing, fail to find it, draw the conclusion.",
            "Śāntideva is dismantling the very thing we cling to most tightly.",
        ]),
        (78, 100, [
            "The analysis is reaching its conclusion — what remains when everything is examined?",
            "Atoms, contact, perception — the building blocks of experience are being scrutinised.",
            "Can partless particles touch? If they can't, what is 'contact'?",
            "Consciousness without form apprehending form — the circularity is being exposed.",
            "The text is now in deep philosophical territory — each concept examined and deconstructed.",
            "Emptiness isn't being introduced here — it's being driven home with forensic rigour.",
            "The debate has moved to the very foundations of perception and reality.",
            "If you thought the earlier analysis was thorough, this section goes even deeper.",
            "Conventional designation is being distinguished from ultimate reality — carefully.",
        ]),
        (101, 130, [
            "The argument is now between Mādhyamikas and other Buddhist schools.",
            "Suffering exists by convention — but not ultimately. The implications are being worked out.",
            "Compassion arises from the conventional — and is no less valid for being empty.",
            "The four noble truths are being reconciled with emptiness — a delicate operation.",
            "This is a dialogue — positions are being stated and refuted in alternation.",
            "The freedom that comes from not clinging to any view — that's the prize being described.",
            "If nothing truly exists, does the path still work? Yes — and here's why.",
            "The text is navigating the knife-edge between nihilism and realism.",
            "The opponent keeps saying 'but if things are empty, then...' — and Śāntideva keeps responding.",
            "Conventional truth does the work of liberation — ultimate truth is its nature.",
            "Even emptiness is empty — the analysis doesn't exempt itself.",
        ]),
        (131, 155, [
            "The benefits of realising emptiness are now being described — they're immense.",
            "Cyclic existence is being examined — what keeps it going, and what stops it.",
            "The text asks: what is it that continues from life to life?",
            "Karma and its results are being examined in the light of emptiness.",
            "Merit and nonvirtue still function — even in the absence of inherent existence.",
            "The bodhisattva's compassion becomes even more powerful when combined with this understanding.",
            "Like a dream, like a magical illusion — the comparisons are piling up.",
            "If beings are like illusions, why help them? Because their suffering is real to them.",
            "The text is addressing the most common objection: doesn't emptiness undermine compassion?",
            "Saṃsāra and nirvāṇa — the distinction is being dissolved.",
        ]),
        (156, 167, [
            "The ocean of suffering can be crossed — that's the promise of this analysis.",
            "Emptiness is the medicine that cures the root illness — clinging to existence.",
            "The chapter is reaching its peak — the highest wisdom is being pointed to.",
            "For the sake of beings, Śāntideva would endure anything — understanding emptiness makes this possible.",
            "The final verses of this analysis read like a crescendo of realisation.",
            "Having dismantled everything, the text arrives at something luminous.",
        ]),
    ],
}


def parse_ref_number(ref_str):
    """Extract the verse number (part after the dot) as an integer."""
    parts = ref_str.split('.')
    if len(parts) != 2:
        return None
    # Strip any segment suffixes
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

    # Find matching range
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
    # Parse commentary sections
    with open('texts/verse_commentary_mapping.txt', 'r') as f:
        content = f.read()

    with open('texts/bcv_parsed.json', 'r') as f:
        parsed = json.load(f)

    refs_set = set(parsed['refs'])
    lines = content.split('\n')
    section_header = re.compile(r'^\[\d+\.')
    ref_extract = re.compile(r'(?:\[|-)(\d+\.\d+[a-z]*)')
    segment_suffix = re.compile(r'[a-z]+$')

    # Collect all unique (first_ref, chapter) pairs in order
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
        # Normalize
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

    # Generate clues
    counters = {}
    clue_map = {}
    missing = []

    for first_ref, chapter, verse_num in ref_entries:
        clue = get_clue(chapter, verse_num, counters)
        if clue:
            clue_map[first_ref] = clue
        else:
            missing.append(first_ref)

    # Write output
    with open('texts/section_clues.json', 'w') as f:
        json.dump(clue_map, f, indent=2, ensure_ascii=False)

    print(f"Generated {len(clue_map)} clues")
    print(f"Missing: {len(missing)} refs: {missing}")

    # Stats per chapter
    from collections import Counter
    ch_counts = Counter()
    for ref in clue_map:
        ch = int(ref.split('.')[0])
        ch_counts[ch] += 1
    for ch in sorted(ch_counts):
        print(f"  Chapter {ch}: {ch_counts[ch]} clues")


if __name__ == '__main__':
    main()
