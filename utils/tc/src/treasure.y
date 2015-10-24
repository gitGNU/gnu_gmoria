/* treasure.y: a Moria treasure definition compiler

   Copyright (C) 2007, 2010 Ben Asselstine
   Written by Ben Asselstine

   tc is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   tc is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with tc; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>
#include <argz.h>

#include <stdlib.h>

#include "config.h"
#include "st.h"
#include "opts.h"
#include "treasure.h"
#include "tcheck.h"
#include "xvasprintf.h"


/*
 * defined_t is used to indicate whether all fields have been defined
 */

typedef struct {
    unsigned	special: 1,
		tval: 1,
		tchar: 1,
		subval: 1,
		p1: 1,
		cost: 1,
		number: 1,
		weight: 1,
		tohit: 1,
		todam: 1,
		ac: 1,
		toac: 1,
		damage: 1,
		stackable: 1,
		stackable_id: 1,
		buyable: 1,
		unique_function: 1,
		store_only: 1,
		level: 1,
		mushroom_flag: 1;
} defined_t;



/*
 * template_t contains treasure definition & flags
 */

typedef struct 
{
  char *id;
  state_type state;
  treasure_type	val;
  defined_t def;
} template_t;

typedef struct 
{
  char *id;
  state_type state;
  treasure_type	val;
  defined_t def;
} sorted_template_t;



/*
 * symInit_t is used to initialize symbol tables with integer values
 */

typedef struct 
{
  char *name;
  int32u val;
} symInit_t;


static symInit_t 
eatingcausesInit[] = 
{
   { "poisoning", 0 },
   { "blindness", 1 },
   { "fear", 2 },
   { "confusion_i", 3 },
   { "confusion_ii", 4 },
   { "cure_poison", 5 },
   { "cure_blindness", 6 },
   { "cure_fear", 7 },
   { "cure_confusion", 8 },
   { "lose_strength", 9 },
   { "lose_constitution", 10 },
   { "restore_strength", 15 },
   { "restore_constitution", 16 },
   { "restore_intelligence", 17 },
   { "restore_wisdom", 18 },
   { "restore_dexterity", 19 },
   { "restore_charisma", 20 },
   { "cure_wounds_i", 21 },
   { "cure_wounds_ii", 22 },
   { "cure_wounds_iii", 23 },
   { "cure_wounds_iv", 25 },
   { "cause_wounds", 26 },
};

static symInit_t 
potion1causesInit[] = 
{
   { "gain_strength", 0 },
   { "lose_strength", 1 },
   { "restore_strength", 2 },
   { "gain_intelligence", 3 },
   { "lose_intelligence", 4 },
   { "restore_intelligence", 5 },
   { "gain_wisdom", 6 },
   { "lose_wisdom", 7 },
   { "restore_wisdom", 8 },
   { "gain_charisma", 9 },
   { "lose_charisma", 10 },
   { "restore_charisma", 11 },
   { "cure_wounds_i", 12 },
   { "cure_wounds_ii", 13 },
   { "cure_wounds_iii", 14 },
   { "healing", 15 },
   { "gain_constitution", 16 },
   { "gain_experience", 17 },
   { "sleep", 18 },
   { "blindness", 19 },
   { "confusion", 20 },
   { "poisoning", 21 },
   { "speed", 22 },
   { "slowness", 23 },
   { "gain_dexterity", 25 },
   { "restore_dexterity", 26 },
   { "restore_constitution", 27 },
   { "cure_blindness", 28 },
   { "cure_confusion", 29 },
   { "cure_poison", 30 },
   { NULL, 0 }
};

static symInit_t 
potion2causesInit[] = 
{
   { "lose_experience", 1 },
   { "throw_up", 2 },
   { "invulnerability", 3 },
   { "heroism", 4 },
   { "super_heroism", 5 },
   { "cure_fear", 6 },
   { "restore_life_levels", 7 },
   { "resist_heat", 8 },
   { "resist_cold", 9 },
   { "see_invisible", 10 },
   { "slow_poison", 11 },
   { "cure_poison", 12 },
   { "restore_mana", 13 },
   { "infravision", 14 },
   { NULL, 0 }
};

static symInit_t 
scrollcausesInit[] = 
{
   { "increase_tohit", 0 },
   { "increase_todam", 1 },
   { "enchant_armor_i", 2 },
   { "identify", 3 },
   { "remove_curse", 4 },
   { "light", 5 },
   { "summon_monster", 6 },
   { "phase_door", 7 },
   { "teleport", 8 },
   { "teleport_level", 9 },
   { "confuse_monster", 10 },
   { "magic_mapping", 11 },
   { "sleep_monsters_i", 12 },
   { "warding_glyph", 13 },
   { "detect_treasure", 14 },
   { "detect_objects", 15 },
   { "detect_traps", 16 },
   { "detect_secret_doors", 17 },
   { "mass_genocide", 18 },
   { "detect_invisble", 19 },
   { "aggravate_monster", 20 },
   { "create_trap", 21 },
   { "trap_or_door_destruction", 22 },
   { "create_door", 23 },
   { "recharge", 24 },
   { "genocide", 25 },
   { "darkness", 26 },
   { "protection_from_evil", 27 },
   { "create_food", 28 },
   { "dispel_undead", 29 },
   { "enchant_weapon", 32 },
   { "curse_weapon", 33 },
   { "enchant_armor_ii", 34 },
   { "curse_armor", 35 },
   { "summon_undead", 36 },
   { "bless_i", 37 },
   { "bless_ii", 38 },
   { "bless_iii", 39 },
   { "recall", 40 },
   { "earthquake", 41 },
   { NULL, 0 }
};

static symInit_t 
staffcausesInit[] = 
{
   { "light", 0 },
   { "detect_secret_doors", 1 },
   { "detect_traps", 2 },
   { "detect_treasures", 3 },
   { "detect_objects", 4 },
   { "teleport", 5 },
   { "earthquake", 6 },
   { "summon_monster", 7 },
   { "earthquake_ii", 9 },
   { "starlight", 10 },
   { "speed_monsters", 11 },
   { "slow_monsters", 12 },
   { "sleep_monsters_ii", 13 },
   { "cure_wounds_i", 14 },
   { "detect_invisible", 15 },
   { "speed", 16 },
   { "slowness", 17 },
   { "mass_polymorph", 18 },
   { "remove_curse", 19 },
   { "detect_evil", 20 },
   { "curing", 21 },
   { "dispel_undead", 22 },
   { "darkness", 24 },
   { NULL, 0 }
};

static symInit_t 
wandcausesInit[] = 
{
   { "light_line", 0 },
   { "lightning_bolt", 1 },
   { "frost_bolt", 2 },
   { "fire_bolt", 3 },
   { "stone_to_mud", 4 },
   { "polymorph_monster", 5 },
   { "heal_monster", 6 },
   { "haste_monster", 7 },
   { "slow_monster", 8 },
   { "confuse_monster", 9 },
   { "sleep_monster", 10 },
   { "drain_life", 11 },
   { "destroy_traps_and_doors", 12 },
   { "magic_missile", 13 },
   { "build_wall", 14 },
   { "clone_monster", 15 },
   { "teleport_monster", 16 },
   { "disarm_all", 17 },
   { "lightning_ball", 18 },
   { "cold_ball", 19 },
   { "fire_ball", 20 },
   { "poison_gas", 21 },
   { "acid_ball", 22 },
   { "wonder", 23 },
   { NULL, 0 }
};


static symInit_t 
specialInit[] = 
{
    { "strength", 0 },
    { "intelligence", 1 },
    { "wisdom", 2 },
    { "dexterity", 3 },
    { "constitution", 4 },
    { "charisma", 5 },
    { "search", 6 },
    { "slow_digestion", 7 },
    { "stealth", 8 },
    { "aggravate", 9 },
    { "teleport", 10 },
    { "regenerate", 11 },
    { "speed", 12 },
    { "ego_slay_dragon", 13 },
    { "ego_slay_animal", 14 },
    { "ego_slay_evil", 15 },
    { "ego_slay_undead", 16 },
    { "ego_frost_brand", 17 },
    { "ego_flame_tongue", 18 },
    { "resist_fire", 19 },
    { "resist_acid", 20 },
    { "resist_cold", 21 },
    { "sustain_stat", 22 },
    { "free_action", 23 },
    { "see_invisible", 24 },
    { "resist_lightning", 25 },
    { "free_falling", 26 },
    { "blindness", 27 },
    { "fear", 28 },
    { "tunnel", 29 },
    { "infrared", 30 },
    { "cursed", 31 },
    { NULL, 0 }
};

static symInit_t
spellsInit[] = 
{
    { "magic_missile", 0},
    { "detect_monsters", 1},
    { "phase_door", 2},
    { "light_area", 3},
    { "cure_light_wounds", 4},
    { "find_hidden_traps_and_doors", 5},
    { "stinking_cloud", 6},
    { "confusion", 7},
    { "lightning_bolt", 8},
    { "trap_and_door_destruction", 9},
    { "sleep_i", 10},
    { "cure_poison", 11},
    { "teleport_self", 12},
    { "remove_curse", 13},
    { "frost_bolt", 14},
    { "turn_stone_to_mud", 15},
    { "create_food", 16},
    { "recharge_item_i", 17},
    { "sleep_ii", 18},
    { "polymorph_other", 19},
    { "identify", 20},
    { "sleep_iii", 21},
    { "fire_bolt", 22},
    { "slow_monster", 23},
    { "frost_ball", 24},
    { "recharge_item_ii", 25},
    { "teleport_other", 26},
    { "haste_self", 27},
    { "fire_ball", 28},
    { "resist_poison_gas", 29},
    { "word_of_destruction", 30},
    { "genocide", 31},
    { NULL, 0 },
};

static symInit_t
prayersInit[] = 
{
    { "detect_evil", 0},
    { "cure_light_wounds", 1},
    { "bless", 2},
    { "remove_fear", 3},
    { "call_light", 4},
    { "find_traps", 5},
    { "detect_doors_and_stairs", 6},
    { "slow_poison", 7},
    { "blind_creature", 8},
    { "portal", 9},
    { "cure_medium_wounds", 10},
    { "chant", 11},
    { "sanctuary", 12},
    { "create_food", 13},
    { "remove_curse", 14},
    { "resist_heat_and_cold", 15},
    { "neutralize_poison", 16},
    { "orb_of_draining", 17},
    { "cure_serious_wounds", 18},
    { "sense_invisible", 19},
    { "protection_from_evil", 20},
    { "earthquake", 21},
    { "sense_surroundings", 22},
    { "cure_critical_wounds", 23},
    { "turn_undead", 24},
    { "pray_prayer", 25},
    { "dispel_undead", 26},
    { "heal", 27},
    { "dispel_evil", 28},
    { "resist_poison_gas", 29},
    { "glyph_of_warding", 30},
    { "holy_word", 31},
    { NULL, 0 },
};

static symInit_t
stackableInit[] = 
{
    { "never", 0},
    { "with_same_kind", 1},
    { "with_same_p1", 2},
    { NULL, 0 },
};

static symInit_t
buyableInit[] = 
{
    { "by_general_store", 0 },
    { "by_armoury", 1 },
    { "by_weaponsmith", 2 },
    { "by_temple", 3 },
    { "by_alchemist", 4 },
    { "by_magic_shop", 5 },
    { "exclusively_in_town", 6 },
    { NULL, 0 },
};

static symInit_t 
uniqfuncInit[] = 
{
    { "chest_ruined", UNIQ_CHEST_RUINED},
    { "wizard_object", UNIQ_WIZARD_OBJECT},
    { "scare_monster", UNIQ_SCARE_MONSTER},
    { "created_by_spell", UNIQ_CREATED_BY_SPELL},
    { "inventory_object", UNIQ_INVENTORY_OBJECT},
    { NULL, 0 }
};

static symInit_t 
containsInit[] = 
{
    { "carry_small_obj", 23 },
    { "carry_obj", 24 },
    { "carry_gold", 25 },
    { "has_random_60", 26 },
    { "has_random_90", 27 },
    { "has_1d2_obj", 28 },
    { "has_2d2_obj", 29 },
    { "has_4d2_obj", 30 },
    { NULL, 0 }
};

