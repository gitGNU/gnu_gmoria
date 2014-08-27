/* creature.y: a Moria race & class definition compiler

   Copyright (c) 1989 Joseph Hall
   Copyright (C) 2014 Ben Asselstine
   Written by Ben Asselstine

   rcc is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   rcc is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with rcc; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

%{
#include "config.h"
#include <stdlib.h>
#include "argz.h"
#include "xvasprintf.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <netinet/in.h>
#include <dirent.h>

#include "st.h"
#include "opts.h"
#include "race-class.h"
#include "object_constant.h"



/*
 * defined_t is used to indicate whether all fields have been defined
 */

typedef struct {
    unsigned	age: 1,
		infra_vision: 1,
		male_height: 1,
		male_weight: 1,
		female_height: 1,
		female_weight: 1,
		hit_points: 1,
		disarming: 1,
		search_chance: 1,
		stealth_factor: 1,
		frequency_of_search: 1,
		base_to_hit: 1,
		base_to_hit_with_bows: 1,
		saving_throw: 1,
		strength_modifier: 1,
		intelligence_modifier: 1,
		wisdom_modifier: 1,
		dexterity_modifier: 1,
		constitution_modifier: 1,
		charisma_modifier: 1,
		experience_factor: 1,
		classes: 1,
		store_price_adjust_by_race: 1,
		shopkeep: 1,
		backgrounds: 1;
} race_defined_t;

typedef struct {
    unsigned    hit_points: 1,
		disarming: 1,
		search_chance: 1,
		stealth_factor: 1,
		frequency_of_search: 1,
		base_to_hit: 1,
		base_to_hit_with_bows: 1,
		saving_throw: 1,
		strength_modifier: 1,
		intelligence_modifier: 1,
		wisdom_modifier: 1,
		dexterity_modifier: 1,
		constitution_modifier: 1,
		charisma_modifier: 1,
		experience_factor: 1,
                adjust_base_to_hit: 1,
                adjust_base_to_hit_with_bows: 1,
                adjust_use_device: 1,
                adjust_disarming: 1,
                adjust_saving_throw: 1,
                titles: 1,
                spells: 1,
                prayers: 1;
} class_defined_t;

typedef struct {
    unsigned    store: 1,
                haggle_per: 1,
                inflate: 1,
                max_insults: 1,
                max_cost: 1;
} shopkeep_defined_t;

typedef struct {
    unsigned    roll: 1,
                social_class_bonus: 1;
} fragment_defined_t;

typedef struct {
    unsigned    adjust_base_to_hit: 1,
                adjust_base_to_hit_with_bows: 1,
                adjust_use_device: 1,
                adjust_disarming: 1,
                adjust_saving_throw: 1;
} adjust_per_one_third_level_defined_t;

typedef struct {
    unsigned    roll: 1,
                social_class_bonus: 1;
} background_defined_t;

typedef struct {
    unsigned    level: 1,
                mana: 1,
                fail: 1,
                exp: 1;
} spell_defined_t;

typedef struct
{
  char *race;
  int price;
} race_price_t;

typedef struct
{
  race_type r;
  race_price_t *price_adjust;
  int num_price_adjust;
  char *classes_argz;
  size_t classes_len;
  owner_type *shopkeeps;
  int num_shopkeeps;
  background_type *backgrounds;
  int num_backgrounds;
} race_t;

typedef struct
{
  int idx;
  race_t val;
  race_defined_t def;
  int line_no_for_classes;
  int line_no_for_price_adjust;
} race_template_t;


typedef struct
{
  int idx;
  spell_type s;
  int line_no;
} spell_t;

typedef struct
{
  class_type c;
  char *titles_argz;
  size_t titles_len;
  int adjust_per_one_third_level[MAX_LEV_ADJ];
  spell_t *spells;
  int num_spells;
  spell_t *prayers;
  int num_prayers;
} class_t;

typedef struct
{
  int idx;
  class_t val;
  class_defined_t def;
} class_template_t;

typedef struct
{
  owner_type val;
  shopkeep_defined_t def;
  int line_no;
} shopkeep_template_t;

typedef struct
{
  background_type val;
  background_defined_t def;
  int line_no;
} background_template_t;

typedef struct
{
  background_type val;
  fragment_defined_t def;
} fragment_template_t;

typedef struct
{
  spell_t val;
  spell_defined_t def;
} spell_template_t;

/*
 * symInit_t is used to initialize symbol tables with integer values
 */

typedef struct 
{
  char *name;
  int32u val;
} symInit_t;



/*
 * Maximum token length = maximum string constant length
 * Also, trim the stack to an "acceptable" size.
 */

#define	MAX_TOK_LEN	64		/* maximum acceptable token length  */
#define	YYSTACKSIZE	128

#define GEN_TYPE_TMPL	256		/* type of a template for st	    */

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

static race_template_t blankRace;	/* blank race for init-ing     */
static race_template_t tmpRace;		/* working race for current race   */

static class_template_t blankClass;	/* blank class for init-ing     */
static class_template_t tmpClass;	/* working class for current class */

static shopkeep_template_t blankShopkeep;
static shopkeep_template_t tmpShopkeep;
static fragment_template_t blankFragment;
static fragment_template_t tmpFragment;

int num_shopkeeps;
int *experience_levels;
int num_experience_levels;
background_template_t tmpBackground;
background_template_t blankBackground;
spell_template_t tmpSpell;
spell_template_t blankSpell;
spell_template_t tmpPrayer;
spell_template_t blankPrayer;

/*
 * Global symbol tables
 */

static st_Table_Pt keywordT_P;		/* parser's keywords		    */
static st_Table_Pt spellsT_P;		/* spells that go in books	    */
static st_Table_Pt prayersT_P;		/* prayers that go in books	    */
static st_Table_Pt raceT_P;		/* race definitions		    */
static st_Table_Pt classT_P;		/* class definitions */

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
    { "word_of_destruction", 29},
    { "genocide", 30},
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
    { "glyph_of_warding", 29},
    { "holy_word", 30},
    { NULL, 0 },
};
/*
 * Function declarations
 */

void PutRace (char *s, race_template_t *tmpl_P, int consistency_check);
void PutShopkeep(shopkeep_template_t *tmpl_P, int consistency_check);
void PutBackground(background_template_t *tmpl_P, int consistency_check);
void PutSpell (char *s, spell_template_t *tmpl_P, int consistency_check);
void PutPrayer (char *s, spell_template_t *tmpl_P, int consistency_check);
void CheckBackground (int chart, int next);
void PutClass (char *s, class_template_t *tmpl_P, int consistency_check);

int yyerror (char *s);

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

%token RACE CLASS EXPERIENCE_LEVELS AGE MALE_HEIGHT MALE_WEIGHT FEMALE_HEIGHT
%token FEMALE_WEIGHT INFRA_VISION ATTRIBUTES HIT_POINTS DISARMING SEARCH_CHANCE
%token STEALTH_FACTOR FREQUENCY_OF_SEARCH BASE_TO_HIT BASE_TO_HIT_WITH_BOWS
%token SAVING_THROW STRENGTH_MODIFIER INTELLIGENCE_MODIFIER WISDOM_MODIFIER
%token DEXTERITY_MODIFIER CONSTITUTION_MODIFIER CHARISMA_MODIFIER
%token EXPERIENCE_FACTOR CLASSES STORE_PRICE_ADJUST_BY_RACE SHOPKEEP STORE
%token HAGGLE_PER INFLATE MAX_INSULTS MAX_COST BACKGROUNDS BACKGROUND FRAGMENT
%token ROLL SOCIAL_CLASS_BONUS ADJUST_PER_ONE_THIRD_LEVEL TITLES SPELLS SPELL
%token LEVEL MANA FAIL EXP PRAYERS PRAYER ADJUST_BASE_TO_HIT 
%token ADJUST_BASE_TO_HIT_WITH_BOWS ADJUST_USE_DEVICE ADJUST_DISARMING 
%token ADJUST_SAVING_THROW

%{
static symInit_t 
keywordInit[] = 
{
    { "race", RACE},
    { "class", CLASS},
    { "experience_levels", EXPERIENCE_LEVELS},
    { "age", AGE},
    { "male_height", MALE_HEIGHT},
    { "male_weight", MALE_WEIGHT},
    { "female_height", FEMALE_HEIGHT},
    { "female_weight", FEMALE_WEIGHT},
    { "infra_vision", INFRA_VISION},
    { "attributes", ATTRIBUTES},
    { "hit_points", HIT_POINTS},
    { "disarming", DISARMING},
    { "search_chance", SEARCH_CHANCE},
    { "stealth_factor", STEALTH_FACTOR},
    { "frequency_of_search", FREQUENCY_OF_SEARCH},
    { "base_to_hit", BASE_TO_HIT},
    { "base_to_hit_with_bows", BASE_TO_HIT_WITH_BOWS},
    { "saving_throw", SAVING_THROW},
    { "strength_modifier", STRENGTH_MODIFIER},
    { "intelligence_modifier", INTELLIGENCE_MODIFIER},
    { "wisdom_modifier", WISDOM_MODIFIER},
    { "dexterity_modifier", DEXTERITY_MODIFIER},
    { "constitution_modifier", CONSTITUTION_MODIFIER},
    { "charisma_modifier", CHARISMA_MODIFIER},
    { "experience_factor", EXPERIENCE_FACTOR},
    { "classes", CLASSES},
    { "store_price_adjust_by_race", STORE_PRICE_ADJUST_BY_RACE},
    { "shopkeep", SHOPKEEP},
    { "store", STORE},
    { "haggle_per", HAGGLE_PER},
    { "inflate", INFLATE},
    { "max_insults", MAX_INSULTS},
    { "max_cost", MAX_COST},
    { "backgrounds", BACKGROUNDS},
    { "background", BACKGROUND},
    { "fragment", FRAGMENT},
    { "roll", ROLL},
    { "social_class_bonus", SOCIAL_CLASS_BONUS},
    { "adjust_per_one_third_level", ADJUST_PER_ONE_THIRD_LEVEL},
    { "titles", TITLES},
    { "spells", SPELLS},
    { "spell", SPELL},
    { "level", LEVEL},
    { "mana", MANA},
    { "fail", FAIL},
    { "exp", EXP},
    { "prayers", PRAYERS},
    { "prayer", PRAYER},
    { "adjust_base_to_hit", ADJUST_BASE_TO_HIT},
    { "adjust_base_to_hit_with_bows", ADJUST_BASE_TO_HIT_WITH_BOWS},
    { "adjust_use_device", ADJUST_USE_DEVICE},
    { "adjust_disarming", ADJUST_DISARMING},
    { "adjust_saving_throw", ADJUST_SAVING_THROW},
    { NULL, 0 }
};
%}
/*
 * Entities
 */