static symInit_t
tvalInit[] = 
{
    { "nothing", 0},
    { "misc", 1},
    { "chest", 2},
    { "sling_ammo", 10},
    { "bolt", 11},
    { "arrow", 12},
    { "spike", 13},
    { "light", 15},
    { "bow", 20},
    { "hafted", 21},
    { "polearm", 22},
    { "sword", 23},
    { "digging", 25},
    { "boots", 30},
    { "gloves", 31},
    { "cloak", 32},
    { "helm", 33},
    { "shield", 34},
    { "hard_armor", 35},
    { "soft_armor", 36},
    { "amulet", 40},
    { "ring", 45},
    { "staff", 55},
    { "wand", 65},
    { "scroll", 70},
    { "potion1", 75},
    { "potion2", 76},
    { "potion", 75}, //placeholder for potion1 (75) or potion2 (76)
    { "flask", 77},
    { "food", 80},
    { "mushroom", 80}, //not a tval. distinguishing between mushrooms and food
    { "magic_book", 90},
    { "prayer_book", 91},
    { "gold", 100},
    { "invis_trap", 101},
    { "vis_trap", 102},
    { "rubble", 103},
    { "open_door", 104},
    { "closed_door", 105},
    { "up_stair", 107},
    { "down_stair", 108},
    { "secret_door", 109},
    { "store_door", 110},
    { NULL, 0 },
};



/*
 * Maximum token length = maximum string constant length
 * Also, trim the stack to an "acceptable" size.
 */

#define	MAX_TOK_LEN	64		/* maximum acceptable token length  */
#define	YYSTACKSIZE	128

#define GEN_TYPE_TMPL	256		/* type of a template for st	    */

int treasureCt;
/*
 * Globals used by the tokenizer (lexical analyzer)
 */

#define INPUT_BUF_SIZE 256
static char	inputBuf[INPUT_BUF_SIZE] = { 0 };
					/* input line buffer		    */
static char	*inputBufp = inputBuf;	/* position in input line buffer    */
static int	lineNo = 0;		/* number of current line	    */
static FILE	*input_F;
static char	tokStr[MAX_TOK_LEN];	/* text of current token	    */
static	int	tokType;		/* type of current token	    */

static template_t blankTemplate;	/* blank template for init-ing     */
static template_t tmpTemplate;		/* working template for current     */
					/* class or treasure		    */

char *adjective_argz = NULL;            /* the working adjective           */
size_t adjective_argz_len = 0;
char *mushroom_adjectives_argz = NULL;  /* unidentified mushroom words      */
size_t mushroom_adjectives_argz_len = 0;
char *wand_adjectives_argz = NULL;      /* unidentified wand words          */
size_t wand_adjectives_argz_len = 0;
char *staff_adjectives_argz = NULL;     /* unidentified staff words         */
size_t staff_adjectives_argz_len = 0;
char *potion_adjectives_argz = NULL;    /* unidentified potion words        */
size_t potion_adjectives_argz_len = 0;
char *amulet_adjectives_argz = NULL;    /* unidentified amulet words        */
size_t amulet_adjectives_argz_len = 0;
char *ring_adjectives_argz = NULL;      /* unidentified ring words          */
size_t ring_adjectives_argz_len = 0;
char *syllables_argz = NULL;            /* syllables for scrolls           */
size_t syllables_argz_len = 0;


/*
 * Global symbol tables
 */

static st_Table_Pt keywordT_P;		/* parser's keywords		    */
static st_Table_Pt containsT_P;		/* treasure flags for chests	    */
static st_Table_Pt specialT_P;		/* special properties		    */
static st_Table_Pt uniqfuncT_P;		/* the horrible one-offs	    */
static st_Table_Pt spellsT_P;		/* spells that go in books	    */
static st_Table_Pt prayersT_P;		/* prayers that go in books	    */
static st_Table_Pt eatingcausesT_P;	/* effects of eating foodstuffs     */
static st_Table_Pt potion1causesT_P;	/* effects of eating tv_potion1     */
static st_Table_Pt potion2causesT_P;	/* effects of eating tv_potion2     */
static st_Table_Pt scrollcausesT_P;	/* effects of reading tv_scroll    */
static st_Table_Pt staffcausesT_P;	/* effects of using tv_staff        */
static st_Table_Pt wandcausesT_P;	/* effects of zapping tv_wand       */
static st_Table_Pt tvalT_P;		/* treasure types		    */
static st_Table_Pt stackableT_P;	/* how the object stacks	    */
static st_Table_Pt buyableT_P;		/* object is in these stores*/
static st_Table_Pt classT_P;		/* class templates		    */
static st_Table_Pt treasureT_P;		/* treasure definitions		    */
static st_Table_Pt sortedtreasureT_P;	/* sorted treasure definitions	    */

/*
 * Function declarations
 */

extern void WriteTreasure ();
extern void PutClassTemplate ();
extern template_t GetClassTemplate ();
extern int MergeClassTemplate (char *s, template_t *t1);
extern void AddSpecial ();
extern void NegSpecial ();
extern void AddContainsFlag ();
extern void NegContainsFlag ();
extern void AddSpell ();
extern void NegSpell ();
extern void AddPrayer ();
extern void NegPrayer ();
extern void AddStackableFlag ();
extern void AddRelativeSubval();
extern void NegStackableFlag ();
extern void AddEquipNewFlag ();
extern void NegEquipNewFlag ();
extern void AddBuyableFlag ();
extern void AddEatingFlag ();
extern void NegEatingFlag ();
extern void AddPotionFlag ();
extern void NegPotionFlag ();
extern void AddScrollFlag ();
extern void NegScrollFlag ();
extern void AddStaffFlag ();
extern void NegStaffFlag ();
extern void AddWandFlag ();
extern void NegWandFlag ();
extern void AddTVal ();
extern void AddAdjective ();
extern void AddUniqueFunction ();
extern void PutTreasure ();
extern void PutAdjectives ();
extern void PutSyllables ();

%}


/*
 * YACC DEFINITIONS
 */

/*
 * The parser's stack can hold ints, doubles, and strings.
 */

%union {
	int ival;
	double dval;
	char sval[MAX_TOK_LEN];
	}

/*
 * Reserved words
 */

%token CLASS TREASURE SPECIAL TVAL TCHAR P1 COST NUMBER WEIGHT TO_HIT
%token TO_DAM AC TO_AC DAMAGE LEVEL NONE PRAYER SPELL BUYABLE
%token STACKABLE SUBVAL UNIQUE_FUNCTION EATING_CAUSES CONTAINS RELSUBVAL
%token POTION_CAUSES SCROLL_CASTS UNIDENTIFIED WAND_CASTS STAFF_CASTS SYLLABLES
/*
 * Entities
 */


%{
static symInit_t 
keywordInit[] = 
{
    { "class", CLASS },
    { "treasure", TREASURE},
    { "special", SPECIAL},
    { "spell", SPELL},
    { "prayer", PRAYER},
    { "kind", TVAL},
    { "letter", TCHAR},
    { "p1", P1},
    { "cost", COST},
    { "quantity", NUMBER},
    { "weight", WEIGHT},
    { "to_hit", TO_HIT},
    { "to_dam", TO_DAM},
    { "ac", AC},
    { "to_ac", TO_AC},
    { "damage", DAMAGE},
    { "level", LEVEL},
    { "none", NONE},
    { "stackable", STACKABLE},
    { "subval", SUBVAL},
    { "relsubval", RELSUBVAL},
    { "unique_function", UNIQUE_FUNCTION},
    { "sold", BUYABLE},
    { "eating_causes", EATING_CAUSES},
    { "contains", CONTAINS},
    { "potion_causes", POTION_CAUSES},
    { "scroll_casts", SCROLL_CASTS},
    { "staff_casts", STAFF_CASTS},
    { "wand_casts", WAND_CASTS},
    { "unidentified", UNIDENTIFIED},
    { "syllable", SYLLABLES},
    { NULL, 0 } /* note, is 32 the max here ?*/
};
%}
%token <sval> IDENTIFIER	/* identifier, not a keyword		    */
%token <dval> FLOAT_LIT		/* floating-pt literal			    */
%token <ival> INT_LIT		/* integer literal			    */
%token <sval> STRING_LIT	/* string literal			    */
%token <ival> BOOL_LIT		/* boolean literal			    */

/*
 * ASCII chars are their own tokens
 */


%start	treasures


/*
 * THE PARSER
 */

%%

treasures	:	class_def ';' treasures
		|	treasure_def ';' treasures
		|	unidentified_def ';' treasures
		|	syllables_def ';' treasures
		|	comment_def  treasures
		|	/* empty */
		;

comment_def 	: 	'#' comments 
			{/*don't do anything*/;}
		;

comments	: 	comment more_comments
		;

comment		: 	IDENTIFIER  
			{/* don't do anything with it*/;}
		;

more_comments	:  	comment more_comments
		|	/* empty */
		;

syllables_def   :	SYLLABLES '{' adjectives '}'
				{ PutSyllables (); }
		;

unidentified_def:	UNIDENTIFIED IDENTIFIER '{' adjectives '}'
				{ PutAdjectives ($<sval>2); }
		;

adjectives      :	adjective more_adjectives
		;

adjective	:	STRING_LIT
				{ AddAdjective ($<sval>1); }
		;

more_adjectives :	',' adjective more_adjectives
		|	/* empty */
		;

class_def	:	CLASS IDENTIFIER parent_classes '{' features '}'
				{ PutClassTemplate($<sval>2, &tmpTemplate); 
  				  tmpTemplate = blankTemplate; }
		;

parent_classes	:	':' parent_class more_classes
		|	/* empty */
			{ tmpTemplate = blankTemplate; }
		;

parent_class	:	IDENTIFIER
				{ MergeClassTemplate ($<sval>1, &tmpTemplate); }
		|	/* empty */
				{ tmpTemplate = blankTemplate; }
		;


more_classes	:	',' parent_class more_classes
		|	/* empty */
		;

treasure_def	:	TREASURE STRING_LIT parent_classes
			'{' features '}'
				{ 
                                  tmpTemplate.id = xasprintf("%06d", 
                                                             treasureCt);
                                  tmpTemplate.val.name = xasprintf("%s", 
                                                                   $<sval>2);
				  PutTreasure (tmpTemplate.id, &tmpTemplate,
					      arguments.tc.consistency_check);
				  tmpTemplate = blankTemplate;
                                  treasureCt++;
				}
		;

features	:	feature ';' features
		|	/* empty */
		;

feature		:	LEVEL ':' INT_LIT
				{ tmpTemplate.val.level = $<ival>3;
				  tmpTemplate.def.level = TRUE; }
		|	DAMAGE ':' INT_LIT '|' INT_LIT
				{ tmpTemplate.val.damage[0] = $<ival>3;
				  tmpTemplate.val.damage[1] = $<ival>5;
				  tmpTemplate.def.damage = TRUE; }
		|	COST ':' INT_LIT
				{ tmpTemplate.val.cost = $<ival>3;
				  tmpTemplate.def.cost = TRUE; }
		|	RELSUBVAL ':' INT_LIT { AddRelativeSubval ($<ival>3); } 
		|	SUBVAL ':' INT_LIT
				{ tmpTemplate.val.subval = $<ival>3;
				  tmpTemplate.def.subval = TRUE; }
		|	AC ':' INT_LIT
				{ tmpTemplate.val.ac = $<ival>3;
				  tmpTemplate.def.ac = TRUE; }
		|	TCHAR ':' STRING_LIT
				{ tmpTemplate.val.tchar = $<sval>3[0];
				  tmpTemplate.def.tchar = TRUE; }
		|	TCHAR ':' INT_LIT
				{ tmpTemplate.val.tchar = $<ival>3; //XXX
				  tmpTemplate.def.tchar = TRUE; }
		|	TO_AC ':' INT_LIT
				{ tmpTemplate.val.toac = $<ival>3;
				  tmpTemplate.def.toac = TRUE; }
		|	TO_HIT':' INT_LIT
				{ tmpTemplate.val.tohit = $<ival>3;
				  tmpTemplate.def.tohit = TRUE; }
		|	TO_DAM':' INT_LIT
				{ tmpTemplate.val.todam = $<ival>3;
				  tmpTemplate.def.todam = TRUE; }
		|	P1':' INT_LIT
				{ tmpTemplate.val.p1 = $<ival>3;
				  tmpTemplate.def.p1 = TRUE; }
		|	NUMBER':' INT_LIT
				{ tmpTemplate.val.number = $<ival>3;
				  tmpTemplate.def.number = TRUE; }
		|	WEIGHT':' INT_LIT
				{ tmpTemplate.val.weight = $<ival>3;
				  tmpTemplate.def.weight = TRUE; }
		|	BUYABLE ':' buy_flags
		|	TVAL':' tval
		|	EATING_CAUSES ':' eatingcauses
		|	POTION_CAUSES ':' potion1causes
		|	SCROLL_CASTS ':' scrollcauses
		|	STAFF_CASTS ':' staffcauses
		|	WAND_CASTS ':' wandcauses
		|	SPECIAL':' specials
		|	SPELL':' spells
		|	PRAYER':' prayers
		|	CONTAINS ':' carries
		|	STACKABLE':' stack_flags
		|	UNIQUE_FUNCTION ':' unique_functions
		;

buy_flags	:	buy_flag more_buy_flags
		;

buy_flag	:	IDENTIFIER { AddBuyableFlag ($<sval>1, 1); }
		|	IDENTIFIER '*' INT_LIT 
                                { AddBuyableFlag ($<sval>1, $<ival>3); }
		|	NONE /* empty */
		;

more_buy_flags:		',' buy_flag more_buy_flags
		|	/* empty */
		;

unique_functions:	IDENTIFIER { AddUniqueFunction ($<sval>1); }
		;

tval		:	IDENTIFIER { AddTVal ($<sval>1); }
		;

carries		:	carry more_carries
		;

carry		:	IDENTIFIER { AddContainsFlag ($<sval>1); }
		|	'~' IDENTIFIER { NegContainsFlag ($<sval>2); }
		|	NONE { tmpTemplate.def.special = TRUE; }
		;

more_carries	:	',' carry more_carries
		|	/* empty */
		;

stack_flags	:	stack_flag more_stack_flags
		;

stack_flag	:	IDENTIFIER { AddStackableFlag ($<sval>1); }
		|	'~' IDENTIFIER { NegStackableFlag ($<sval>2); }
		|	NONE /* empty */
		;

more_stack_flags:	',' stack_flag more_stack_flags
		|	/* empty */
		;

spells		:	spell more_spells
		;

spell		:	IDENTIFIER { AddSpell ($<sval>1); }
		|	'~' IDENTIFIER { NegSpell ($<sval>2); }
		|	NONE /* empty */
		;

more_spells	:	',' spell more_spells
		|	/* empty */
		;

prayers		:	prayer more_prayers
		;

prayer		:	IDENTIFIER { AddPrayer ($<sval>1); }
		|	'~' IDENTIFIER { NegPrayer ($<sval>2); }
		|	NONE /* empty */
		;

more_prayers	:	',' prayer more_prayers
		|	/* empty */
		;

specials	:	special more_specials
		;

special		:	IDENTIFIER { AddSpecial ($<sval>1); }
		|	'~' IDENTIFIER { NegSpecial ($<sval>2); }
		|	NONE /* empty */
		;

more_specials	:	',' special more_specials
		|	/* empty */
		;

eatingcauses	:	eatingcause more_eatingcauses
		;

eatingcause	:	IDENTIFIER { AddEatingFlag ($<sval>1); }
		|	'~' IDENTIFIER { NegEatingFlag ($<sval>2); }
		|	NONE /* empty */
		;

more_eatingcauses:	',' eatingcause more_eatingcauses
		|	/* empty */
		;

potion1causes	:	potion1cause more_potion1causes
		;

potion1cause	:	IDENTIFIER { AddPotionFlag ($<sval>1); }
		|	'~' IDENTIFIER { NegPotionFlag ($<sval>2); }
		|	NONE /* empty */
		;

more_potion1causes:	',' potion1cause more_potion1causes
		|	/* empty */
		;

scrollcauses	:	scrollcause more_scrollcauses
		;

scrollcause	:	IDENTIFIER { AddScrollFlag ($<sval>1); }
		|	'~' IDENTIFIER { NegScrollFlag ($<sval>2); }
		|	NONE /* empty */
		;

more_scrollcauses:	',' scrollcause more_scrollcauses
		|	/* empty */
		;

staffcauses	:	staffcause more_staffcauses
		;

staffcause	:	IDENTIFIER { AddStaffFlag ($<sval>1); }
		|	'~' IDENTIFIER { NegStaffFlag ($<sval>2); }
		|	NONE /* empty */
		;

more_staffcauses:	',' staffcause more_staffcauses
		|	/* empty */
		;

wandcauses	:	wandcause more_wandcauses
		;

wandcause	:	IDENTIFIER { AddWandFlag ($<sval>1); }
		|	'~' IDENTIFIER { NegWandFlag ($<sval>2); }
		|	NONE /* empty */
		;

more_wandcauses:	',' wandcause more_wandcauses
		|	/* empty */
		;
%%



/*
 * MyFGetC--
 *	fgetc with support for comments
 *
 *	# is the comment character.  comment lasts till end of line.
 * Spews out an extra char of whitespace at EOF since something seems to
 * need it.  I'll figure this out eventually...
 */
static int 
MyFGetC (FILE *input_F)
{
  while (!*inputBufp || (*inputBufp == '#')) 
    {
      fgets (inputBuf, INPUT_BUF_SIZE, input_F);
      if (feof (input_F))
	return EOF;
      lineNo++;
      inputBufp = inputBuf;
    }
  return *inputBufp++;
}



/*
 * Advance--
 *	Advance to the next token in the input stream and set tokStr,
 * tokType.
 *
 *	On error, tokType is set to a negative value.
 */
static void 
Advance (FILE *input_F)
{
  register char *tok = tokStr;	/* accumulating token string		    */
  register int len = 0;		/* length of current token		    */
  static int c = 32;		/* current character; ' ' is harmless init  */


  /*
   * Skip whitespace in the stream
   */
  while ((c != EOF) && isspace (c))
    c = MyFGetC (input_F);

  /*
   * At end of file?
   */
  if (c == EOF) 
    {
      tokType = EOF;
      strcpy (tokStr, "[EOF]");
      return;
    }

  /*
   * Recognize a number [+|-][dddd][.][dddd][{e|E}[+|-]dddd]
   */
  if (isdigit (c) || (c == '.') || (c == '+') || (c == '-')) 
    {
      register int decPt = FALSE,   /* seen a decimal point yet?	*/
	       hasExp = FALSE;	    /* has an exponent?			*/

      if ((c == '-') || (c == '+')) 
	{
	  *tok++ = c;
	  c = MyFGetC (input_F);
	}

      while ((len < MAX_TOK_LEN - 1) && (isdigit (c) || (c == '.'))) 
	{
	  if (c == '.') 
	    {
	      if (decPt)
		break;
	      else
		decPt = TRUE;
	    }

	  *tok++ = c;
	  c = MyFGetC (input_F);
	  len++;
	}

      if ((c == 'e') || (c == 'E')) 
	{
	  hasExp = TRUE;
	  *tok++ = c;
	  c = MyFGetC (input_F);
	  len++;

	  if ((c == '-') || (c == '+')) 
	    {
	      *tok++ = c;
	      c = MyFGetC (input_F);
	      len++;
	    }

	  while ((len < MAX_TOK_LEN - 1) && isdigit (c)) 
	    {
	      *tok++ = c;
	      c = MyFGetC (input_F);
	      len++;
	    }
	}

      *tok = 0;

      if (decPt || hasExp) 
	{
	  tokType = FLOAT_LIT;
	  yylval.dval = atof (tokStr);
	} 
      else 
	{
	  tokType = INT_LIT;
	  yylval.ival = atoi (tokStr);
	}

      return;

    }

  /*
   * Recognize a quoted string
   */
  if (c == '\"') 
    {

      c = MyFGetC (input_F);

      while ((len < MAX_TOK_LEN - 1) &&
	     (c != EOF) && (c != '\n') && (c != '\"')) 
	{
	  *tok++ = c;
	  c = MyFGetC (input_F);
	}

      *tok = 0;

      c = MyFGetC (input_F);

      tokType = STRING_LIT;
      strncpy (yylval.sval, tokStr, MAX_TOK_LEN - 1);
      yylval.sval[MAX_TOK_LEN - 1] = 0;

      return;

    }

  /*
   * Recognize an identifier and try to match it with a keyword.
   * Identifiers begin with a letter and continue in letters and/or
   * digits.  Convert it to lowercase.
   */
  if (isalpha (c) || (c == '_') || (c == '$')) {

    if (isupper (c))
      c = tolower (c);
    *tok++ = c;
    c = MyFGetC (input_F);
    len++;

    while ((len < MAX_TOK_LEN - 1) && (isalpha (c) || isdigit (c) ||
				       (c == '_') || (c == '$'))) 
      {
	if (isupper (c))
	  c = tolower (c);
	*tok++ = c;
	c = MyFGetC (input_F);
	len++;
      }

    *tok = 0;

    /*
     * We've got the identifier; see if it matches any keywords.
     */

      {
	generic_t gval;
	int type;
	if (St_GetSym (keywordT_P, tokStr, &type, &gval) == ST_SYM_FOUND) 
	  {
	    tokType = gval.i;
	    strncpy (yylval.sval, tokStr, MAX_TOK_LEN - 1);
	    yylval.sval[MAX_TOK_LEN - 1] = 0;
	  } 
	else if (!strcmp (tokStr, "true")) 
	  {
	    tokType = BOOL_LIT;
	    yylval.ival = 1;
	  } 
	else if (!strcmp (tokStr, "false")) 
	  {
	    tokType = BOOL_LIT;
	    yylval.ival = 0;
	  } 
	else 
	  {
	    tokType = IDENTIFIER;
	    strncpy (yylval.sval, tokStr, MAX_TOK_LEN - 1);
	    yylval.sval[MAX_TOK_LEN - 1] = 0;
	  }
      }

    return;

  }

  /*
   * Recognize punctuation
   */

  tokType = c;
  *tok++ = c;
  *tok = 0;
  c = MyFGetC (input_F);
  return;
}

void 
ErrMsg (char *s)
{
  int i;

  fprintf (stderr, "Error: %s at line %d\n", s, lineNo);
  fprintf (stderr, "%s", inputBuf);
  for (i = 0; i < inputBufp - inputBuf; i++) 
    {
      fputc ((inputBuf[i] == '\t' ? '\t' : ' '), stderr);
    }
  fprintf (stderr, "^ before here\n\n");
  return;
}

int 
yyerror (char *s)
{
  ErrMsg (s);
  return 0;
}


int 
yylex ()
{
  Advance (input_F);
  return tokType;
}

unsigned int
lookup_flag (char *kind, char *f)
{
  char *flags;
  generic_t gval;
  int retval = 0;
  char *s;
  int type;
  char s1[256];
  static st_Table_Pt table;
  int negate = 0;

  if (strcmp (kind, "specials") == 0)
    table = specialT_P;
  else if (strcmp (kind, "spells") == 0)
    table = spellsT_P;
  else if (strcmp (kind, "prayers") == 0)
    table = prayersT_P;
  else if (strcmp (kind, "contains") == 0)
    table = containsT_P;
  else if (strcmp (kind, "eatingcauses") == 0)
    table = eatingcausesT_P;
  else
    return -1;

  flags = strdup (f);
  for (s = strtok (flags, ", "); s != NULL; s = strtok (NULL, ", "))
    {
      negate = 0;
      if (s[0] == '~')
	{
	  negate = 1;
	  s++;
	}
      if (St_GetSym (table, s, &type, &gval) != ST_SYM_FOUND) 
	{
	  sprintf (s1, "unknown %s '%s' (in internal code)", kind, s);
	  ErrMsg (s1);
	} 
      else
	{
	  if (negate)
	    retval &= ~(1 << gval.i);
	  else
	    retval |= (1 << gval.i);
	}
    }
  free (flags);
  return retval;
}