%token <sval> IDENTIFIER	/* identifier, not a keyword		    */
%token <dval> FLOAT_LIT		/* floating-pt literal			    */
%token <ival> INT_LIT		/* integer literal			    */
%token <sval> STRING_LIT	/* string literal			    */
%token <ival> BOOL_LIT		/* boolean literal			    */

/*
 * ASCII chars are their own tokens
 */


%start	race_and_class


/*
 * THE PARSER
 */

%%

race_and_class	:	race_def ';' race_and_class
		|	class_def ';' race_and_class
		|	exp_levels_def ';' race_and_class
		|	comment_def  race_and_class
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

race_def	:	RACE STRING_LIT '{' race_attributes '}'
				{ tmpRace.val.r.trace =
				    (char *) malloc(strlen($<sval>2) + 1);
				  strcpy(tmpRace.val.r.trace, $<sval>2);
                                  tmpRace.idx = St_TableSize(raceT_P);
				  PutRace($<sval>2, &tmpRace,
					      arguments.rcc.consistency_check);
				  tmpRace = blankRace;
				}
		;

class_def	:	CLASS STRING_LIT '{' class_attributes '}'
				{ tmpClass.val.c.title =
				    (char *) malloc(strlen($<sval>2) + 1);
				  strcpy(tmpClass.val.c.title, $<sval>2);
                                  tmpClass.idx = St_TableSize(classT_P);
				  PutClass($<sval>2, &tmpClass,
					      arguments.rcc.consistency_check);
				  tmpClass = blankClass;
				}
		;

race_attributes :	race_attribute ';' race_attributes
                |	classes_def ';' race_attributes
                |	price_race_adj ';' race_attributes
                |	shopkeep_def ';' race_attributes
                |	backgrounds_def ';' race_attributes
		|	/* empty */
		;

race_attribute  :	AGE ':' INT_LIT '|' INT_LIT
				{ tmpRace.val.r.b_age = $<ival>3;
                                  tmpRace.val.r.m_age = $<ival>5;
				  tmpRace.def.age = TRUE; }
		|	INFRA_VISION ':' INT_LIT 
				{ tmpRace.val.r.infra = $<ival>3;
				  tmpRace.def.infra_vision = TRUE; }
		|	MALE_HEIGHT ':' INT_LIT '|' INT_LIT
				{ tmpRace.val.r.m_b_ht = $<ival>3;
				  tmpRace.val.r.m_m_ht = $<ival>5;
				  tmpRace.def.male_height = TRUE; }
		|	MALE_WEIGHT ':' INT_LIT '|' INT_LIT
				{ tmpRace.val.r.m_b_wt = $<ival>3;
				  tmpRace.val.r.m_m_wt = $<ival>5;
				  tmpRace.def.male_weight = TRUE; }
		|	FEMALE_HEIGHT ':' INT_LIT '|' INT_LIT
				{ tmpRace.val.r.f_b_ht = $<ival>3;
				  tmpRace.val.r.f_m_ht = $<ival>5;
				  tmpRace.def.female_height = TRUE; }
		|	FEMALE_WEIGHT ':' INT_LIT '|' INT_LIT
				{ tmpRace.val.r.f_b_wt = $<ival>3;
				  tmpRace.val.r.f_m_wt = $<ival>5;
				  tmpRace.def.female_weight = TRUE; }
		|	HIT_POINTS ':' INT_LIT
				{ tmpRace.val.r.bhitdie = $<ival>3;
				  tmpRace.def.hit_points = TRUE; }
		|	DISARMING ':' INT_LIT
				{ tmpRace.val.r.b_dis = $<ival>3;
				  tmpRace.def.disarming = TRUE; }
		|	SEARCH_CHANCE ':' INT_LIT
				{ tmpRace.val.r.srh = $<ival>3;
				  tmpRace.def.search_chance = TRUE; }
		|	STEALTH_FACTOR ':' INT_LIT
				{ tmpRace.val.r.stl = $<ival>3;
				  tmpRace.def.stealth_factor = TRUE; }
		|	FREQUENCY_OF_SEARCH ':' INT_LIT
				{ tmpRace.val.r.fos = $<ival>3;
				  tmpRace.def.frequency_of_search = TRUE; }
		|	BASE_TO_HIT ':' INT_LIT
				{ tmpRace.val.r.bth = $<ival>3;
				  tmpRace.def.base_to_hit = TRUE; }
		|	BASE_TO_HIT_WITH_BOWS ':' INT_LIT
				{ tmpRace.val.r.bthb = $<ival>3;
				  tmpRace.def.base_to_hit_with_bows = TRUE; }
		|	SAVING_THROW ':' INT_LIT
				{ tmpRace.val.r.bsav = $<ival>3;
				  tmpRace.def.saving_throw = TRUE; }
		|	STRENGTH_MODIFIER ':' INT_LIT
				{ tmpRace.val.r.str_adj = $<ival>3;
				  tmpRace.def.strength_modifier = TRUE; }
		|	INTELLIGENCE_MODIFIER ':' INT_LIT
				{ tmpRace.val.r.int_adj = $<ival>3;
				  tmpRace.def.intelligence_modifier = TRUE; }
		|	WISDOM_MODIFIER ':' INT_LIT
				{ tmpRace.val.r.wis_adj = $<ival>3;
				  tmpRace.def.wisdom_modifier = TRUE; }
		|	DEXTERITY_MODIFIER ':' INT_LIT
				{ tmpRace.val.r.dex_adj = $<ival>3;
				  tmpRace.def.dexterity_modifier = TRUE; }
		|	CONSTITUTION_MODIFIER ':' INT_LIT
				{ tmpRace.val.r.con_adj = $<ival>3;
				  tmpRace.def.constitution_modifier = TRUE; }
		|	CHARISMA_MODIFIER ':' INT_LIT
				{ tmpRace.val.r.chr_adj = $<ival>3;
				  tmpRace.def.charisma_modifier = TRUE; }
		|	EXPERIENCE_FACTOR ':' INT_LIT
				{ tmpRace.val.r.b_exp = $<ival>3;
				  tmpRace.def.experience_factor = TRUE; }
		;

classes_def     :	CLASSES '{' ok_classes '}'
				{ /*PutAllowedClassesForRace();*/ 
                                  tmpRace.def.classes = TRUE; 
                                  tmpRace.line_no_for_classes = lineNo;}
		;

ok_classes      :	ok_class more_ok_classes
		;

ok_class        :	STRING_LIT
				{ argz_add(&tmpRace.val.classes_argz,
                                           &tmpRace.val.classes_len, $<sval>1);}
		;

more_ok_classes :       ',' ok_class more_ok_classes
		|	/* empty */
		;

price_race_adj  :	STORE_PRICE_ADJUST_BY_RACE '{' race_prices '}'
				{tmpRace.def.store_price_adjust_by_race = TRUE;
                                 tmpRace.line_no_for_price_adjust = lineNo; }
                ;

race_prices     :	race_price ';' more_race_prices
                ;

race_price      :	STRING_LIT ':' INT_LIT
				{if (arguments.rcc.consistency_check)
                                   {
                                     int i = 0;
                                     for (; i<tmpRace.val.num_price_adjust; i++)
                                       {
                                         race_price_t val =
                                           tmpRace.val.price_adjust[i];
                                         if (strcmp (val.race, $<sval>1) == 0)
                                           {
                                             char *msg = 
                                               xasprintf ("duplicate race `%s'",
                                                           val.race);
                                             yyerror (msg);
                                           }
                                       }
                                       if ($<ival>3 == 0)
                                         {
                                           char *msg = "price must be greater "
                                                       "than zero";
                                           yyerror (msg);
                                         }
                                   }
                                 tmpRace.val.num_price_adjust++;
                                 int num = tmpRace.val.num_price_adjust;
                                 tmpRace.val.price_adjust = 
                                   realloc (tmpRace.val.price_adjust,
                                            num * sizeof (race_price_t));
                                 race_price_t val;
                                 val.race = strdup($<sval>1); //FIXME leak
                                 val.price = $<ival>3;
                                 tmpRace.val.price_adjust[num-1] = val;}
		;

more_race_prices:	race_price ';' more_race_prices
		|	/* empty */
		;

shopkeep_def    :       SHOPKEEP STRING_LIT STRING_LIT STRING_LIT '{' shopkeep_attrs '}'
				{ 
                                  tmpRace.def.shopkeep = TRUE;
                                  char *r = xasprintf ("(%s)", $<sval>3);
                                  tmpShopkeep.val.owner_name = 
                                    xasprintf ("%-22s %-12s %s", 
                                      $<sval>2, r, $<sval>4);
                                  tmpShopkeep.line_no = lineNo;
                                  tmpShopkeep.val.owner_race = 
                                    St_TableSize(raceT_P);
				  PutShopkeep(&tmpShopkeep,
					      arguments.rcc.consistency_check);
				  tmpShopkeep = blankShopkeep;
                                  num_shopkeeps++;
				}
                ;