void
AddUniqueFunction (char *s)
{
  char s1[256];
  int type;
  generic_t gval;

  if (St_GetSym (uniqfuncT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown unique_function '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      switch (gval.i)
        {
        case UNIQ_CHEST_RUINED:
          if (tmpTemplate.val.tval != TV_CHEST)
            {
              sprintf (s1, "only a chest can be ruined");
              ErrMsg (s1);
              return;
            }
          break;
        case UNIQ_WIZARD_OBJECT:
          if (tmpTemplate.val.tval != TV_NOTHING)
            {
              sprintf (s1, "only a nothing can be a wizard object");
              ErrMsg (s1);
              return;
            }
          break;
        case UNIQ_SCARE_MONSTER:
          if (tmpTemplate.val.tval != TV_VIS_TRAP)
            {
              sprintf (s1, "only a visible trap can scare a monster");
              ErrMsg (s1);
              return;
            }
          break;
        case UNIQ_CREATED_BY_SPELL:
          if (tmpTemplate.val.tval != TV_FOOD)
            {
              sprintf (s1, "only a foodstuff can be created by the "
                           "create_food spell");
              ErrMsg (s1);
              return;
            }
          break;
        default:
          break;
        }
      tmpTemplate.state.unique_function = gval.i;
      tmpTemplate.def.unique_function = TRUE;
    }
  return;
}

char *
argz_copy (char *argz, size_t argz_len)
{
  char *new_argz = NULL;
  size_t new_argz_len = 0;
  char *entry = NULL;
  while ((entry = argz_next (argz, argz_len, entry)))
    argz_add (&new_argz, &new_argz_len, entry);
  return new_argz;
}

void
PutSyllables ()
{
  if (syllables_argz)
    free (syllables_argz);
  syllables_argz = argz_copy (adjective_argz, adjective_argz_len);
  syllables_argz_len = adjective_argz_len;
}

void
PutAdjectives (char *s)
{
  char s1[256];
  int type;
  generic_t gval;
  if (St_GetSym (tvalT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown TVal '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      int found = 0;
      switch (gval.i)
        {
          case TV_POTION1:
            if (potion_adjectives_argz)
              free (potion_adjectives_argz);
            potion_adjectives_argz = argz_copy (adjective_argz, 
                                                adjective_argz_len);
            potion_adjectives_argz_len = adjective_argz_len;
            found = 1;
            break;
          case TV_WAND:
            if (wand_adjectives_argz)
              free (wand_adjectives_argz);
            wand_adjectives_argz = argz_copy (adjective_argz, 
                                              adjective_argz_len);
            wand_adjectives_argz_len = adjective_argz_len;
            found = 1;
            break;
          case TV_AMULET:
            if (amulet_adjectives_argz)
              free (amulet_adjectives_argz);
            amulet_adjectives_argz = argz_copy (adjective_argz,
                                                adjective_argz_len);
            amulet_adjectives_argz_len = adjective_argz_len;
            found = 1;
            break;
          case TV_STAFF:
            if (staff_adjectives_argz)
              free (staff_adjectives_argz);
            staff_adjectives_argz = argz_copy (adjective_argz,
                                               adjective_argz_len);
            staff_adjectives_argz_len = adjective_argz_len;
            found = 1;
            break;
          case TV_RING:
            if (ring_adjectives_argz)
              free (ring_adjectives_argz);
            ring_adjectives_argz = argz_copy (adjective_argz,
                                              adjective_argz_len);
            ring_adjectives_argz_len = adjective_argz_len;
            found = 1;
            break;
          case TV_FOOD:
            if (strcmp (s, "mushroom") != 0)
              found = 0;
            else
              {
                if (mushroom_adjectives_argz)
                  free (mushroom_adjectives_argz);
                mushroom_adjectives_argz = argz_copy (adjective_argz,
                                                      adjective_argz_len);
                mushroom_adjectives_argz_len = adjective_argz_len;
                found = 1;
              }
            break;
          default:
            found = 0;
            break;
        }
      if (!found)
        {
          sprintf (s1, "The `unidentified' keyword cannot be used with '%s' "
                   "objects", s);
          ErrMsg (s1);
        }
      else
        {
          free (adjective_argz);
          adjective_argz = NULL;
          adjective_argz_len = 0;
        }
    }
  return;
}

void
show_adjective_list (char *argz, size_t argz_len, FILE *stream)
{
  size_t length = 0;
  char *entry = NULL;
  int first = 1;
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      length += strlen (entry) + 4;
      if (length > 80)
        {
          length = strlen (entry) + 4;
          first = 1;
          fprintf (stream, "\n");
        }
      if (first)
        {
          fprintf (stream, "  ");
          first = 0;
          length += 2;
        }
      fprintf (stream, "\"%s\", ", entry);
    }
}

void
AddAdjective (char *s)
{
  argz_add (&adjective_argz, &adjective_argz_len, s);
  return;
}

void
AddTVal (char *s)
{
  char s1[256];
  int type;
  generic_t gval;

  if (St_GetSym (tvalT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown TVal '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.tval = gval.i;
      tmpTemplate.def.tval = TRUE;
      if (strcmp (s, "mushroom") == 0)
        {
          tmpTemplate.state.mushroom_flag = 1;
          tmpTemplate.def.mushroom_flag = TRUE;
        }
    }
  return;
}

void 
AddContainsFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (tmpTemplate.val.tval != TV_CHEST)
  {
      sprintf (s1, "this kind of object can't contain things");
      ErrMsg (s1);
      return;
  }
  if (St_GetSym (containsT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown container flag '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      tmpTemplate.val.flags |= (1 << gval.i);
      tmpTemplate.def.special = TRUE;
    }
  return;
}


void 
NegContainsFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (tmpTemplate.val.tval != TV_CHEST)
  {
      sprintf (s1, "this kind of object can't contain things");
      ErrMsg (s1);
      return;
  }
  if (St_GetSym (containsT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown container flag '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      tmpTemplate.val.flags &= ~(1 << gval.i);
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void AddSpecial(char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (specialT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown special '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.flags |= (1 << gval.i);
      tmpTemplate.def.special = TRUE;
    }
  return;
}
void
NegSpecial (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (specialT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown special '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.flags &= ~(1 << gval.i);
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void AddBuyableFlag(char *s, int freq)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (buyableT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown buyable flag '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      if (gval.i == 6) 
	{
	  /* not found in the dungeon, only in stores */
	  tmpTemplate.state.store_only = 1;
	  tmpTemplate.def.store_only = TRUE;
	}
      else
	{
	  tmpTemplate.state.buyable_freq[gval.i] = freq;
	  tmpTemplate.state.buyable |= (1 << gval.i);
	  tmpTemplate.def.buyable = TRUE;
	}
    }
  return;
}

void AddRelativeSubval(int id)
{
  tmpTemplate.state.stackable_id = id;
  tmpTemplate.def.stackable_id = TRUE;
}

void AddStackableFlag(char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (stackableT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown stackable flag '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.state.stackable |= (1 << gval.i);
      tmpTemplate.def.stackable = TRUE;
    }
  return;
}
void
NegStackableFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (stackableT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown stackable flag '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.state.stackable &= ~(1 << gval.i);
      tmpTemplate.def.stackable = TRUE;
    }
  return;
}

void AddSpell(char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (tmpTemplate.val.tval != TV_MAGIC_BOOK)
    {
      sprintf (s1, "This kind of object cannot contain spells");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (spellsT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown spell '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.flags |= (1 << gval.i);
      tmpTemplate.val.spells[gval.i] = 1;
      tmpTemplate.def.special = TRUE;
    }
  return;
}
void
NegSpell (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (tmpTemplate.val.tval != TV_MAGIC_BOOK)
    {
      sprintf (s1, "This kind of object cannot contain spells");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (spellsT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown spell '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.flags &= ~(1 << gval.i);
      tmpTemplate.def.special = TRUE;
    }
  return;
}


void AddPrayer (char *s)
{
  generic_t gval;
  int type;
  char s1[256];
  if (tmpTemplate.val.tval != TV_PRAYER_BOOK)
    {
      sprintf (s1, "This kind of object cannot contain prayers");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (prayersT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown prayer '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.flags |= (1 << gval.i);
      tmpTemplate.val.spells[gval.i] = 1;
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void
NegPrayer (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (tmpTemplate.val.tval != TV_PRAYER_BOOK)
    {
      sprintf (s1, "This kind of object cannot contain prayers");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (prayersT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown prayer '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.flags &= ~(1 << gval.i);
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void AddEatingFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];
  if (tmpTemplate.val.tval != TV_FOOD)
    {
      sprintf (s1, "This kind of object cannot have eating effects "
                   "because it's not edible.");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (eatingcausesT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown eating effect '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.flags |= (1 << gval.i);
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void
NegEatingFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (tmpTemplate.val.tval != TV_FOOD)
    {
      sprintf (s1, "This kind of object cannot have eating effects "
                   "because it's not edible.");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (eatingcausesT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown eating effect '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.flags &= ~(1 << gval.i);
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void AddPotionFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];
  if (tmpTemplate.val.tval != TV_POTION1)
    {
      sprintf (s1, "This kind of object cannot have potion effects "
                   "because it's not of type POTION");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (potion1causesT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      if (St_GetSym (potion2causesT_P, s, &type, &gval) != ST_SYM_FOUND)
        {
          sprintf (s1, "unknown potion effect '%s'", s);
          ErrMsg (s1);
        }
      else
       {
          tmpTemplate.val.flags |= (1 << gval.i);
          tmpTemplate.def.special = TRUE;
          tmpTemplate.val.tval = TV_POTION2;
       }
    }
  else
    {
      tmpTemplate.val.flags |= (1 << gval.i);
      tmpTemplate.def.special = TRUE;
      tmpTemplate.val.tval = TV_POTION1;
    }
  return;
}

void
NegPotionFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (tmpTemplate.val.tval != TV_POTION1)
    {
      sprintf (s1, "This kind of object cannot have potion effects "
                   "because it's not of type POTION.");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (potion1causesT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      if (St_GetSym (potion2causesT_P, s, &type, &gval) != ST_SYM_FOUND)
        {
          sprintf (s1, "unknown potion effect '%s'", s);
          ErrMsg (s1);
        }
      else
       {
          tmpTemplate.val.flags &= ~(1 << gval.i);
          tmpTemplate.def.special = TRUE;
       }
    }
  else
    {
      tmpTemplate.val.flags &= ~(1 << gval.i);
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void AddScrollFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];
  if (tmpTemplate.val.tval != TV_SCROLL)
    {
      sprintf (s1, "This kind of object cannot have scroll effects "
                   "because it's not of type SCROLL.");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (scrollcausesT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown scroll effect '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.effect_idx = gval.i;
      tmpTemplate.def.special = TRUE;
      tmpTemplate.val.tval = TV_SCROLL;
    }
  return;
}

void
NegScrollFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (tmpTemplate.val.tval != TV_SCROLL)
    {
      sprintf (s1, "This kind of object cannot have scroll effects "
                   "because it's not of type SCROLL.");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (scrollcausesT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown scroll effect '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.effect_idx = 0;
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void AddStaffFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];
  if (tmpTemplate.val.tval != TV_STAFF)
    {
      sprintf (s1, "This kind of object cannot have staff effects "
                   "because it's not of type STAFF.");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (staffcausesT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown staff effect '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.effect_idx = gval.i;
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void
NegStaffFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (tmpTemplate.val.tval != TV_STAFF)
    {
      sprintf (s1, "This kind of object cannot have staff effects "
                   "because it's not of type STAFF.");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (staffcausesT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown staff effect '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.effect_idx = 0;
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void AddWandFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];
  if (tmpTemplate.val.tval != TV_WAND)
    {
      sprintf (s1, "This kind of object cannot have wand effects "
                   "because it's not of type WAND.");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (wandcausesT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown wand effect '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.effect_idx = gval.i;
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void
NegWandFlag (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (tmpTemplate.val.tval != TV_WAND)
    {
      sprintf (s1, "This kind of object cannot have wand effects "
                   "because it's not of type WAND.");
      ErrMsg (s1);
      return;
    }
  if (St_GetSym (wandcausesT_P, s, &type, &gval) != ST_SYM_FOUND)
    {
      sprintf (s1, "unknown wand effect '%s'", s);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.effect_idx = 0;
      tmpTemplate.def.special = TRUE;
    }
  return;
}

st_Table_Pt 
InitTable (char *name, symInit_t *init)
{
  int i;
  st_Table_Pt table_P;
  generic_t gval;

  table_P = St_NewTable (name, 20);
  for (i = 0; init[i].name; i++) 
    {
      gval.i = init[i].val;
      St_DefSym (table_P, init[i].name, GEN_TYPE_INT, gval);
    }

  return table_P;
}


void 
InitTables ()
{
  keywordT_P = InitTable ("keyword", keywordInit);
  specialT_P = InitTable ("specials", specialInit);
  uniqfuncT_P = InitTable ("unique_functions", uniqfuncInit);
  spellsT_P = InitTable ("spells", spellsInit);
  containsT_P = InitTable ("contains", containsInit);
  prayersT_P = InitTable ("prayers", prayersInit);
  eatingcausesT_P = InitTable ("eatingcauses", eatingcausesInit);
  potion1causesT_P = InitTable ("potion1causes", potion1causesInit);
  potion2causesT_P = InitTable ("potion2causes", potion2causesInit);
  scrollcausesT_P = InitTable ("scrollcauses", scrollcausesInit);
  staffcausesT_P = InitTable ("staffcauses", staffcausesInit);
  wandcausesT_P = InitTable ("wandcauses", wandcausesInit);
  tvalT_P = InitTable ("tvals", tvalInit);
  stackableT_P = InitTable ("stackable", stackableInit);
  buyableT_P = InitTable ("buyable", buyableInit);

  classT_P = St_NewTable ("class", 100);
  treasureT_P = St_NewTable ("treasure", 500);
  sortedtreasureT_P = St_NewTable ("sorted treasure", 500);

  return;
}

/* determine the correct TV_flag for this tval */
char *
getTValString (int tval)
{
  char *s = NULL;
  symInit_t *t;
  for (t  = &tvalInit[0]; t->name != NULL; t++)
    {
      if (tval == t->val)
        {
          char *letter;
          s = xasprintf("tv_%s", t->name);
          if (s)
            {
              for (letter = &s[0]; *letter != '\0'; letter++)
                {
                  *letter = toupper (*letter);
                }
              return s;
            }
        }
    }
  return NULL;
}

void 
WriteTreasure (sorted_template_t *tmpl_P, int count)
{
  char *tval;
  char s[256];
  strcpy (s, "\"");
  strcat (s, tmpl_P->val.name);
  strcat (s, "\"");            
  tval = getTValString (tmpl_P->val.tval);
  fprintf (arguments.tc.outfile, 
           "{%-31s,0x%08XL, %4u, %10s, '%s%c',\t/*%3d*/\n",
	   s, (unsigned int) tmpl_P->val.flags, tmpl_P->val.effect_idx, tval, tmpl_P->val.tchar == '\'' || tmpl_P->val.tchar == '\\' ? "\\" :"", tmpl_P->val.tchar, count);
  free (tval);
  fprintf (arguments.tc.outfile, 
	   "%5d,\t%4d,\t%2d,%4u,%4d,\t%1d,%4d,%3d,%4d, {%d,%d}%s,%3d",
           tmpl_P->val.p1, tmpl_P->val.cost, tmpl_P->val.subval, 
           tmpl_P->val.number, tmpl_P->val.weight, tmpl_P->val.tohit, 
           tmpl_P->val.todam, tmpl_P->val.ac, tmpl_P->val.toac, 
           tmpl_P->val.damage[0], tmpl_P->val.damage[1],
           (tmpl_P->val.damage[0] > 9 && tmpl_P->val.damage[1] > 9) ? "":"\t",
	   tmpl_P->val.level);
  if (tmpl_P->val.tval == TV_MAGIC_BOOK || tmpl_P->val.tval == TV_PRAYER_BOOK)
    {
      int i;
      fprintf (arguments.tc.outfile, ",\n  {");
      for (i = 0; i < MAX_SPELLS; i++)
        {
          fprintf (arguments.tc.outfile, "%d", tmpl_P->val.spells[i]);
          if (i != MAX_SPELLS - 1)
            fprintf (arguments.tc.outfile, ",");
        }
      fprintf (arguments.tc.outfile, "}},\n");
    }
  else
    fprintf (arguments.tc.outfile, "},\n");
  return;
}

void
AddSortedTreasure (template_t *t)
{
  generic_t gval;
  sorted_template_t *s;
  gval.v = malloc (sizeof (sorted_template_t));
  s = (sorted_template_t *) gval.v;
  memset (s, 0, sizeof (sorted_template_t));
  s->id = t->id;
  s->state = t->state;
  s->val = t->val;
  s->def = t->def;
  St_DefSym (sortedtreasureT_P, s->id, GEN_TYPE_TMPL, gval);
  return;
}

void 
SortTreasuresBy (int store, int tval)
{
  char *entry = NULL;
  char *argz = NULL;
  size_t argz_len = 0;
  int type;
  generic_t gval;
  template_t *t;
  St_SArgzTable (treasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (treasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in SortTreasuresBy\n");
          exit (1);
        }
      t = (template_t *) gval.v;
      if (t->state.store_only == store && t->val.tval == tval &&
          t->def.unique_function == FALSE)
        {
          AddSortedTreasure (t);
        }
    }
  free (argz);
}

void 
SortUniqueFunctionTreasure (int uniqfunc)
{
  char *entry = NULL;
  char *argz = NULL;
  size_t argz_len = 0;
  int type;
  generic_t gval;
  template_t *t;
  St_SArgzTable (treasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (treasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in SortUniqueFunctionTreasure\n");
          exit (1);
        }
      t = (template_t *) gval.v;
      if (t->state.unique_function == uniqfunc && 
          t->def.unique_function == TRUE)
        {
          AddSortedTreasure (t);
        }
    }
  free (argz);
}

/* Go to great lengths to order the object_list array in the same fashion
 * as the existing treasures.c file. */
void
SortTreasures ()
{
  int i;
  int not_in_stores_tvals[] = 
    {
      TV_FOOD, TV_SWORD, TV_HAFTED, TV_POLEARM, TV_BOW, TV_ARROW, TV_BOLT,
      TV_SLING_AMMO, TV_SPIKE, TV_LIGHT, TV_DIGGING, TV_BOOTS, TV_HELM,
      TV_SOFT_ARMOR, TV_HARD_ARMOR, TV_CLOAK, TV_GLOVES, TV_SHIELD, TV_RING, 
      TV_AMULET, TV_SCROLL, TV_POTION1, TV_POTION2, TV_FLASK, 
      TV_WAND, TV_STAFF, TV_MAGIC_BOOK, TV_PRAYER_BOOK, TV_CHEST, TV_MISC
    };
  int in_stores_tvals[] =
    {
      TV_FOOD, TV_SWORD, TV_HAFTED, TV_POLEARM, TV_BOW, TV_ARROW, TV_BOLT,
      TV_SLING_AMMO, TV_SPIKE, TV_DIGGING, TV_BOOTS, TV_HELM, TV_SOFT_ARMOR,
      TV_HARD_ARMOR, TV_CLOAK, TV_GLOVES, TV_SHIELD, TV_RING, TV_AMULET,
      TV_SCROLL, TV_POTION1, TV_POTION2, TV_LIGHT, TV_FLASK,
      TV_WAND, TV_STAFF, TV_MAGIC_BOOK, TV_PRAYER_BOOK, TV_CHEST, TV_MISC
    };
  int terrain_tvals[] =
   {
     TV_OPEN_DOOR, TV_CLOSED_DOOR, TV_SECRET_DOOR, TV_UP_STAIR, 
     TV_DOWN_STAIR, TV_STORE_DOOR, TV_VIS_TRAP, TV_INVIS_TRAP, TV_RUBBLE
   };
  
  for (i = 0; i < sizeof (not_in_stores_tvals) / sizeof (int); i++)
    SortTreasuresBy (!SOLD_IN_STORES, not_in_stores_tvals[i]);

  for (i = 0; i < sizeof (in_stores_tvals) / sizeof (int); i++)
    SortTreasuresBy (SOLD_IN_STORES, in_stores_tvals[i]);

  for (i = 0; i < sizeof (terrain_tvals) / sizeof (int); i++)
    SortTreasuresBy (!SOLD_IN_STORES, terrain_tvals[i]);

  SortUniqueFunctionTreasure (UNIQ_CREATED_BY_SPELL);
  SortUniqueFunctionTreasure (UNIQ_SCARE_MONSTER);
  SortTreasuresBy (!SOLD_IN_STORES, TV_GOLD);
  SortUniqueFunctionTreasure (UNIQ_INVENTORY_OBJECT);
  SortUniqueFunctionTreasure (UNIQ_CHEST_RUINED);
  SortUniqueFunctionTreasure (UNIQ_WIZARD_OBJECT);
}

void 
WriteTreasures ()
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  generic_t gval;
  int count = 0;

  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);

  fprintf (arguments.tc.outfile, "treasure_type object_list[MAX_OBJECTS] = {\n");
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in WriteTreasures\n");
          exit (1);
        }
      WriteTreasure ((sorted_template_t *) gval.v, count);
      count++;
    }

  fprintf (arguments.tc.outfile, "};\n\n");

  free (argz);
  return;
}

void 
oldWriteTreasures ()
{
  char **s_A, **sp;
  int type;
  generic_t gval;
  int count = 0;

  s_A = St_SListTable (sortedtreasureT_P);

  fprintf (arguments.tc.outfile, "treasure_type object_list[MAX_OBJECTS] = {\n");

  for (sp = s_A; *sp; sp++) 
    {
      if (St_GetSym (sortedtreasureT_P, *sp, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in WriteTreasures\n");
          exit (1);
        }
      WriteTreasure ((sorted_template_t *) gval.v, count);
      count++;
    }

  fprintf (arguments.tc.outfile, "};\n\n");

  St_SListTable (NULL);
  return;
}


void 
PutClassTemplate (char *s, template_t *tmpl_P)
{
  generic_t gval;
  char s1[256];

  gval.v = malloc (sizeof(template_t));
  *(template_t *) gval.v = *tmpl_P;

  if (St_DefSym (classT_P, s, GEN_TYPE_TMPL, gval) == ST_SYM_FOUND) 
    {
      sprintf (s1, "attempt to redefine class '%s'", s);
      ErrMsg (s1);
      free (gval.v);
      return;
    }
  return;
}


int
MergeClassTemplate (char *s, template_t *t1)
{
  template_t t2;
  t2 = GetClassTemplate (s);
  if (t2.def.special == TRUE)
    {
      t1->val.flags |= (t2.val.flags);
      t1->val.effect_idx = t2.val.effect_idx;
      t1->def.special = TRUE;
    }
  if (t2.def.damage == TRUE)
    {
      t1->val.damage[0] = t2.val.damage[0];
      t1->val.damage[1] = t2.val.damage[1];
      t1->def.damage = TRUE;
    }
  if (t2.def.cost == TRUE)
    {
      t1->val.cost = t2.val.cost;
      t1->def.cost = TRUE;
    }
  if (t2.def.subval == TRUE)
    {
      t1->val.subval = t2.val.subval;
      t1->def.subval = TRUE;
    }
  if (t2.def.weight == TRUE)
    {
      t1->val.weight = t2.val.weight;
      t1->def.weight = TRUE;
    }
  if (t2.def.number == TRUE)
    {
      t1->val.number = t2.val.number;
      t1->def.number = TRUE;
    }
  if (t2.def.tohit == TRUE)
    {
      t1->val.tohit = t2.val.tohit;
      t1->def.tohit = TRUE;
    }
  if (t2.def.todam == TRUE)
    {
      t1->val.todam = t2.val.todam;
      t1->def.todam = TRUE;
    }
  if (t2.def.toac == TRUE)
    {
      t1->val.toac = t2.val.toac;
      t1->def.toac = TRUE;
    }
  if (t2.def.ac == TRUE)
    {
      t1->val.ac = t2.val.ac;
      t1->def.ac = TRUE;
    }
  if (t2.def.p1 == TRUE)
    {
      t1->val.p1 = t2.val.p1;
      t1->def.p1 = TRUE;
    }
  if (t2.def.tchar == TRUE)
    {
      t1->val.tchar = t2.val.tchar;
      t1->def.tchar = TRUE;
    }
  if (t2.def.level == TRUE)
    {
      t1->val.level = t2.val.level;
      t1->def.level = TRUE;
    }
  if (t2.def.tval == TRUE)
    {
      t1->val.tval = t2.val.tval;
      t1->def.tval = TRUE;
    }
  if (t2.def.stackable == TRUE)
    {
      t1->state.stackable |= (t2.state.stackable);
      t1->def.stackable = TRUE;
    }
  if (t2.def.mushroom_flag == TRUE)
    {
      t1->state.mushroom_flag = t2.state.mushroom_flag;
      t1->def.mushroom_flag = TRUE;
    }
  if (t2.def.stackable_id == TRUE)
    {
      t1->state.stackable_id = t2.state.stackable_id;
      t1->def.stackable_id = TRUE;
    }
  if (t2.def.unique_function == TRUE)
    {
      t1->state.unique_function |= t2.state.unique_function;
      t1->def.unique_function = TRUE;
    }
  if (t2.def.store_only == TRUE)
    {
      t1->state.store_only = t2.state.store_only;
      t1->def.store_only = TRUE;
    }
  if (t2.def.buyable == TRUE)
    {
      int i;
      t1->state.buyable |= t2.state.buyable;
      for (i = 0; i < MAX_STORES; i++)
	t1->state.buyable_freq[i] += t2.state.buyable_freq[i];
      t1->def.buyable = TRUE;
    }

  return 0;
}

template_t 
GetClassTemplate (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (classT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "class '%s' undefined\n", s);
      ErrMsg (s1);
      return blankTemplate;
    } 
  else 
    {
      return *(template_t *) gval.v;
    }
  return blankTemplate;
}


void 
NotDefined(char *name, char *s)
{
  fprintf (stderr, "Warning: %s not defined for \"%s\", line %d\n",
	   s, name, lineNo);
  return;
}


void 
PutTreasure (char *s, template_t *tmpl_P, int consistency_check)
{
  generic_t gval;

  gval.v = malloc (sizeof(template_t));
  *(template_t *) gval.v = *tmpl_P;

  if (!tmpl_P->def.tval)
    NotDefined (tmpl_P->val.name, "TVAL");
  if (!tmpl_P->def.tchar)
    NotDefined (tmpl_P->val.name, "TCHAR");
  if (!tmpl_P->def.p1)
    NotDefined (tmpl_P->val.name, "P1");
  if (!tmpl_P->def.cost)
    NotDefined (tmpl_P->val.name, "COST");
  if (!tmpl_P->def.number)
    NotDefined (tmpl_P->val.name, "QUANTITY");
  if (!tmpl_P->def.weight)
    NotDefined (tmpl_P->val.name, "WEIGHT");
  if (!tmpl_P->def.tohit)
    NotDefined (tmpl_P->val.name, "TO_HIT");
  if (!tmpl_P->def.todam)
    NotDefined (tmpl_P->val.name, "TO_DAM");
  if (!tmpl_P->def.ac)
    NotDefined (tmpl_P->val.name, "AC");
  if (!tmpl_P->def.toac)
    NotDefined (tmpl_P->val.name, "TO_AC");
  if (!tmpl_P->def.damage)
    NotDefined (tmpl_P->val.name, "DAMAGE");
  if (!tmpl_P->def.level)
    NotDefined (tmpl_P->val.name, "LEVEL");
  if (!tmpl_P->def.stackable)
    NotDefined (tmpl_P->val.name, "STACKABLE");
  if (tmpl_P->val.tval == TV_STAFF && !tmpl_P->def.special)
    NotDefined (tmpl_P->val.name, "STAFF_CASTS");
  if (tmpl_P->val.tval == TV_SCROLL && !tmpl_P->def.special)
    NotDefined (tmpl_P->val.name, "SCROLL_CASTS");
  if (tmpl_P->val.tval == TV_WAND && !tmpl_P->def.special)
    NotDefined (tmpl_P->val.name, "WAND_CASTS");

  if (consistency_check)
    ConsistencyCheckTreasure (&tmpl_P->val, &tmpl_P->state);

  if (St_DefSym (treasureT_P, s, GEN_TYPE_TMPL, gval) == ST_SYM_FOUND) 
    {
      fprintf (arguments.tc.outfile, "Warning: redefining \"%s\", line %d\n", 
               tmpl_P->val.name, lineNo);
    }

  return;
}

int
get_max_dungeon_obj ()
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  generic_t gval;
  sorted_template_t *t;
  int retval = -1;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in get_max_dungeon_obj\n");
          exit (1);
        }
      t = (sorted_template_t *) gval.v;
      if (t->state.store_only)
        {
	  retval = atoi (t->id) - 1;
          break;
        }
    }
  free (argz);
  return retval;
}

int
count_specific_store_choices (int store)
{
  char *argz = NULL;
  size_t argz_len = 0;
  int count = 0;
  int type;
  char *entry = NULL;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err in count_specific_store_choices\n");
          exit (1);
        }
      t = (sorted_template_t *) gval.v;
      count += t->state.buyable_freq[store];
    }
  return count;
}

int
count_store_choices(int bail)
{
  int store_choices[MAX_STORES];
  int i;
  int warn = 0;
  memset (store_choices, 0, sizeof (store_choices));
  for (i = 0; i < MAX_STORES; i++)
    {
      store_choices[i] = count_specific_store_choices (i);
      if (i > 0)
	{
	  if (store_choices[i] != store_choices[i-1])
	    warn = 1;
	}
    }
  if (warn && bail)
    {
      fprintf(stderr, "Error: There must be an equal number of "
	      "choices per store!\n");
      for (i = 0; i < MAX_STORES; i++)
	{
	  fprintf (stderr, "\tStore `%d': %d choices\n", i + 1, 
		   store_choices[i]);
	}
      exit(1);
    }
  return store_choices[0];
}

int
count_obj_with_tval_and_subvals (int tval, int subval)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int count = 0;
  int type;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err in count_obj_with_tval_and_subvals\n");
          exit (1);
        }
      t = (sorted_template_t *) gval.v;
      if (t->val.tval == tval && t->val.subval == subval)
	count++;
    }
  free (argz);
  return count;
}

int
count_obj_with_tval (int tval)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int count = 0;
  int type;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in count_obj_with_tval\n");
          exit (1);
        }
      t = (sorted_template_t *) gval.v;
      if (t->val.tval == tval)
        count++;
    }
  free (argz);
  return count;
}

int
get_obj_with_tval (int tval)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int retval = -1;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in get_obj_with_tval\n");
          exit (1);
        }
      t = (sorted_template_t *) gval.v;
      if (t->val.tval == tval)
        {
	  retval = atoi (t->id);
          break;
        }
    }
  free (argz);
  return retval;
}

int
get_obj_with_uniq (int uniq)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int retval = -1;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in get_obj_with_uniq\n");
          exit (1);
        }
      t = (sorted_template_t *) gval.v;
      if (t->state.unique_function == uniq && t->def.unique_function == TRUE)
        {
	  retval = atoi (t->id);
          break;
        }
    }
  return retval;
}