shopkeep_attrs  :       shopkeep_attr ';' more_shop_attrs
                ;

more_shop_attrs :       shopkeep_attr ';' more_shop_attrs
                |               /* empty */
                ;

shopkeep_attr   :       STORE ':' STRING_LIT
                                {
                                 if (arguments.rcc.consistency_check)
                                   {
                                     if (strlen ($<sval>3) > 1 || 
                                         strlen ($<sval>3) == 0 ||
                                         $<sval>3[0] - '1' > MAX_STORES)
                                       yyerror ("invalid store");
                                   }
                                 tmpShopkeep.def.store = TRUE;
                                 tmpShopkeep.val.pstore = $<sval>3[0] - '1';}
                |       HAGGLE_PER ':' INT_LIT
                                {tmpShopkeep.def.haggle_per = TRUE;
                                 tmpShopkeep.val.haggle_per = $<ival>3;}
                |       INFLATE ':' INT_LIT '|' INT_LIT
                                {tmpShopkeep.def.inflate = TRUE;
                                 tmpShopkeep.val.min_inflate = $<ival>3;
                                 tmpShopkeep.val.max_inflate = 
                                   tmpShopkeep.val.min_inflate + $<ival>5;}
                |       MAX_INSULTS ':' INT_LIT
                                {tmpShopkeep.def.max_insults = TRUE;
                                 tmpShopkeep.val.insult_max = $<ival>3;}
                |       MAX_COST ':' INT_LIT
                                {tmpShopkeep.def.max_cost = TRUE;
                                 tmpShopkeep.val.max_cost = $<ival>3;}
                ;

backgrounds_def :       BACKGROUNDS '{' backgrounds '}'
                                {tmpRace.def.backgrounds = TRUE;}
                ;

backgrounds     :	background more_backgrounds
		;

background      :       BACKGROUND INT_LIT INT_LIT '{' fragments '}'
                                {int i;
                                 for (i=0; i<tmpRace.val.num_backgrounds; i++)
                                   if (!tmpRace.val.backgrounds[i].chart)
                                     {
                                       tmpRace.val.backgrounds[i].chart = 
                                         $<ival>2;
                                       tmpRace.val.backgrounds[i].next = 
                                         $<ival>3;
                                     }
                                 if (arguments.rcc.consistency_check)
                                   CheckBackground($<ival>2, $<ival>3); }
                ;

more_backgrounds:	',' background more_backgrounds
		|	/* empty */
		;

fragments       :	fragment more_fragments
		;

fragment        :       FRAGMENT STRING_LIT '{' frag_attrs '}'
                                {tmpBackground.val.info = strdup($<sval>2);
                                 //FIXME leak
                                 PutBackground(&tmpBackground,
                                               arguments.rcc.consistency_check);
                                 tmpBackground = blankBackground;}
                ;

more_fragments  :	',' fragment more_fragments
                |       /* empty */
		;

frag_attrs      :       frag_attr ';' more_frag_attrs
                ;

frag_attr       :       ROLL ':' INT_LIT
                                {if (arguments.rcc.consistency_check &&
                                     $<ival>3 > 100)
                                   yyerror("roll exceeds 100");
                                 tmpBackground.def.roll = TRUE;
                                 tmpBackground.val.roll = $<ival>3;}
                |       SOCIAL_CLASS_BONUS ':' INT_LIT
                                {tmpBackground.def.social_class_bonus = TRUE;
                                 tmpBackground.val.bonus = $<ival>3;}
                ;

more_frag_attrs :	frag_attr ';' more_frag_attrs
                |       /* empty */
		;

class_attributes:	class_attribute ';' class_attributes
                |	adjust_per_lev ';' class_attributes
                |	titles_def ';' class_attributes
                |	spells_def ';' class_attributes
                |	prayers_def ';' class_attributes
		|	/* empty */
		;

class_attribute :       HIT_POINTS ':' INT_LIT
				{ tmpClass.val.c.adj_hd = $<ival>3;
				  tmpClass.def.hit_points = TRUE; }
		|	DISARMING ':' INT_LIT
				{ tmpClass.val.c.mdis = $<ival>3;
				  tmpClass.def.disarming = TRUE; }
		|	SEARCH_CHANCE ':' INT_LIT
				{ tmpClass.val.c.msrh = $<ival>3;
				  tmpClass.def.search_chance = TRUE; }
		|	STEALTH_FACTOR ':' INT_LIT
				{ tmpClass.val.c.mstl = $<ival>3;
				  tmpClass.def.stealth_factor = TRUE; }
		|	FREQUENCY_OF_SEARCH ':' INT_LIT
				{ tmpClass.val.c.mfos = $<ival>3;
				  tmpClass.def.frequency_of_search = TRUE; }
		|	BASE_TO_HIT ':' INT_LIT
				{ tmpClass.val.c.mbth = $<ival>3;
				  tmpClass.def.base_to_hit = TRUE; }
		|	BASE_TO_HIT_WITH_BOWS ':' INT_LIT
				{ tmpClass.val.c.mbthb = $<ival>3;
				  tmpClass.def.base_to_hit_with_bows = TRUE; }
		|	SAVING_THROW ':' INT_LIT
				{ tmpClass.val.c.msav = $<ival>3;
				  tmpClass.def.saving_throw = TRUE; }
		|	STRENGTH_MODIFIER ':' INT_LIT
				{ tmpClass.val.c.madj_str = $<ival>3;
				  tmpClass.def.strength_modifier = TRUE; }
		|	INTELLIGENCE_MODIFIER ':' INT_LIT
				{ tmpClass.val.c.madj_int = $<ival>3;
				  tmpClass.def.intelligence_modifier = TRUE; }
		|	WISDOM_MODIFIER ':' INT_LIT
				{ tmpClass.val.c.madj_wis = $<ival>3;
				  tmpClass.def.wisdom_modifier = TRUE; }
		|	DEXTERITY_MODIFIER ':' INT_LIT
				{ tmpClass.val.c.madj_dex = $<ival>3;
				  tmpClass.def.dexterity_modifier = TRUE; }
		|	CONSTITUTION_MODIFIER ':' INT_LIT
				{ tmpClass.val.c.madj_con = $<ival>3;
				  tmpClass.def.constitution_modifier = TRUE; }
		|	CHARISMA_MODIFIER ':' INT_LIT
				{ tmpClass.val.c.madj_chr = $<ival>3;
				  tmpClass.def.charisma_modifier = TRUE; }
		|	EXPERIENCE_FACTOR ':' INT_LIT
				{ tmpClass.val.c.m_exp = $<ival>3;
				  tmpClass.def.experience_factor = TRUE; }
		;

adjust_per_lev  :       ADJUST_PER_ONE_THIRD_LEVEL '{' adj_attrs '}'
                ;

adj_attrs       :       adj_attr ';' more_adj_attrs
                ;

more_adj_attrs  :       adj_attr ';'  more_adj_attrs
                |               /* empty */
                ;

adj_attr        :       ADJUST_BASE_TO_HIT ':' INT_LIT
                                {tmpClass.val.adjust_per_one_third_level[0] =
                                 $<ival>3;
                                 tmpClass.def.adjust_base_to_hit = TRUE;}
                |       ADJUST_BASE_TO_HIT_WITH_BOWS ':' INT_LIT
                                {tmpClass.val.adjust_per_one_third_level[1] =
                                 $<ival>3;
                                 tmpClass.def.adjust_base_to_hit_with_bows = TRUE;}
                |       ADJUST_USE_DEVICE ':' INT_LIT
                                {tmpClass.val.adjust_per_one_third_level[2] =
                                 $<ival>3;
                                 tmpClass.def.adjust_use_device = TRUE;}
                |       ADJUST_DISARMING ':' INT_LIT
                                {tmpClass.val.adjust_per_one_third_level[3] =
                                 $<ival>3;
                                 tmpClass.def.adjust_disarming = TRUE;}
                |       ADJUST_SAVING_THROW ':' INT_LIT
                                {tmpClass.val.adjust_per_one_third_level[4] =
                                 $<ival>3;
                                 tmpClass.def.adjust_saving_throw = TRUE;}
                ;

titles_def      :       TITLES '{' titles '}'
				{ /*PutTitles();*/ }
		;

titles          :	title more_titles
		;

title           :	STRING_LIT
				{ 
                                 if (arguments.rcc.consistency_check)
                                   {
                                     const char *t = NULL;
                                     char *argz = tmpClass.val.titles_argz;
                                     size_t len = tmpClass.val.titles_len;
                                     while ((t = argz_next (argz, len, t)))
                                       {
                                         if (strcmp (t, $<sval>1) == 0)
                                           {
                                             char *msg = 
                                               xasprintf ("duplicate title %s",
                                                          $<sval>1);
                                             yyerror (msg);
                                           }
                                       }
                                   }

                                 argz_add (&tmpClass.val.titles_argz,
                                           &tmpClass.val.titles_len, 
                                           $<sval>1); }
		;

more_titles     :	',' title more_titles
		|	/* empty */
		;

spells_def      :       SPELLS '{' spells '}'
                ;

spells          :       spell more_spells
                ;

more_spells     :       ',' spell more_spells
                |
                ;

spell           :       SPELL IDENTIFIER '{' spell_attrs '}'
                                {PutSpell($<sval>2, &tmpSpell,
                                          arguments.rcc.consistency_check);
                                 tmpSpell = blankSpell;}
                ;

spell_attrs     :       spell_attr ';' more_spell_attrs
                ;

more_spell_attrs:       spell_attr ';' more_spell_attrs
                |               /* empty */
                ;