int
get_subval_with_uniq (int uniq)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int retval = -1;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in get_obj_with_uniq\n");
          exit (1);
        }
      t = (sorted_template_t *) gval.v;
      if (t->state.unique_function == uniq && t->def.unique_function == TRUE)
        {
	  retval = t->val.subval;
          break;
        }
    }
  return retval;
}

int get_highest_subval_of_obj_with_tval (int tval)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int max = 0;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in "
		   "get_highest_subval_of_obj_with_tval\n");
          exit (1);
        }
      t = (sorted_template_t *) gval.v;
      if (t->val.tval != tval)
	continue;

      if (t->val.subval > max)
	max = t->val.subval;
    }
  return max;
}

int get_lowest_subval_of_obj_with_tval (int tval)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int min = -1;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in "
		   "get_lowest_subval_of_obj_with_tval\n");
          exit (1);
        }
      t = (sorted_template_t *) gval.v;
      if (t->val.tval != tval)
	continue;

      if (t->val.subval < min || min == -1)
	min = t->val.subval;
    }
  if (min == -1)
    min = 0;
  return min;
}

void
get_min_and_max_mushies (int *low, int *high)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int min = -1;
  int max = 0;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in "
		   "get_lowest_subval_of_obj_with_tval\n");
          exit (1);
        }
      t = (sorted_template_t *) gval.v;
      if (t->state.mushroom_flag == 0)
	continue;

      if (t->val.subval < min || min == -1)
	min = t->val.subval;
      if (t->val.subval > max)
	max = t->val.subval;
    }
  if (min == -1)
    min = 0;
  *low = min;
  *high = max;
  return;
}

int
count_mushies()
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int count = 0;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in "
		   "get_lowest_subval_of_obj_with_tval\n");
          exit (1);
        }
      t = (sorted_template_t *) gval.v;
      if (t->state.mushroom_flag)
	count++;
    }
  return count;
}

void 
WriteConstants (int never_min, int never_max, int single_min, int single_max,
		int group_min, int group_max)
{
  int scare_monster;
  int val;
  fprintf (arguments.tc.outfile,
	   "\n#define MAX_OBJECTS\t\t%d\n", St_TableSize (sortedtreasureT_P));
  int max_dungeon_obj = get_max_dungeon_obj ();
  if (max_dungeon_obj > 0)
    fprintf (arguments.tc.outfile, "#define MAX_DUNGEON_OBJ\t\t%d\n", 
	     max_dungeon_obj);
  if ((val = get_obj_with_tval (TV_OPEN_DOOR)) != -1)
    fprintf (arguments.tc.outfile,
	     "#define OBJ_OPEN_DOOR\t\t%d\n", val);
  if ((val = get_obj_with_tval (TV_CLOSED_DOOR)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_CLOSED_DOOR\t\t%d\n", val);
  if ((val = get_obj_with_tval (TV_SECRET_DOOR)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_SECRET_DOOR\t\t%d\n", val);
  if ((val = get_obj_with_tval (TV_UP_STAIR)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_UP_STAIR\t\t%d\n", val);
  if ((val = get_obj_with_tval (TV_DOWN_STAIR)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_DOWN_STAIR\t\t%d\n", val);
  if ((val = get_obj_with_tval (TV_STORE_DOOR)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_STORE_DOOR\t\t%d\n", val);
  if ((val = get_obj_with_tval (TV_VIS_TRAP)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_TRAP_LIST\t\t%d\n", val);
  if ((val = get_obj_with_tval (TV_RUBBLE)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_RUBBLE\t\t%d\n", val);
  if ((val = get_obj_with_uniq (UNIQ_CREATED_BY_SPELL)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_MUSH\t\t%d\n", val);
  if ((val = get_obj_with_uniq (UNIQ_SCARE_MONSTER)) != -1)
    {
      fprintf (arguments.tc.outfile, "#define OBJ_SCARE_MON\t\t%d\n", val);
      int subval;
      if ((subval = get_subval_with_uniq (UNIQ_SCARE_MONSTER)) != -1)
	fprintf (arguments.tc.outfile, "#define SCARE_MONSTER\t\t%d\n", subval);
      scare_monster = 1;
    }
  if ((val = get_obj_with_tval (TV_GOLD)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_GOLD_LIST\t\t%d\n", val);
  if ((val = get_obj_with_tval (TV_NOTHING)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_NOTHING\t\t%d\n", val);
  if ((val = get_obj_with_uniq (UNIQ_CHEST_RUINED)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_RUINED_CHEST\t%d\n", val);
  if ((val = get_obj_with_uniq (UNIQ_WIZARD_OBJECT)) != -1)
    fprintf (arguments.tc.outfile, "#define OBJ_WIZARD\t\t%d\n", val);
  if (single_min > 0)
    {
      fprintf (arguments.tc.outfile, "#define OBJECT_IDENT_SIZE\t%d\n", 
	       7 * single_min);
      fprintf (arguments.tc.outfile, 
	       "/* bit shift object ident indexes by %d bits in desc.c */\n", 
	       (int) log2 (single_min));
    }
  if (get_obj_with_tval (TV_GOLD) != -1)
    fprintf (arguments.tc.outfile, "#define MAX_GOLD\t\t%d\n", 
	     count_obj_with_tval (TV_GOLD));
  if (potion_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "#define MAX_COLORS\t\t%d\n", 
	       argz_count (potion_adjectives_argz, potion_adjectives_argz_len));
      //do we have enough?
      int max_subval = get_highest_subval_of_obj_with_tval (TV_POTION1);
      int max = max_subval;
      max_subval = get_highest_subval_of_obj_with_tval (TV_POTION2);
      if (max_subval > max)
	max = max_subval;
      int min_subval = get_lowest_subval_of_obj_with_tval (TV_POTION1);
      int min = min_subval;
      min_subval = get_lowest_subval_of_obj_with_tval (TV_POTION2);
      if (min_subval > max)
	min = max_subval;
      if  (potion_adjectives_argz_len < (max - min + 1) && max)
	{
	  fprintf (stderr, "Error: %d potion adjectives are required in "
		   "the `unidentified POTION' section, but only "
		   "%d are given\n", max - min + 1, 
		   argz_count (potion_adjectives_argz, 
			       potion_adjectives_argz_len));
	  exit (1);
	}
    }
  else if (count_obj_with_tval (TV_POTION1) || count_obj_with_tval (TV_POTION2))
    {
      fprintf (stderr, "Warning: potions identified, but no `unidentified "
	       "POTION' section declared");
    }

  if (mushroom_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "#define MAX_MUSH\t\t%d\n", 
	       argz_count (mushroom_adjectives_argz, 
			   mushroom_adjectives_argz_len));
      int min, max;
      get_min_and_max_mushies (&min, &max);
      if  (mushroom_adjectives_argz_len < (max - min + 1) && max)
	{
	  fprintf (stderr, "Error: %d mushroom adjectives are required in "
		   "the `unidentified MUSHROOM' section, but only "
		   "%d are given\n", max - min + 1, 
		   argz_count (mushroom_adjectives_argz, 
			       mushroom_adjectives_argz_len));
	  exit (1);
	}
      else if (argz_count (mushroom_adjectives_argz,
			   mushroom_adjectives_argz_len) != 
	       (max - min + 1) + 1 && max)
	{
	  fprintf (stderr, "Error: exactly %d mushroom adjectives are "
		   "required in the `unidentified MUSHROOM' section, but "
		   "%d are given\n", max ? max - min + 1 + 1 : 0, 
		   argz_count (mushroom_adjectives_argz, 
			       mushroom_adjectives_argz_len));
	  exit (1);
	}
    }
  else if (count_mushies())
    {
      fprintf (stderr, "Warning: mushrooms identified, but no `unidentified "
	       "MUSHROOM' section declared");
    }

  if (staff_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "#define MAX_WOODS\t\t%d\n", 
	       argz_count (staff_adjectives_argz, staff_adjectives_argz_len));
      //do we have enough?
      int max_subval = get_highest_subval_of_obj_with_tval (TV_STAFF);
      int max = max_subval;
      int min_subval = get_lowest_subval_of_obj_with_tval (TV_STAFF);
      int min = min_subval;
      if  (staff_adjectives_argz_len < (max - min + 1) && max)
	{
	  fprintf (stderr, "Error: %d staff adjectives are required in "
		   "the `unidentified STAFF' section, but only "
		   "%d are given\n", max - min + 1, 
		   argz_count (staff_adjectives_argz, 
			       staff_adjectives_argz_len));
	  exit (1);
	}
    }
  else if (count_obj_with_tval (TV_STAFF))
    {
      fprintf (stderr, "Warning: staves identified, but no `unidentified "
	       "STAFF' section declared");
    }
  if (wand_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "#define MAX_METALS\t\t%d\n", 
	       argz_count (wand_adjectives_argz, wand_adjectives_argz_len));
      //do we have enough?
      int max_subval = get_highest_subval_of_obj_with_tval (TV_WAND);
      int max = max_subval;
      int min_subval = get_lowest_subval_of_obj_with_tval (TV_WAND);
      int min = min_subval;
      if  (wand_adjectives_argz_len < (max - min + 1) && max)
	{
	  fprintf (stderr, "Error: %d wand adjectives are required in "
		   "the `unidentified WAND' section, but only "
		   "%d are given\n", max - min + 1, 
		   argz_count (wand_adjectives_argz, 
			       wand_adjectives_argz_len));
	  exit (1);
	}
    }
  else if (count_obj_with_tval (TV_WAND))
    {
      fprintf (stderr, "Warning: wands identified, but no `unidentified "
	       "WAND' section declared");
    }
  if (ring_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "#define MAX_ROCKS\t\t%d\n", 
	       argz_count (ring_adjectives_argz, ring_adjectives_argz_len));
      //do we have enough?
      int max_subval = get_highest_subval_of_obj_with_tval (TV_RING);
      int max = max_subval;
      int min_subval = get_lowest_subval_of_obj_with_tval (TV_RING);
      int min = min_subval;
      if  (ring_adjectives_argz_len < (max - min + 1) && max)
	{
	  fprintf (stderr, "Error: %d ring adjectives are required in "
		   "the `unidentified RING' section, but only "
		   "%d are given\n", max - min + 1, 
		   argz_count (ring_adjectives_argz, 
			       ring_adjectives_argz_len));
	  exit (1);
	}
    }
  else if (count_obj_with_tval (TV_RING))
    {
      fprintf (stderr, "Warning: rings identified, but no `unidentified "
	       "RING' section declared");
    }
  if (amulet_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "#define MAX_AMULETS\t\t%d\n", 
	       argz_count (amulet_adjectives_argz, amulet_adjectives_argz_len));
      //do we have enough?
      int max_subval = get_highest_subval_of_obj_with_tval (TV_AMULET);
      int max = max_subval;
      int min_subval = get_lowest_subval_of_obj_with_tval (TV_AMULET);
      int min = min_subval;
      if  (amulet_adjectives_argz_len < (max - min + 1) && max)
	{
	  fprintf (stderr, "Error: %d amulet adjectives are required in "
		   "the `unidentified AMULET' section, but only "
		   "%d are given\n", max - min + 1, 
		   argz_count (amulet_adjectives_argz, 
			       amulet_adjectives_argz_len));
	  exit (1);
	}
    }
  else if (count_obj_with_tval (TV_AMULET))
    {
      fprintf (stderr, "Warning: amulets identified, but no `unidentified "
	       "AMULET' section declared");
    }

  if (count_obj_with_tval (TV_SCROLL))
    {
      int highest_subval = 0;
      int subval = get_highest_subval_of_obj_with_tval (TV_SCROLL);
      if (subval > highest_subval)
	highest_subval = subval;
      int max_titles = highest_subval - single_min + 1;
      fprintf (arguments.tc.outfile, "#define MAX_TITLES\t\t%d\n", max_titles);

    }
  if (syllables_argz_len)
    {
      fprintf (arguments.tc.outfile, "#define MAX_SYLLABLES\t\t%d\n", 
	       argz_count (syllables_argz, syllables_argz_len));
    }
  else if (count_obj_with_tval (TV_SCROLL))
    {
      fprintf (stderr, "Warning: scrolls identified, but no `syllables' "
	       "section declared");
    }
  int store_choices = count_store_choices (0);
  if (store_choices)
    {
      fprintf (arguments.tc.outfile, "#define STORE_CHOICES\t\t%d\n", 
	       store_choices);
      count_store_choices (1);
    }
  if (never_max != 0 && single_max != 0 && group_max != 0)
    {
      fprintf (arguments.tc.outfile, "#define ITEM_NEVER_STACK_MIN\t%d\n", 
	       never_min);
      fprintf (arguments.tc.outfile, "#define ITEM_NEVER_STACK_MAX\t%d\n", 
	       never_max);
      fprintf (arguments.tc.outfile, "#define ITEM_SINGLE_STACK_MIN\t%d\n", 
	       single_min);
      fprintf (arguments.tc.outfile, "#define ITEM_SINGLE_STACK_MAX\t%d\n", 
	       single_max);
      fprintf (arguments.tc.outfile, "#define ITEM_GROUP_MIN\t\t%d\n", 
	       group_min);
      fprintf (arguments.tc.outfile, "#define ITEM_GROUP_MAX\t\t%d\n", 
	       group_max);
    }

  int trap_count = count_obj_with_tval (TV_INVIS_TRAP);
  trap_count += count_obj_with_tval (TV_VIS_TRAP);
  if (scare_monster && trap_count)
    trap_count--;
  if (trap_count)
    fprintf (arguments.tc.outfile, "#define MAX_TRAP\t\t%d\n", trap_count);

  fprintf (arguments.tc.outfile, "\n\n");
  return;
}

void
show_store_choices_list (int store, FILE *stream)
{
  size_t length = 0;
  char *entry = NULL;
  char *choicestr;
  int first = 1;
  int j;
  int freq;
  char *argz = NULL;
  size_t argz_len = 0;
  int type;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
	{
	  fprintf (stderr, "internal err in show_store_choices_list\n");
	  exit (1);
	}
      t = (sorted_template_t *) gval.v;
      if (t->state.buyable_freq[store] == 0)
	continue;
      freq = t->state.buyable_freq[store];
      choicestr = xasprintf ("%d", atoi (entry));
      if (choicestr == NULL)
	return;
      for (j = 0 ; j < freq; j++)
	{
	  length += strlen (choicestr) + 4;
	  if (length > 80)
	    {
	      length = strlen (choicestr) + 4;
	      first = 1;
	      fprintf (stream, "\n");
	    }
	  if (first)
	    {
	      fprintf (stream, "  ");
	      first = 0;
	      length += 2;
	    }
	  fprintf (stream, "%s, ", choicestr);
	}
      free (choicestr);
    }
}

void 
WriteStoreChoices ()
{
  int i;
  fprintf (arguments.tc.outfile,
	   "\nint16u store_choice[MAX_STORES][STORE_CHOICES] = {\n");
  for (i = 0; i < MAX_STORES; i++)
    {
      fprintf (arguments.tc.outfile, "\t/* ");
      switch (i)
	{
	case 0: fprintf (arguments.tc.outfile, "General Store"); break;
	case 1: fprintf (arguments.tc.outfile, "Armoury"); break;
	case 2: fprintf (arguments.tc.outfile, "Weaponsmith"); break;
	case 3: fprintf (arguments.tc.outfile, "Temple"); break;
	case 4: fprintf (arguments.tc.outfile, "Alchemy shop"); break;
	case 5: fprintf (arguments.tc.outfile, "Magic-User store"); break;
	default: fprintf (arguments.tc.outfile, "Unknown store"); break;
	}
      fprintf (arguments.tc.outfile, "\t*/\n");
      fprintf (arguments.tc.outfile, "{");

      if (count_store_choices(0))
	{
	  show_store_choices_list (i, arguments.tc.outfile);
	  fprintf (arguments.tc.outfile, "}%s\n", 
		   i == MAX_STORES - 1 ? "" : ",");
	}
    }
  fprintf (arguments.tc.outfile, "};\n\n");
}

void WriteGenerationNotice ()
{
  fprintf (arguments.tc.outfile,
	   "/* The following was generated by the %s treasure compiler \n"
           "   (%s-tc %s) on %s.\n", 
	   PACKAGE, GAME_NAME, VERSION, __DATE__);
  fprintf (arguments.tc.outfile,"\n\
   Copyright (c) 1989-94 James E. Wilson, Robert A. Koeneke\n\
   This program is free software; you can redistribute it and/or modify\n\
   it under the terms of the GNU General Public License as published by\n\
   the Free Software Foundation; either version 3 of the License, or\n\
   (at your option) any later version.\n\
   \n\
   This program is distributed in the hope that it will be useful,\n\
   but WITHOUT ANY WARRANTY; without even the implied warranty of\n\
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n\
   GNU Library General Public License for more details.\n\
   \n\
   You should have received a copy of the GNU General Public License\n\
   along with this program; if not, write to the Free Software\n\
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.\n");
  fprintf (arguments.tc.outfile,
	   "*/\n\n");
}

void WriteTreasureHdr ()
{
  fprintf (arguments.tc.outfile,"\n\
/* Following are treasure arrays	and variables			*/ \n\
\n\
/* Object description:	Objects are defined here.  Each object has\n\
  the following attributes:\n\
	Descriptor : Name of item and formats.\n\
		& is replaced with 'a', 'an', or a number.\n\
		~ is replaced with null or 's'.\n\
	Character  : Character that represents the item.\n\
	Type value : Value representing the type of object.\n\
	Sub value  : separate value for each item of a type.\n\
		0 - 63: object can not stack\n\
		64 - 127: dungeon object, can stack with other D object\n\
		128 - 191: unused, previously for store items\n\
		192: stack with other iff have same p1 value, always\n\
			treated as individual objects\n\
		193 - 255: object can stack with others iff they have\n\
			the same p1 value, usually considered one group\n\
		Objects which have two type values, e.g. potions and\n\
		scrolls, need to have distinct subvals for\n\
		each item regardless of its tval\n\
	Damage	   : amount of damage item can cause.\n\
	Weight	   : relative weight of an item.\n\
	Number	   : number of items appearing in group.\n\
	To hit	   : magical plusses to hit.\n\
	To damage  : magical plusses to damage.\n\
	AC	   : objects relative armor class.\n\
		1 is worse than 5 is worse than 10 etc.\n\
	To AC	   : Magical bonuses to AC.\n\
	P1	   : Catch all for magical abilities such as\n\
		     plusses to strength, minuses to searching.\n\
	Flags	   : Abilities of object.  Each ability is a\n\
		     bit.  Bits 1-31 are used. (Signed integer)\n\
                     Foods and potions use this for multiple effects.\n\
        Effect Idx : A single effect of wands, scrolls, and staves.\n\
	Level	   : Minimum level on which item can be found.\n\
	Cost	   : Relative cost of item.\n\
\n\
	Special Abilities can be added to item by magic_init(),\n\
	found in misc.c.\n\
\n\
	Scrolls, Potions, and Food:\n\
	Flags is used to define a function which reading/quaffing\n\
	will cause.  Most scrolls and potions have only one bit\n\
	set.  Potions will generally have some food value, found\n\
	in p1.\n\
\n\
	Wands and Staffs:\n\
	Flags defines a function, p1 contains number of charges\n\
	for item.  p1 is set in magic_init() in misc.c.\n\
\n\
	Chests:\n\
	Traps are added randomly by magic_init() in misc.c.	*/\n");

  return;
}

int count_relsubvals_in_use (int tval, int relsubval)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int count = 0;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
	{
	  fprintf (stderr, "internal err. in subval_in_use\n");
	  exit (1);
	}
      t = (sorted_template_t *) gval.v;
      if (t->def.stackable_id == TRUE)
	if (t->val.tval == tval && t->state.stackable_id == relsubval)
	  count++;
    }

  free (argz);
  return count;
}
int
relsubval_in_use (int tval, int relsubval)
{
  int count = count_relsubvals_in_use (tval, relsubval);
  if (count > 1) /* should find myself, and then maybe one more */
    return 1;
  else
    return 0;
}

int
count_subvals_in_use (int tval, int subval)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int count = 0;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
	{
	  fprintf (stderr, "internal err. in subval_in_use\n");
	  exit (1);
	}
      t = (sorted_template_t *) gval.v;
      if (t->def.subval == TRUE)
	if (t->val.tval == tval && t->val.subval == subval)
	  count++;
    }

  free (argz);
  return count;
}
int
subval_in_use (int tval, int subval)
{
  int count = count_subvals_in_use (tval, subval);
  if (count > 1) /* should find myself, and then maybe one more */
    return 1;
  else
    return 0;
}

/* are we specifying relative subvals? */
int
using_relative_subvals ()
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int count = 0;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
	{
	  fprintf (stderr, "internal err. in using_relative_subvals\n");
	  exit (1);
	}
      t = (sorted_template_t *) gval.v;
      if (t->def.stackable_id == TRUE)
	count++;
    }

  free (argz);
  return count;
}

/* are we explicitly specifying subvals? */
int
using_subvals ()
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int count = 0;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
	{
	  fprintf (stderr, "internal err. in using_relative_subvals\n");
	  exit (1);
	}
      t = (sorted_template_t *) gval.v;
      if (t->def.subval == TRUE)
	count++;
    }

  free (argz);
  return count;
}

int get_subval_of_same_named_object (int relative, int stackable_flags, int tval, char *name)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int subval = -1;
  generic_t gval;
  sorted_template_t *t;
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
	{
	  fprintf (stderr, "internal err. in using_relative_subvals\n");
	  exit (1);
	}
      t = (sorted_template_t *) gval.v;
      if (t->state.stackable != stackable_flags)
	continue;
      if (t->def.tval == TRUE && t->val.tval != tval)
	continue;
      if (strcmp (t->val.name, name) != 0)
	continue;
      if (relative && t->def.stackable_id)
	subval = t->state.stackable_id;
      else if (!relative && t->def.subval)
	subval = t->val.subval;
    }

  free (argz);
  return subval;

}
void 
AutonumberSubVals (int relative, int stackable_flags, int min, int *max_subval)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int subvals[TV_MAX_VISIBLE];
  int relsubvals[TV_MAX_VISIBLE];
  int type;
  generic_t gval;
  sorted_template_t *t;
  memset (subvals, 0, sizeof (subvals));
  memset (relsubvals, 0, sizeof (relsubvals));
  int max = 0;

  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
	{
	  fprintf (stderr, "internal err. in AutonumberSubVals\n");
	  exit (1);
	}
      t = (sorted_template_t *) gval.v;
      if (t)
	{
	  if (t->state.stackable != stackable_flags)
	    continue;

	  if (!relative && t->def.subval == TRUE)
	    {
	      if (t->val.subval > max)
		max = t->val.subval;
	      continue; /* don't autonumber if set manually */
	    }
	  if (relative && t->def.stackable_id == TRUE)
	    {
	      t->val.subval = min + t->state.stackable_id;
	      if (t->val.subval > max)
		max = t->val.subval;
	      t->def.subval = TRUE;
	      continue; /* don't autonumber if set manually */
	    }
	  // try to number this the same as others with the same name
	  int subval = get_subval_of_same_named_object (relative,
							stackable_flags, 
							t->val.tval,
							t->val.name);
	  if (subval != -1)
	    {
	      t->val.subval = subval;
	      t->def.subval = TRUE;
	      continue;
	    }
	  if (relative)
	    {
	      //implicitly autonumber the relsubval
	      t->val.subval = min + relsubvals[t->val.tval];
	      t->def.subval = TRUE;
	      //is this subval already in use?  skip it.
	      while (relsubval_in_use (t->val.tval, t->val.subval))
		{
		  relsubvals[t->val.tval]++;
		  t->val.subval = min + relsubvals[t->val.tval];
		  t->def.subval = TRUE;
		}
	      relsubvals[t->val.tval]++;
	      if (t->val.subval > max)
		max = t->val.subval;
	    }
	  else
	    {
	      //implicitly autonumber the subval
	      //not going to work because subval is larger
	      t->val.subval = min + subvals[t->val.tval];
	      t->def.subval = TRUE;
	      //is this subval already in use?  skip it.
	      while (subval_in_use (t->val.tval, t->val.subval))
		{
		  subvals[t->val.tval]++;
		  t->val.subval = min + subvals[t->val.tval];
		  t->def.subval = TRUE;
		}
	      subvals[t->val.tval]++;
	      if (t->val.subval > max)
		max = t->val.subval;
	    }
	}
    }
  free (argz);
  if (max_subval)
    *max_subval = max;
  return;
}

void 
CalculateSubVals (int *never_stack_min, int *never_stack_max, int *item_single_stack_min, int *item_single_stack_max, int *item_group_min, int *item_group_max)
{
  int relative = 0;
  int subvals_specified = using_subvals();
  int relsubvals_specified = using_relative_subvals();
  if (subvals_specified && relsubvals_specified)
    {
      fprintf (stderr,"Error: Cannot have relsubval with subval\n");
      exit (1);
    }
  else if (relsubvals_specified)
    relative = 1;
  else if (subvals_specified)
    relative = 0;
  else
    relative = 0;

  //{ "never", 0},
  //{ "with_same_kind", 1},
  //{ "with_same_p1", 2},
  int never;
  int same_kind;
  int same_p1;
  int same_p1_and_kind;
  AutonumberSubVals (relative, 1 << 0, 0, &never);
  //now we bump up never to some power of 2, -1.
  if (never == 0) //FIXME: fix this such crapola!
    never = 0;
  else if (never + 1 <= 1) //synonymous
    never = 1 - 1;
  else if (never + 1 <= 2)
    never = 2 - 1;
  else if (never + 1 <= 4)
    never = 4 - 1;
  else if (never + 1 <= 8)
    never = 8 - 1;
  else if (never + 1 <= 16)
    never = 16 - 1;
  else if (never + 1 <= 32)
    never = 32 - 1;
  else if (never + 1 <= 64)
    never = 64 - 1;
  else if (never + 1 <= 128)
    never = 128 - 1;
  else if (never + 1 <= 256)
    never = 256 - 1;
  else if (never + 1 <= 1024)
    never = 1024 - 1;
  else if (never + 1 <= 2048)
    never = 2048 - 1;
  else if (never + 1 <= 4096)
    never = 4096 - 1;
  else if (never + 1 <= 8192)
    never = 8192 - 1;
  AutonumberSubVals (relative, 1 << 1, never + 1, &same_kind);

  AutonumberSubVals (relative, (1 << 2) | (1 << 1), same_kind + 1, 
		     &same_p1_and_kind);

  AutonumberSubVals (relative, 1 << 2, 
		     same_kind + 1 + same_p1_and_kind - same_kind, &same_p1);

  if (never_stack_min)
    *never_stack_min = 0;
  if (never_stack_max)
    *never_stack_max = never;
  if (item_single_stack_min)
    *item_single_stack_min = never + 1;
  if (item_single_stack_max)
    *item_single_stack_max = same_p1_and_kind;
  if (item_group_min)
    *item_group_min = same_kind + 1;
  if (item_group_max)
    *item_group_max = same_p1;

  return;
}

void
WriteAdjectives ()
{
  if (potion_adjectives_argz_len == 0 && mushroom_adjectives_argz_len  == 0 &&
      staff_adjectives_argz_len  == 0 && wand_adjectives_argz_len  == 0 &&
      ring_adjectives_argz_len == 0 && amulet_adjectives_argz_len == 0)
    return;
  if (potion_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "char *colors [MAX_COLORS] = {\n");
      show_adjective_list (potion_adjectives_argz, potion_adjectives_argz_len,
			   arguments.tc.outfile);
      fprintf (arguments.tc.outfile, "\n};\n");
    }
  if (mushroom_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "char *mushrooms[MAX_MUSH] = {\n");
      show_adjective_list (mushroom_adjectives_argz, 
			   mushroom_adjectives_argz_len,
			   arguments.tc.outfile);
      fprintf (arguments.tc.outfile, "\n};\n");
    }
  if (staff_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "char *woods[MAX_WOODS] = {\n");
      show_adjective_list (staff_adjectives_argz, staff_adjectives_argz_len,
			   arguments.tc.outfile);
      fprintf (arguments.tc.outfile, "\n};\n");
    }
  if (wand_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "char *metals[MAX_METALS] = {\n");
      show_adjective_list (wand_adjectives_argz, wand_adjectives_argz_len,
			   arguments.tc.outfile);
      fprintf (arguments.tc.outfile, "\n};\n");
    }
  if (ring_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "char *rocks[MAX_ROCKS] = {\n");
      show_adjective_list (ring_adjectives_argz, ring_adjectives_argz_len,
			   arguments.tc.outfile);
      fprintf (arguments.tc.outfile, "\n};\n");
    }
  if (amulet_adjectives_argz_len)
    {
      fprintf (arguments.tc.outfile, "char *amulets[MAX_AMULETS] = {\n");
      show_adjective_list (amulet_adjectives_argz, amulet_adjectives_argz_len,
			   arguments.tc.outfile);
      fprintf (arguments.tc.outfile, "\n};\n");
    }
  if (syllables_argz_len)
    {
      fprintf (arguments.tc.outfile, "char *syllables [MAX_SYLLABLES] = {\n");
      show_adjective_list (syllables_argz, syllables_argz_len,
			   arguments.tc.outfile);
      fprintf (arguments.tc.outfile, "\n};\n");
    }
}