spell_attr      :       LEVEL ':' INT_LIT
                                {tmpSpell.val.s.slevel = $<ival>3;
                                 tmpSpell.def.level = TRUE;}
                |       MANA ':' INT_LIT
                                {tmpSpell.val.s.smana = $<ival>3;
                                 tmpSpell.def.mana = TRUE;}
                |       FAIL ':' INT_LIT
                                {tmpSpell.val.s.sfail = $<ival>3;
                                 tmpSpell.def.fail = TRUE;}
                |       EXP ':' INT_LIT
                                {tmpSpell.val.s.sexp = $<ival>3;
                                 tmpSpell.def.exp = TRUE;}
                ;

prayers_def     :       PRAYERS '{' prayers '}'
                ;

prayers         :       prayer more_prayers
                ;

more_prayers    :       ',' prayer more_prayers
                |
                ;

prayer          :       PRAYER IDENTIFIER '{' prayer_attrs '}'
                                {PutPrayer($<sval>2, &tmpPrayer,
                                           arguments.rcc.consistency_check);
                                 tmpPrayer = blankPrayer;}
                ;

prayer_attrs    :       prayer_attr ';' more_prayer_attrs
                ;

more_prayer_attrs:       prayer_attr ';' more_prayer_attrs
                |               /* empty */
                ;

prayer_attr     :       LEVEL ':' INT_LIT
                                {tmpPrayer.val.s.slevel = $<ival>3;
                                 tmpPrayer.def.level = TRUE;}
                |       MANA ':' INT_LIT
                                {tmpPrayer.val.s.smana = $<ival>3;
                                 tmpPrayer.def.mana = TRUE;}
                |       FAIL ':' INT_LIT
                                {tmpPrayer.val.s.sfail = $<ival>3;
                                 tmpPrayer.def.fail = TRUE;}
                |       EXP ':' INT_LIT
                                {tmpPrayer.val.s.sexp = $<ival>3;
                                 tmpPrayer.def.exp = TRUE;}
                ;

exp_levels_def  :       EXPERIENCE_LEVELS '{' exp_levels '}'
		;

exp_levels      :	exp_level more_exp_levels
		;

exp_level       :	INT_LIT
				{ 
                                  int lvl = num_experience_levels;
                                  if (lvl > 0 &&
                                      experience_levels[lvl-1] > $<ival>1 &&
                                      arguments.rcc.consistency_check)
                                    yyerror (xasprintf("%s %d is too small",
                                                       "experience level",
                                                       $<ival>1));
                                  else
                                    {
                                      num_experience_levels++;
                                      lvl++;
                                      experience_levels =
                                        realloc (experience_levels, lvl * 
                                                   sizeof (int));
                                      experience_levels[lvl-1] = $<ival>1;
                                    }
                                }
		;

more_exp_levels :	',' exp_level more_exp_levels
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
ErrMsgLineNo (char *s, int line_no)
{
  if (line_no >= 0)
    fprintf (stderr, "Error: %s at line %d\n", s, line_no);
  else
    fprintf (stderr, "Error: %s\n", s);
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
  spellsT_P = InitTable ("spells", spellsInit);
  prayersT_P = InitTable ("prayers", prayersInit);

  raceT_P = St_NewTable ("race", 200);
  classT_P = St_NewTable ("class", 40);

  return;
}

void 
NotDefined(char *name, char *s)
{
  fprintf (stderr, 
	   "Warning: %s not defined for \"%s\", line %d\n",
	   s, name, lineNo);
  return;
}

void 
PutRace (char *s, race_template_t *tmpl_P, int consistency_check)
{
  generic_t gval;

  gval.v = malloc (sizeof(race_template_t));
  *(race_template_t *) gval.v = *tmpl_P;

  if (!tmpl_P->def.age)
    NotDefined (tmpl_P->val.r.trace, "AGE");
  if (!tmpl_P->def.infra_vision)
    NotDefined (tmpl_P->val.r.trace, "INFRA_VISION");
  if (!tmpl_P->def.male_height)
    NotDefined (tmpl_P->val.r.trace, "MALE_HEIGHT");
  if (!tmpl_P->def.male_weight)
    NotDefined (tmpl_P->val.r.trace, "MALE_WEIGHT");
  if (!tmpl_P->def.female_height)
    NotDefined (tmpl_P->val.r.trace, "FEMALE_HEIGHT");
  if (!tmpl_P->def.female_weight)
    NotDefined (tmpl_P->val.r.trace, "FEMALE_WEIGHT");
  if (!tmpl_P->def.hit_points)
    NotDefined (tmpl_P->val.r.trace, "HIT_POINTS");
  if (!tmpl_P->def.disarming)
    NotDefined (tmpl_P->val.r.trace, "DISARMING");
  if (!tmpl_P->def.search_chance)
    NotDefined (tmpl_P->val.r.trace, "SEARCH_CHANCE");
  if (!tmpl_P->def.stealth_factor)
    NotDefined (tmpl_P->val.r.trace, "STEALTH_FACTOR");
  if (!tmpl_P->def.frequency_of_search)
    NotDefined (tmpl_P->val.r.trace, "FREQUENCY_OF_SEARCH");
  if (!tmpl_P->def.base_to_hit)
    NotDefined (tmpl_P->val.r.trace, "BASE_TO_HIT");
  if (!tmpl_P->def.base_to_hit_with_bows)
    NotDefined (tmpl_P->val.r.trace, "BASE_TO_HIT_WITH_BOWS");
  if (!tmpl_P->def.saving_throw)
    NotDefined (tmpl_P->val.r.trace, "SAVING_THROW");
  if (!tmpl_P->def.strength_modifier)
    NotDefined (tmpl_P->val.r.trace, "STRENGTH_MODIFIER");
  if (!tmpl_P->def.intelligence_modifier)
    NotDefined (tmpl_P->val.r.trace, "INTELLIGENCE_MODIFIER");
  if (!tmpl_P->def.wisdom_modifier)
    NotDefined (tmpl_P->val.r.trace, "WISDOM_MODIFIER");
  if (!tmpl_P->def.dexterity_modifier)
    NotDefined (tmpl_P->val.r.trace, "DEXTERITY_MODIFIER");
  if (!tmpl_P->def.constitution_modifier)
    NotDefined (tmpl_P->val.r.trace, "CONSTITUTION_MODIFIER");
  if (!tmpl_P->def.charisma_modifier)
    NotDefined (tmpl_P->val.r.trace, "CHARISMA_MODIFIER");
  if (!tmpl_P->def.experience_factor)
    NotDefined (tmpl_P->val.r.trace, "EXPERIENCE_FACTOR");
  if (!tmpl_P->def.classes)
    NotDefined (tmpl_P->val.r.trace, "CLASSES");
  if (!tmpl_P->def.store_price_adjust_by_race)
    NotDefined (tmpl_P->val.r.trace, "STORE_PRICE_ADJUST_BY_RACE");
  if (!tmpl_P->def.shopkeep)
    ;//NotDefined (tmpl_P->val.r.trace, ""); it's okay if we don't have one.
  if (!tmpl_P->def.backgrounds)
    NotDefined (tmpl_P->val.r.trace, "BACKGROUNDS");

  if (consistency_check)
    ;//ConsistencyCheckRace (&tmpl_P->val, &tmpl_P->state);

  if (St_DefSym (raceT_P, s, GEN_TYPE_TMPL, gval) == ST_SYM_FOUND) 
    {
      fprintf (arguments.rcc.outfile, "Warning: redefining \"%s\", line %d\n", 
               tmpl_P->val.r.trace, lineNo);
    }

  return;
}

void PutShopkeep(shopkeep_template_t *tmpl_P, int consistency_check)
{
  char *id = "shopkeep";
  if (!tmpl_P->def.store)
    NotDefined (id, "STORE");
  if (!tmpl_P->def.haggle_per)
    NotDefined (id, "HAGGLE_PER");
  if (!tmpl_P->def.inflate)
    NotDefined (id, "INFLATE");
  if (!tmpl_P->def.max_insults)
    NotDefined (id, "MAX_INSULTS");
  if (!tmpl_P->def.max_cost)
    NotDefined (id, "MAX_COST");
  if (consistency_check)
    {
      if (tmpl_P->val.insult_max == 0)
        yyerror ("max_insults can't be zero");
      if (tmpl_P->val.max_cost == 0)
        yyerror ("max_cost can't be zero");
    }
  tmpRace.val.num_shopkeeps++;
  tmpRace.val.shopkeeps = realloc(tmpRace.val.shopkeeps, 
                                  tmpRace.val.num_shopkeeps * 
                                    sizeof(owner_type));
  tmpRace.val.shopkeeps[tmpRace.val.num_shopkeeps-1] = tmpl_P->val;
}

void PutBackground(background_template_t *tmpl_P, int consistency_check)
{
  if (!tmpl_P->def.roll)
    NotDefined("fragment", "ROLL");
  if (!tmpl_P->def.social_class_bonus)
    NotDefined("fragment", "SOCIAL_CLASS_BONUS");
  tmpRace.val.num_backgrounds++;
  int num = tmpRace.val.num_backgrounds;
  tmpRace.val.backgrounds = realloc (tmpRace.val.backgrounds, 
                                     num * sizeof (background_type));
  tmpRace.val.backgrounds[num-1] = tmpBackground.val;
}

void CheckSpell (spell_type *s)
{
  if (s->slevel == 0)
    yyerror ("level can't be zero");
  if (s->smana == 0)
    yyerror ("mana can't be zero");
  if (s->sfail >= 100)
    yyerror ("fail can't be 100 or more");
}

void
PutSpell (char *s, spell_template_t *tmpl_P, int consistency_check)
{
  generic_t gval;
  int type;
  if (St_GetSym (spellsT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      yyerror (xasprintf("unknown spell `%s'", s));
      return;
    }
  tmpl_P->val.idx = gval.i;
  tmpl_P->val.line_no = lineNo;

  int i;
  for (i = 0; i < tmpClass.val.num_spells; i++)
    {
      if (tmpClass.val.spells[i].idx == tmpl_P->val.idx)
        {
          yyerror (xasprintf ("duplicate spell %s", s));
          return;
        }
    }
  char *id = xasprintf ("spell %s", s);
  if (!tmpl_P->def.level)
    NotDefined(id, "LEVEL");
  if (!tmpl_P->def.mana)
    NotDefined(id, "MANA");
  if (!tmpl_P->def.fail)
    NotDefined(id, "FAIL");
  if (!tmpl_P->def.exp)
    NotDefined(id, "EXP");
  if (consistency_check)
    CheckSpell (&tmpl_P->val.s);
  tmpClass.val.num_spells++;
  int num = tmpClass.val.num_spells;
  tmpClass.val.spells = realloc (tmpClass.val.spells,  
                                 num * sizeof(spell_t));
  tmpClass.val.spells[num-1] = tmpl_P->val;
  free (id);
}

void
PutPrayer (char *s, spell_template_t *tmpl_P, int consistency_check)
{
  generic_t gval;
  int type;
  if (St_GetSym (prayersT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      yyerror (xasprintf("unknown prayer `%s'", s));
      return;
    }
  tmpl_P->val.idx = gval.i;
  tmpl_P->val.line_no = lineNo;
  int i;
  for (i = 0; i < tmpClass.val.num_prayers; i++)
    {
      if (tmpClass.val.prayers[i].idx == tmpl_P->val.idx)
        {
          yyerror (xasprintf ("duplicate prayer %s", s));
          return;
        }
    }
  char *id = xasprintf ("prayer %s", s);
  if (!tmpl_P->def.level)
    NotDefined(id, "LEVEL");
  if (!tmpl_P->def.mana)
    NotDefined(id, "MANA");
  if (!tmpl_P->def.fail)
    NotDefined(id, "FAIL");
  if (!tmpl_P->def.exp)
    NotDefined(id, "EXP");
  if (consistency_check)
    CheckSpell (&tmpl_P->val.s);
  tmpClass.val.num_prayers++;
  int num = tmpClass.val.num_prayers;
  tmpClass.val.prayers = realloc (tmpClass.val.prayers,  
                                 num * sizeof(spell_t));
  tmpClass.val.prayers[num-1] = tmpl_P->val;
  free (id);
}

int compare_ints (const void *i1, const void *i2)
{
  int num1 = *(int*)i1;
  int num2 = *(int*)i2;
  return num1 - num2;
}

void CheckBackground (int chart, int next)
{
  //check to see if the background has no dup rolls, and a roll of 100.
  int i;
  int rolls[tmpRace.val.num_backgrounds];
  int num_rolls = 0;
  if (chart == 0)
    yyerror ("invalid background id of 0");
  if (chart == next)
    yyerror ("next background id can't point to this background");
  memset (rolls, 0, sizeof (rolls));
  for (i = 0; i < tmpRace.val.num_backgrounds; i++)
    {
      if (tmpRace.val.backgrounds[i].chart != chart)
        continue;
      if (tmpRace.val.backgrounds[i].next != next)
        { 
          yyerror ("background has duplicate id or points " 
                   "to wrong next background");
          return;
        }
      rolls[num_rolls] = tmpRace.val.backgrounds[i].roll;
      num_rolls++;
    }
  qsort (rolls, num_rolls, sizeof (int), compare_ints);
  for (i = 0; i < num_rolls; i++)
    {
      if (rolls[i] == rolls[i-1])
        {
          yyerror (xasprintf ("duplicate roll value of %d", rolls[i]));
          return;
        }
    }
  if (num_rolls)
    {
      if (rolls[num_rolls-1] != 100)
        {
          yyerror ("background needs fragment with roll of 100");
          return;
        }
      if (rolls[0] == 0)
        {
          yyerror ("background has fragment with roll of 0");
          return;
        }
    }
}

void WriteGenerationNotice()
{
  fprintf (arguments.rcc.outfile,
	   "/* The following was generated by the %s race & class compiler \n"
           "   (%s-rcc %s) on %s. \n", 
           PACKAGE_NAME, GAME_NAME, VERSION, __DATE__);
  fprintf (arguments.rcc.outfile,"\n\
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
  fprintf (arguments.rcc.outfile,
	   "*/\n\n");
  return;
}

void 
PutClass (char *s, class_template_t *tmpl_P, int consistency_check)
{
  generic_t gval;

  gval.v = malloc (sizeof(class_template_t));
  *(class_template_t *) gval.v = *tmpl_P;

  if (!tmpl_P->def.hit_points)
    NotDefined (tmpl_P->val.c.title, "HIT_POINTS");
  if (!tmpl_P->def.disarming)
    NotDefined (tmpl_P->val.c.title, "DISARMING");
  if (!tmpl_P->def.search_chance)
    NotDefined (tmpl_P->val.c.title, "SEARCH_CHANCE");
  if (!tmpl_P->def.stealth_factor)
    NotDefined (tmpl_P->val.c.title, "STEALTH_FACTOR");
  if (!tmpl_P->def.frequency_of_search)
    NotDefined (tmpl_P->val.c.title, "FREQUENCY_OF_SEARCH");
  if (!tmpl_P->def.base_to_hit)
    NotDefined (tmpl_P->val.c.title, "BASE_TO_HIT");
  if (!tmpl_P->def.base_to_hit_with_bows)
    NotDefined (tmpl_P->val.c.title, "BASE_TO_HIT_WITH_BOWS");
  if (!tmpl_P->def.saving_throw)
    NotDefined (tmpl_P->val.c.title, "SAVING_THROW");
  if (!tmpl_P->def.strength_modifier)
    NotDefined (tmpl_P->val.c.title, "STRENGTH_MODIFIER");
  if (!tmpl_P->def.intelligence_modifier)
    NotDefined (tmpl_P->val.c.title, "INTELLIGENCE_MODIFIER");
  if (!tmpl_P->def.wisdom_modifier)
    NotDefined (tmpl_P->val.c.title, "WISDOM_MODIFIER");
  if (!tmpl_P->def.dexterity_modifier)
    NotDefined (tmpl_P->val.c.title, "DEXTERITY_MODIFIER");
  if (!tmpl_P->def.constitution_modifier)
    NotDefined (tmpl_P->val.c.title, "CONSTITUTION_MODIFIER");
  if (!tmpl_P->def.charisma_modifier)
    NotDefined (tmpl_P->val.c.title, "CHARISMA_MODIFIER");
  if (!tmpl_P->def.experience_factor)
    NotDefined (tmpl_P->val.c.title, "EXPERIENCE_FACTOR");
  if (!tmpl_P->def.adjust_base_to_hit)
    NotDefined (tmpl_P->val.c.title, "ADJUST_BASE_TO_HIT");
  if (!tmpl_P->def.adjust_base_to_hit_with_bows)
    NotDefined (tmpl_P->val.c.title, "ADJUST_BASE_TO_HIT_WITH_BOWS");
  if (!tmpl_P->def.adjust_use_device)
    NotDefined (tmpl_P->val.c.title, "ADJUST_USE_DEVICE");
  if (!tmpl_P->def.adjust_disarming)
    NotDefined (tmpl_P->val.c.title, "ADJUST_DISARMING");
  if (!tmpl_P->def.adjust_saving_throw)
    NotDefined (tmpl_P->val.c.title, "ADJUST_SAVING_THROW");

  if (St_DefSym (classT_P, s, GEN_TYPE_TMPL, gval) == ST_SYM_FOUND) 
    {
      fprintf (arguments.rcc.outfile, "Warning: redefining \"%s\", line %d\n", 
               tmpl_P->val.c.title, lineNo);
    }

  return;
}

race_template_t* get_race(char *race)
{
  race_template_t *r;
  generic_t gval;
  int type;
  if (St_GetSym (raceT_P, race, &type, &gval) != ST_SYM_FOUND) 
    return NULL;
  r = (race_template_t*) gval.v;
  return r;
}

char *get_race_for_idx(int idx)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  St_SArgzTable (raceT_P, &argz, &argz_len);
  race_template_t *r;
  generic_t gval;
  int type;
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (raceT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        continue;
      r = (race_template_t*) gval.v;
      if (r->idx == idx)
        return r->val.r.trace;
    }
  return NULL;
}


void 
WriteConstants ()
{
  fprintf (arguments.rcc.outfile, "#ifndef RACE_CLASS_CONSTANT_H\n");
  fprintf (arguments.rcc.outfile, "#define RACE_CLASS_CONSTANT_H\n");

  fprintf (arguments.rcc.outfile, "#define MAX_PLAYER_LEVEL %3d    %s\n", 
           num_experience_levels, 
           "/* Maximum possible character level      */");
  if (num_experience_levels > 0)
    fprintf (arguments.rcc.outfile, "#define MAX_EXP  %10dL    %s\n", 
             experience_levels[num_experience_levels-1]-1,
             "/* Maximum amount of experience -CJS- */");
  else
    fprintf (arguments.rcc.outfile, "#define MAX_EXP   %10d    %s\n", 0,
             "/* Maximum amount of experience -CJS- */");
  fprintf (arguments.rcc.outfile, "#define MAX_RACES      %5d    %s\n", 
           St_TableSize(raceT_P),
           "/* Number of defined races               */");
  fprintf (arguments.rcc.outfile, "#define MAX_CLASS      %5d    %s\n", 
           St_TableSize(classT_P),
           "/* Number of defined classes             */");

  int num_backgrounds = 0;
  int i;
  int num_races = St_TableSize(raceT_P);
  for (i = 0; i < num_races; i++)
    {
      char *race = get_race_for_idx(i);
      if (!race)
        continue;
      race_template_t *r = get_race(race);
      num_backgrounds += r->val.num_backgrounds;
    }
  fprintf (arguments.rcc.outfile, "#define MAX_BACKGROUND   %3d    %s\n",
           num_backgrounds, "/* Number of types of histories for univ */");
  fprintf (arguments.rcc.outfile, "#define MAX_OWNERS     %5d    %s\n", 
           num_shopkeeps, "/* Number of owners to choose from       */");
  fprintf (arguments.rcc.outfile, "#endif\n");
}

void CheckRace (race_template_t *race)
{
  int i;
  for (i = 0; i < race->val.num_price_adjust; i++)
    {
      generic_t gval;
      int type;
      if (St_GetSym (raceT_P, race->val.price_adjust[i].race, 
                     &type, &gval) != ST_SYM_FOUND) 
        {
          ErrMsgLineNo (xasprintf("unknown race `%s'", 
                                   race->val.price_adjust[i].race), 
                        race->line_no_for_price_adjust);
        }
    }
  if (race->val.num_price_adjust != St_TableSize(raceT_P))
    {
      ErrMsgLineNo ("missing races in store price adjust block", 
                    race->line_no_for_price_adjust);
    }
  
  char *entry = NULL;
  while ((entry = argz_next (race->val.classes_argz, race->val.classes_len, 
                             entry)))
    {
      generic_t gval;
      int type;
      if (St_GetSym (classT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          ErrMsgLineNo (xasprintf("unknown class `%s'", entry), 
                        race->line_no_for_classes);
        }
    }
}

int check_background_chart (int chart, background_type *b, int num, int *depth)
{
  //recursively check the chart until we get zero, or loop too many times.
  //or we don't find a chart.
  int i;
  int found = 0;
  int next = -1;
  for (i = 0; i < num; i++)
    {
      if (b[i].chart == chart)
        {
          next = b[i].next;
          found = 1;
        }
    }
  if (!found)
    return -1;
  *depth  = *depth + 1;
  if (*depth > num)
    return -2;
  for (i = 0; i < num; i++)
    {
      if (b[i].chart == next)
        {
          found = 1;
          break;
        }
    }
  if (!found)
    return -3;
  else if (next == 0)
    return 0;
  else
    return check_background_chart (next, b, num, depth);
}

int is_starting_chart(int chart)
{
  int i;
  int num_races = St_TableSize(raceT_P);
  for (i = 0; i < num_races; i++)
    {
      char *race = get_race_for_idx(i);
      if (!race)
        continue;
      race_template_t *r = get_race(race);
      if (r->val.num_backgrounds && r->val.backgrounds[0].chart == chart)
        return 1;
    }
  return 0;
}

void CheckRaces()
{
  char *argz = NULL;
  size_t argz_len = 0;;
  char *entry = NULL;
  int type;
  int num_races = St_TableSize(raceT_P);
  if (num_races == 0)
    {
      ErrMsgLineNo("no race blocks found", -1);
      return;
    }
  generic_t gval;
  St_SArgzTable (raceT_P, &argz, &argz_len);
  race_template_t *r;
  int num_backgrounds = 0;
  int starting_chart[num_races];
  int race_count = 0;
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (raceT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in CheckRaces\n");
          exit (1);
        }
      r = (race_template_t *) gval.v;
      CheckRace(r);
      num_backgrounds += r->val.num_backgrounds;
      starting_chart[race_count] = r->val.backgrounds[0].chart;
      race_count++;
    }

  //collect the backgrounds into a single array
  entry = NULL;
  if (num_backgrounds)
    {
      int count = 0;
      int i;
      background_type backgrounds[num_backgrounds];
      while ((entry = argz_next (argz, argz_len, entry)))
        {
          if (St_GetSym (raceT_P, entry, &type, &gval) != ST_SYM_FOUND) 
            continue;
          r = (race_template_t *) gval.v;
          for (i = 0; i < r->val.num_backgrounds; i++)
            {
              backgrounds[count] = r->val.backgrounds[i];
              count++;
            }
        }
      for (i = 0; i < num_races; i++)
        {
          int depth = 0;
          int chart = starting_chart[i];
          if (check_background_chart(chart, backgrounds, num_backgrounds, &depth))
            ErrMsgLineNo (xasprintf ("background %d isn't complete, or loops infinitely", chart), -1);
        }

      int j;
      //every next needs a chart except for 0.
      for (i = 0; i < num_backgrounds; i++)
        {
          if (backgrounds[i].next == 0)
            continue;
          int found = 0;
          for (j = 0; j < num_backgrounds; j++)
            {
              if (backgrounds[j].chart == backgrounds[i].next)
                {
                  found = 1;
                  break;
                }
            }
          if (!found)
            {
              ErrMsgLineNo(xasprintf("background %d points to non-existent next", backgrounds[i].chart), -1);
              break;
            }
        }
        //each chart needs a next that points to it except for starting ones.
      for (i = 0; i < num_backgrounds; i++)
        {
          if (is_starting_chart(backgrounds[i].chart))
            continue;
          int found = 0;
          for (j = 0; j < num_backgrounds; j++)
            {
              if (backgrounds[j].next == backgrounds[i].chart)
                {
                  found = 1;
                  break;
                }
            }
          if (!found)
            {
              ErrMsgLineNo(xasprintf("background %d doesn't have another background pointing to it", backgrounds[i].chart), -1);
              break;
            }
        }
    }

  int shopkeeps[MAX_STORES];
  memset (shopkeeps, 0, sizeof (shopkeeps));
//check for one shopkeep for every pstore.
  entry = NULL;
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      int i;
      if (St_GetSym (raceT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        continue;
      r = (race_template_t *) gval.v;
      for (i = 0; i < r->val.num_shopkeeps; i++)
        shopkeeps[r->val.shopkeeps[i].pstore]++;
    }
  int j;
  for (j = 0; j < MAX_STORES; j++)
    if (shopkeeps[j] == 0)
      ErrMsgLineNo (xasprintf ("store '%c' doesn't have any shopkeeps", 
                               j + '1'), -1);
}

void CheckClass(class_template_t *c)
{
  if (c->val.num_spells && c->val.num_prayers)
    {
      ErrMsgLineNo(xasprintf("Class `%s' can't have both spells and prayers", c->val.c.title), -1);
    }
  int i;
  int max_levels = num_experience_levels;
  for (i = 0; i < c->val.num_spells; i++)
    {
      if (c->val.spells[i].s.slevel > max_levels)
        ErrMsgLineNo(xasprintf("spell has level exceeding %d", max_levels), c->val.spells[i].line_no);
    }
  for (i = 0; i < c->val.num_prayers; i++)
    {
      if (c->val.prayers[i].s.slevel > max_levels)
        ErrMsgLineNo(xasprintf("prayer has level exceeding %d", max_levels), c->val.prayers[i].line_no);
    }
  if (num_experience_levels != 
      argz_count (c->val.titles_argz, c->val.titles_len))
    {
      ErrMsgLineNo(xasprintf("%d titles given for `%s' but need %d",
                             argz_count(c->val.titles_argz, c->val.titles_len),
                             c->val.c.title, max_levels), -1);
    }

    //is this class referenced by a race?
    int found = 0;
    int num_races = St_TableSize(raceT_P);
    for (i = 0; i < num_races; i++)
      {
        char *race = get_race_for_idx(i);
        if (!race)
          continue;
        race_template_t *r = get_race(race);
        char *argz = r->val.classes_argz;
        size_t len = r->val.classes_len;
        char *cl = NULL;
        while ((cl = argz_next (argz, len, cl)))
          {
            if (strcmp (cl, c->val.c.title) == 0)
              {
                found = 1;
                break;
              }
          }
        if (found)
          break;
      }
      if (!found)
        ErrMsgLineNo(xasprintf("class `%s' is not referenced by any race's "
                               "classes block.", c->val.c.title), -1);
}

void CheckClasses()
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  generic_t gval;
  St_SArgzTable (classT_P, &argz, &argz_len);
  class_template_t *c;
  int num_classes = St_TableSize(classT_P);
  if (num_classes == 0)
    {
      ErrMsgLineNo("no class blocks found", -1);
      return;
    }
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (classT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        {
          fprintf (stderr, "internal err. in CheckClasses\n");
          exit (1);
        }
      c = (class_template_t *) gval.v;
      CheckClass(c);
    }
}

void WriteExperienceTable()
{
  int i;
  fprintf (arguments.rcc.outfile, "/* Base experience levels, may be adjusted"
                                  " up for race and/or class*/\n");
  fprintf (arguments.rcc.outfile, "int32u player_exp[MAX_PLAYER_LEVEL] = {");
  for (i = 0; i < num_experience_levels; i++)
    {
      if (i % 8 == 0)
        fprintf (arguments.rcc.outfile, "\n  ");
      else
        fprintf (arguments.rcc.outfile, " ");
      if (experience_levels[i] >= 32768)
        fprintf (arguments.rcc.outfile, "%dL,", experience_levels[i]);
      else
        fprintf (arguments.rcc.outfile, "%d,", experience_levels[i]);
    }
  fprintf (arguments.rcc.outfile, "\n};\n\n");
}

int sort_by_pstore (const void *s1, const void *s2)
{
  owner_type *lowner = (owner_type*) s1;
  owner_type *rowner = (owner_type*) s2;
  return lowner->pstore - rowner->pstore;
}

void WriteShopkeepTable()
{
  //dump all the shopkeeps from each race into an array
  owner_type shopkeeps[num_shopkeeps];

  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  int type;
  int count = 0;
  int i, j, k;
  generic_t gval;
  St_SArgzTable (raceT_P, &argz, &argz_len);
  race_template_t *r;
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (raceT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        continue;
      r = (race_template_t *) gval.v;
      for (i = 0; i < r->val.num_shopkeeps; i++)
        {
          shopkeeps[count] = r->val.shopkeeps[i];

          count++;
        }
    }
  qsort (shopkeeps, num_shopkeeps, sizeof (owner_type), sort_by_pstore);

  fprintf (arguments.rcc.outfile, "/* Store owners have different characteristics for pricing and haggling*/\n");
  fprintf (arguments.rcc.outfile, "owner_type owners[MAX_OWNERS] = {\n");
  owner_type *o = NULL;
  int last_idx[MAX_STORES];
  memset (last_idx, 0, sizeof (last_idx));
  //here we make an attempt to dump out the shopkeeps in groups of 6.
  for (k = 0; k < num_shopkeeps; k++)
    {
      for (i = 0; i < MAX_STORES; i++)
        {
          for (j = last_idx[i]; j < num_shopkeeps; j++)
            {
              o = &shopkeeps[j];
              if (o->pstore != i)
                continue;
              fprintf (arguments.rcc.outfile, "  {\"%s\",\n", o->owner_name);
              fprintf (arguments.rcc.outfile, 
                       "   %d, %d, %d, %d, %d, %d, %d},\n", 
                       o->max_cost, o->max_inflate, o->min_inflate, 
                       o->haggle_per, o->owner_race, o->insult_max, o->pstore);
              last_idx[i] = j + 1;
              break;
            }
        }
    }
  fprintf (arguments.rcc.outfile, "};\n\n");

}

char *get_short_name_for_race(char *race)
{
  if (strcmp (race, "Half-Elf") == 0)
    return strdup ("HfE");
  else if (strcmp (race, "Halfling") == 0)
    return strdup ("Hal");
  else if (strcmp (race, "Half-Orc") == 0)
    return strdup ("HfO");
  else if (strcmp (race, "Half-Troll") == 0)
    return strdup ("HfT");
  else
    {
      char nam[4];
      memset(nam, 0, sizeof (nam));
      strncpy (nam, race, 3);
      return strdup (nam);
    }
}

int get_idx_for_race(char *race)
{
  race_template_t *r;
  generic_t gval;
  int type;
  if (St_GetSym (raceT_P, race, &type, &gval) != ST_SYM_FOUND) 
    return -1;
  r = (race_template_t*) gval.v;
  return r->idx;
}

void WriteShopkeepRacePriceAdjustmentTable()
{
  fprintf (arguments.rcc.outfile, 
           "/* Buying and selling adjustments "
           "for character race VS store   */\n");
  fprintf (arguments.rcc.outfile, 
           "/* owner race                     "
           "                               */\n");
  fprintf (arguments.rcc.outfile, 
           "int8u rgold_adj[MAX_RACES][MAX_RACES] = {\n");

  int num_races = St_TableSize(raceT_P);
  int i, j, k;
  fprintf (arguments.rcc.outfile, "%18s/* ", "");
  for (i = 0; i < num_races; i++)
    {
      char *race = get_race_for_idx(i);
      if (race)
        {
          char *s = get_short_name_for_race(race);
          fprintf (arguments.rcc.outfile, "%-3s", s);
          if (i != num_races - 1)
            fprintf (arguments.rcc.outfile, ", ");
          free (s);
        }
    }
  fprintf (arguments.rcc.outfile, " */\n");
  for (i = 0; i < num_races; i++)
    {
      char *argz = NULL;
      size_t argz_len = 0;
      char *entry = NULL;
      St_SArgzTable (raceT_P, &argz, &argz_len);
      race_template_t *r;
      generic_t gval;
      int type;
      while ((entry = argz_next (argz, argz_len, entry)))
        {
          if (St_GetSym (raceT_P, entry, &type, &gval) != ST_SYM_FOUND) 
            continue;
          r = (race_template_t*) gval.v;
          if (r->idx == i)
            {
              fprintf (arguments.rcc.outfile, "/*%-15s*/ {", r->val.r.trace);
              for (j = 0; j < num_races; j++)
                {
                  for (k = 0; k < r->val.num_price_adjust; k++)
                    {
                      if (get_idx_for_race(r->val.price_adjust[k].race) == j)
                        {
                          fprintf (arguments.rcc.outfile, "%3d", 
                                   r->val.price_adjust[k].price);
                          if (j != num_races - 1)
                            fprintf (arguments.rcc.outfile, ", ");
                        }
                    }
                }
              fprintf (arguments.rcc.outfile, "}");
              if (r->idx != num_races - 1)
                fprintf (arguments.rcc.outfile, ",");
              fprintf (arguments.rcc.outfile, "\n");
            }
        }
      free(argz);
    }
  fprintf (arguments.rcc.outfile, "};\n\n");
}

class_template_t* get_class(char *class)
{
  class_template_t *c;
  generic_t gval;
  int type;
  if (St_GetSym (classT_P, class, &type, &gval) != ST_SYM_FOUND) 
    return NULL;
  c = (class_template_t*) gval.v;
  return c;
}

char *get_class_for_idx(int idx)
{
  char *argz = NULL;
  size_t argz_len = 0;
  char *entry = NULL;
  St_SArgzTable (classT_P, &argz, &argz_len);
  class_template_t *c;
  generic_t gval;
  int type;
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (classT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        continue;
      c = (class_template_t*) gval.v;
      if (c->idx == idx)
        return c->val.c.title;
    }
  return NULL;
}

void WriteTitlesForClass(char *argz, size_t len)
{
  char *entry = NULL;
  int count = 0;
  int col_count = 0;
  int first = 1;
  while ((entry = argz_next (argz, len, entry)))
    {
      if (col_count + strlen (entry) + 4 > 80)
        {
          fprintf (arguments.rcc.outfile, "\n");
          col_count = 0;
        }
      if (col_count == 0)
        {
          if (first)
            {
              fprintf (arguments.rcc.outfile, "  {");
              first = 0;
            }
          else
            fprintf (arguments.rcc.outfile, "   ");
          col_count+=3;
        }
      fprintf (arguments.rcc.outfile, "\"%s\"", entry);
      col_count += strlen (entry) + 2;
      if (count != num_experience_levels -1)
        {
          fprintf (arguments.rcc.outfile, ", ");
          col_count += 2;
        }
      count++;
      if (count == num_experience_levels)
        fprintf (arguments.rcc.outfile, "},\n");
    }
}

void WriteClassTitles()
{
  int i;
  int num_classes = St_TableSize(classT_P);
  fprintf (arguments.rcc.outfile, 
           "/* Class titles for different levels"
           "                            */\n");
  fprintf (arguments.rcc.outfile,
           "char *player_title[MAX_CLASS][MAX_PLAYER_LEVEL] = {\n");
  for (i = 0; i < num_classes; i++)
    {
      char *class = get_class_for_idx(i);
      if (!class)
        continue;
      class_template_t *c = get_class(class);
      fprintf (arguments.rcc.outfile, "  /* %-13s */\n", class);
      WriteTitlesForClass(c->val.titles_argz, c->val.titles_len);
    }
  fprintf (arguments.rcc.outfile, "};\n\n");
}
      
void WriteRaceTable()
{
  fprintf (arguments.rcc.outfile, "/*  Race  STR,INT,WIS,DEX,CON,CHR, \n");
  fprintf (arguments.rcc.outfile, 
           "    Ages, heights, and weights (male then female)\n");
  fprintf (arguments.rcc.outfile, 
           "    Racial Bases for: dis,srh,stl,fos,bth,bthb,bsav,hitdie,\n");
  fprintf (arguments.rcc.outfile, 
           "    infra, exp base, choice-classes */\n");
  fprintf (arguments.rcc.outfile, "race_type race[MAX_RACES] = {\n");
  int i;
  int num_races = St_TableSize(raceT_P);
  for (i = 0; i < num_races; i++)
    {
      char *race = get_race_for_idx(i);
      if (!race)
        continue;
      race_template_t *r = get_race(race);
      fprintf (arguments.rcc.outfile, 
               "  {\"%s\", %hd, %hd, %hd, %hd, %hd, %hd,\n",
               r->val.r.trace, r->val.r.str_adj, r->val.r.int_adj, 
               r->val.r.wis_adj, r->val.r.dex_adj, r->val.r.con_adj,
               r->val.r.chr_adj);
      fprintf (arguments.rcc.outfile,  "   "
               "%hhu, %hhu, %hhu, %hhu, %hhu, %hhu, %hhu, %hhu, %hhu, %hhu,\n",
               r->val.r.b_age, r->val.r.m_age, r->val.r.m_b_ht, 
               r->val.r.m_m_ht, r->val.r.m_b_wt, r->val.r.m_m_wt,
               r->val.r.f_b_ht, r->val.r.f_m_ht, r->val.r.f_b_wt,
               r->val.r.f_m_wt);
      fprintf (arguments.rcc.outfile, "   "
               "%hd, %hd, %hd, %hd, %hd, %hd, %hd, %hhu, %hhu, %hhu, 0x%08X,\n",
                r->val.r.b_dis, r->val.r.srh, r->val.r.stl, r->val.r.fos,
                r->val.r.bth, r->val.r.bthb, r->val.r.bsav, r->val.r.bhitdie,
                r->val.r.infra, r->val.r.b_exp, r->val.r.rtclass);
      fprintf (arguments.rcc.outfile, "   },\n");
    }
  fprintf (arguments.rcc.outfile, "};\n\n");

}

int get_min_spell_level(class_template_t *c)
{
  int min = num_experience_levels + 1;
  int i;
  for (i = 0; i < c->val.num_spells; i++)
    if (c->val.spells[i].s.slevel < min)
      min = c->val.spells[i].s.slevel;
  for (i = 0; i < c->val.num_prayers; i++)
    if (c->val.prayers[i].s.slevel < min)
      min = c->val.prayers[i].s.slevel;
  if (min == num_experience_levels + 1)
    return 0;
  return min;
}

void WriteClassTable()
{
  fprintf (arguments.rcc.outfile,
           "/* Classes.                       "
           "                              */\n");
  fprintf (arguments.rcc.outfile, "class_type class[MAX_CLASS] = {\n");
  fprintf (arguments.rcc.outfile, "/*%-11s HP Dis Src Stl Fos bth btb sve  "
                                  "S  I  W  D Co Ch Spell Exp spl */\n", "");
  int i;
  int num_classes = St_TableSize(classT_P);
  for (i = 0; i < num_classes; i++)
    {
      char *class = get_class_for_idx(i);
      if (!class)
        continue;
      class_template_t *c = get_class(class);
      char *name = xasprintf ("\"%s\",", c->val.c.title);
      char *spells = "NONE,";
      if (c->val.num_prayers)
        spells = "PRIEST,";
      else if (c->val.num_spells)
        spells = "MAGE,";
      int min_spell_level = get_min_spell_level(c);
      fprintf (arguments.rcc.outfile, "  {%-10s "
               "%2hhu, %2hhu, %2hhu, %2hhu, %2hhu, %2hhu, %2hhu, %2hhu,"
               "%2hd,%2hd,%2hd,%2hd,%2hd,%2hd,%-7s%2hhu, %2d}", 
               name, c->val.c.adj_hd, c->val.c.mdis, c->val.c.msrh, 
               c->val.c.mstl, c->val.c.mfos, c->val.c.mbth, c->val.c.mbthb,
               c->val.c.msav, c->val.c.madj_str, c->val.c.madj_int,
               c->val.c.madj_wis, c->val.c.madj_dex, c->val.c.madj_con,
               c->val.c.madj_chr, spells, c->val.c.m_exp, min_spell_level);
      if (i != num_classes - 1)
        fprintf (arguments.rcc.outfile, ",");
      fprintf (arguments.rcc.outfile, "\n");
      free (name);
    }
  fprintf (arguments.rcc.outfile, "};\n\n");
}
      
void WriteClassLevelAdjustmentTable()
{
  fprintf (arguments.rcc.outfile,
           "/* making it 16 bits wastes a little space, but saves "
           "much signed/unsigned\n");
  fprintf (arguments.rcc.outfile,
           "   headaches in its use */\n");
  fprintf (arguments.rcc.outfile,
           "/* CLA_MISC_HIT is identical to CLA_SAVE, "
           "which takes advantage of\n");
  fprintf (arguments.rcc.outfile, "   "
           "the fact that the save values are independent of the class */\n");
  fprintf (arguments.rcc.outfile, 
           "int16 class_level_adj[MAX_CLASS][MAX_LEV_ADJ] = {\n");
  fprintf (arguments.rcc.outfile, 
           "/*%-13sbth bthb  devices disarm save/misc hit  */\n", "");
  int i;
  int num_classes = St_TableSize(classT_P);
  for (i = 0; i < num_classes; i++)
    {
      char *class = get_class_for_idx(i);
      if (!class)
        continue;
      class_template_t *c = get_class(class);
      fprintf (arguments.rcc.outfile, 
               "/* %-7s */ {%3hd, %3hd, %7hd, %5hd, %12hd}", 
               c->val.c.title, c->val.adjust_per_one_third_level[0],
               c->val.adjust_per_one_third_level[1],
               c->val.adjust_per_one_third_level[2],
               c->val.adjust_per_one_third_level[3],
               c->val.adjust_per_one_third_level[4]);
      if (i != num_classes -1)
        fprintf (arguments.rcc.outfile, ",");
      fprintf (arguments.rcc.outfile, "\n");
    }
  fprintf (arguments.rcc.outfile, 
           "};\n\n");
}

void FillClassFlagsInRaces()
{
  //here we take the list of named allowable classes for each race,
  //and we fill in the bitwise field "race_type.rtclass"
  char *argz = NULL;
  size_t argz_len = 0;
  const char *entry = NULL;
  int type;
  int num_races = St_TableSize(raceT_P);
  generic_t gval;
  St_SArgzTable (raceT_P, &argz, &argz_len);
  race_template_t *r;
  while ((entry = argz_next (argz, argz_len, entry)))
    {
      if (St_GetSym (raceT_P, entry, &type, &gval) != ST_SYM_FOUND) 
        continue;
      r = (race_template_t *) gval.v;
      char *cl = NULL;
      while ((cl = argz_next (r->val.classes_argz, r->val.classes_len, cl)))
        {
          class_template_t *c = get_class(cl);
          if (!c)
            continue;
          int mask = (int) pow (2, c->idx);
          r->val.r.rtclass |= mask;
        }
    }
}
      
int sort_by_chart_and_roll (const void *lhs, const void *rhs)
{
  background_type *l = (background_type*) lhs;
  background_type *r = (background_type*) rhs;
  int diff = l->chart - r->chart;
  if (diff == 0)
    diff = l->roll - r->roll;
  return diff;
}

void WriteBackgrounds()
{
  int num_backgrounds = 0;
  int i;
  int num_races = St_TableSize(raceT_P);
  fprintf (arguments.rcc.outfile, "/* Background information"
           "                                       */\n");
  fprintf (arguments.rcc.outfile,
           "int background_start[MAX_RACES] = { "
           "/* starting .chart not index */\n");
  for (i = 0; i < num_races; i++)
    {
      char *race = get_race_for_idx(i);
      if (!race)
        continue;
      race_template_t *r = get_race(race);
      int start = 0;
      if (r->val.num_backgrounds)
        start = r->val.backgrounds[0].chart;
      fprintf (arguments.rcc.outfile, "  %3d, /* %s */\n", 
               start, r->val.r.trace);
      num_backgrounds += r->val.num_backgrounds;
    }
  fprintf (arguments.rcc.outfile, "};\n\n");

  //collect all of the backgrounds into an array and sort them
  background_type backgrounds[num_backgrounds];
  int count = 0;
  int j;
  for (i = 0; i < num_races; i++)
    {
      char *race = get_race_for_idx(i);
      if (!race)
        continue;
      race_template_t *r = get_race(race);
      for (j = 0; j < r->val.num_backgrounds; j++)
        {
          backgrounds[count] = r->val.backgrounds[j];
          count++;
        }
    }
  qsort (backgrounds, num_backgrounds, sizeof (background_type), 
         sort_by_chart_and_roll);
   //okay, dump them out
  fprintf (arguments.rcc.outfile, 
           "background_type background[MAX_BACKGROUND] = {\n");
  for (i = 0; i < num_backgrounds; i++)
    {
      background_type b = backgrounds[i];
      fprintf (arguments.rcc.outfile, 
               "  {\"%s\", %hhu, %hhu, %hhu, %hhu}",
               b.info, b.roll, b.chart, b.next, b.bonus);
      if (i != num_backgrounds - 1)
        fprintf (arguments.rcc.outfile, ",");
      fprintf (arguments.rcc.outfile, "\n");
    }
  fprintf (arguments.rcc.outfile, "};\n\n");
}
      
void WriteClassSpells(spell_t *spells, int num)
{
  int i, j;
  int max = MAX_SPELLS;
  for (i = 0; i < max; i++)
    {
      int found = 0;
      for (j = 0; j < num; j++)
        {
          if (spells[j].idx == i)
            {
              fprintf (arguments.rcc.outfile, "   {%hhu, %hhu, %hhu, %hhu}",
                       spells[j].s.slevel, spells[j].s.smana, 
                       spells[j].s.sfail, spells[j].s.sexp);
              found = 1;
              break;
            }
        }
      if (!found)
        fprintf (arguments.rcc.outfile, "   {MAX_SPELLS, MAX_SPELLS, 0, 0}");
      if (i != max - 1)
        fprintf (arguments.rcc.outfile, ",");
      fprintf (arguments.rcc.outfile, "\n");
    }
}

void WriteSpells()
{
  fprintf (arguments.rcc.outfile,
           "spell_type magic_spell[MAX_CLASS][MAX_SPELLS] = {\n");
  int num_classes = St_TableSize(classT_P);
  int i, j;
  for (i = 0; i < num_classes; i++)
    {
      char *class = get_class_for_idx(i);
      if (!class)
        continue;
      class_template_t *c = get_class(class);
      fprintf (arguments.rcc.outfile, 
               "  {%-29s /* %-13s */\n", "", c->val.c.title);
      if (c->val.num_spells)
        WriteClassSpells(c->val.spells, c->val.num_spells);
      else if (c->val.num_prayers)
        WriteClassSpells(c->val.prayers, c->val.num_prayers);
      else
        WriteClassSpells(c->val.spells, 0);
      fprintf (arguments.rcc.outfile, "   }");
      if (i != num_classes - 1)
        fprintf (arguments.rcc.outfile, ",");
      fprintf (arguments.rcc.outfile, "\n");
    }
  fprintf (arguments.rcc.outfile,"};\n\n");
}

int
rcc_main (char *inputFilename)
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

  FillClassFlagsInRaces();
  if (arguments.rcc.consistency_check)
    {
      CheckRaces();
      CheckClasses();
    }
  WriteGenerationNotice();
  if (arguments.rcc.only_generate_constants)
    WriteConstants ();
  else
    {
      fprintf (arguments.rcc.outfile, "#include \"constant.h\"\n");
      fprintf (arguments.rcc.outfile, "#include \"types.h\"\n\n");
      WriteShopkeepTable();
      WriteShopkeepRacePriceAdjustmentTable();
      WriteClassTitles();
      WriteExperienceTable();
      WriteRaceTable();
      WriteClassTable();
      WriteClassLevelAdjustmentTable();
      WriteBackgrounds();
      WriteSpells();
    }

  return 0;
}