void CheckForRequiredTreasures()
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  generic_t gval;

  struct required_items 
    {
      int tval;
      char *tval_name;
      int subval;
      int store;
      int found;
    };
  struct required_items required_items[] = 
    {
      {TV_FOOD, "TV_FOOD", 90, 1, 0},
      {TV_LIGHT, "TV_LIGHT", 192, 1, 0},
      {TV_CLOAK, "TV_CLOAK", 1, 0, 0},
      {TV_SWORD, "TV_SWORD", 3, 0, 0},
      {TV_SOFT_ARMOR, "TV_SOFT_ARMOR", 2, 0, 0},
      {TV_MAGIC_BOOK, "TV_MAGIC_BOOK", 64, 0, 0},
      {TV_PRAYER_BOOK, "TV_PRAYER_BOOK", 64, 0, 0},
    };
  int i;
  int num_required_items = 
    sizeof (required_items) / sizeof (struct required_items);
  St_SArgzTable (sortedtreasureT_P, &argz, &argz_len);
  int max_dungeon_obj = get_max_dungeon_obj ();

  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (sortedtreasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        continue;
      template_t *t = (template_t*) gval.v;
      for (i = 0; i < num_required_items; i++)
        {
          if (required_items[i].tval == t->val.tval &&
              required_items[i].subval == t->val.subval)
            {
              if (required_items[i].store == 0)
                required_items[i].found = 1;
              else
                {
                  if (required_items[i].store && atoi(t->id) >= max_dungeon_obj)
                    required_items[i].found = 1;
                }
            }
        }
    }
  for (i = 0; i < num_required_items; i++)
    {
      if (required_items[i].found == 0)
        fprintf (stderr, "Error: Necessary %s object with subval=%d not found%s \n", required_items[i].tval_name, required_items[i].subval, required_items[i].store ? " in stores." : ".");
    }

  free (argz);
  return;
}

int
tc_main (char *inputFilename)
{
  InitTables ();

  if (strcmp (inputFilename, "-") == 0)
    input_F = stdin;
  else
    {
      input_F = fopen (inputFilename, "r");
      if (!input_F) 
	{
	  fprintf (stderr, "Error: couldn't open file.\n");
	  return -1;
	}
    }

  if (yyparse ()) 
    {
      fprintf (stderr, "Errors prevent continuation.\n");
      return -2;
    }

  if (arguments.tc.sort)
    SortTreasures ();
  else
    {
      char *argz = NULL;
      size_t argz_len = 0;
      char *entry = NULL;
      generic_t gval;
      int type;
      template_t *t;

      St_SArgzTable (treasureT_P, &argz, &argz_len);
      while ((entry = argz_next (argz, argz_len, entry)))
	{
	  if (St_GetSym (treasureT_P, entry, &type, &gval) != ST_SYM_FOUND) 
	    {
	      fprintf (stderr, "internal err.\n");
	      exit (1);
	    }
	  t = (template_t *) gval.v;
	  AddSortedTreasure (t);
	}
      free (argz);
    }

  int never_min, never_max, single_min, single_max, group_min, group_max;
  CalculateSubVals (&never_min, &never_max, &single_min, &single_max, 
		    &group_min, &group_max);

  if (arguments.tc.consistency_check)
    CheckForRequiredTreasures();
  WriteGenerationNotice ();
  if (arguments.tc.only_generate_constants == 1)
    {
      WriteConstants (never_min, never_max, single_min, single_max, group_min,
                      group_max);
    }
  else
    {
      fprintf(arguments.tc.outfile, "#include \"constant.h\"\n");
      fprintf(arguments.tc.outfile, "#include \"types.h\"\n\n");
      if (count_store_choices(0))
        WriteStoreChoices();
      WriteAdjectives ();
      WriteTreasureHdr ();
      WriteTreasures ();
    }

  return 0;
}
