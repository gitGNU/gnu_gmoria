/* creature.y: a Moria creature definition compiler

   Copyright (c) 1989 Joseph Hall
   Copyright (C) 2005, 2010 Ben Asselstine
   Written by Ben Asselstine

   mc is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   mc is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with mc; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

%{
#include "config.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <netinet/in.h>

#include "st.h"
#include "opts.h"
#include "creature.h"
#include "mcheck.h"




/*
 * defined_t is used to indicate whether all fields have been defined
 */

typedef struct {
    unsigned	move: 1,
		special: 1,
		treasure: 1,
		spell: 1,
		breath: 1,
		resist: 1,
		defense: 1,
		mexp: 1,
		sleep: 1,
		aaf: 1,
		ac: 1,
		speed: 1,
		cchar: 1,
		hd: 1,
		damage: 1,
		level: 1;
} defined_t;



/*
 * template_t contains creature definition & flags
 */

typedef struct 
{
  int idx;
  creature_type	val;
  defined_t def;
} template_t;




/*
 * symInit_t is used to initialize symbol tables with integer values
 */

typedef struct 
{
  char *name;
  int32u val;
} symInit_t;



static symInit_t 
defenseInit[] = 
{
    { "dragon", 0 },
    { "animal", 1 },
    { "evil", 2 },
    { "undead", 3 },
    { "frost", 4 },
    { "fire", 5 },
    { "poison", 6 },
    { "acid", 7 },
    { "light", 8 },
    { "stone", 9 },
    { "bit_9", 10 },
    { "bit_10", 11 },
    { "no_sleep", 12 },
    { "infra", 13 },
    { "max_hp", 14 },
    { "bit_15", 15 },
    { NULL, 0 }
};

static symInit_t 
moveInit[] = 
{
    { "attack_only", 0 },
    { "move_normal", 1 },
    { "magic_only", 2 },
    { "random_20", 3 },
    { "random_40", 4 },
    { "random_75", 5 },
    { NULL, 0 }
};

static symInit_t 
specialInit[] = 
{
    { "invisible", 16 },
    { "open_door", 17 },
    { "phase", 18 },
    { "eats_other", 19 },
    { "picks_up", 20 },
    { "multiply", 21 },
    { "win_creature", 31 },
    { NULL, 0 }
};

static symInit_t 
treasureInit[] = 
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
spellInit[] = 
{
    { "tel_short", 4 },
    { "tel_long", 5 },
    { "tel_to", 6 },
    { "lght_wnd", 7 },
    { "ser_wnd", 8 },
    { "hold_per", 9 },
    { "blind", 10 },
    { "confuse", 11 },
    { "fear", 12 },
    { "summon_mon", 13 },
    { "summon_und", 14 },
    { "slow_per", 15 },
    { "drain_mana", 16 },
    { "bit_17", 17 },
    { "bit_18", 18 },
    { NULL, 0 }
};

static symInit_t 
breathInit[] = 
{
    { "light", 19 },
    { "gas", 20 },
    { "acid", 21 },
    { "frost", 22 },
    { "fire", 23 },
    { NULL, 0 }
};

static symInit_t 
attackTypeInit[] = 
{
    { "normal_damage", 1 },
    { "lose_str", 2 },
    { "confusion", 3 },
    { "cause_fear", 4 },
    { "fire_damage", 5 },
    { "acid_damage", 6 },
    { "cold_damage", 7 },
    { "lightning_damage", 8 },
    { "corrosion", 9 },
    { "cause_blindness", 10 },
    { "cause_paralysis", 11 },
    { "steal_money", 12 },
    { "steal_obj", 13 },
    { "poison", 14 },
    { "lose_dex", 15 },
    { "lose_con", 16 },
    { "lose_int", 17 },
    { "lose_wis", 18 },
    { "lose_exp", 19 },
    { "aggravation", 20 },
    { "disenchant", 21 },
    { "eat_food", 22 },
    { "eat_light", 23 },
    { "eat_charges", 24 },
    { "blank", 99 },
    { NULL, 0 }
};

static symInit_t 
attackDescInit[] = 
{
    { "hits", 1 },
    { "bites", 2 },
    { "claws", 3 },
    { "stings", 4 },
    { "touches", 5 },
    { "kicks", 6 },
    { "gazes", 7 },
    { "breathes", 8 },
    { "spits", 9 },
    { "wails", 10 },
    { "embraces", 11 },
    { "crawls_on", 12 },
    { "releases_spores", 13 },
    { "begs_for_money", 14 },
    { "slimes", 15 },
    { "crushes", 16 },
    { "tramples", 17 },
    { "drools_on", 18 },
    { "insults", 19 },
    { "is_repelled", 99 },
    { NULL, 0 }
};





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

static template_t blankTemplate;	/* blank template for init-ing     */
static template_t tmpTemplate;		/* working template for current     */
					/* class or creature		    */

#define MAX_ATTACK 250
static m_attack_type attackList[MAX_ATTACK];
static m_attack_type sorted_attackList[MAX_ATTACK];
static int attackCt = 1;
static int creatureAttacks = 0;
static int maxCreatureLevel = 0;

/*
 * Global symbol tables
 */

static st_Table_Pt keywordT_P;		/* parser's keywords		    */
static st_Table_Pt defenseT_P;		/* defense flags		    */
static st_Table_Pt moveT_P;		/* movement flags		    */
static st_Table_Pt specialT_P;		/* special flags		    */
static st_Table_Pt treasureT_P;		/* treasure flags		    */
static st_Table_Pt spellT_P;		/* spell flags			    */
static st_Table_Pt breathT_P;		/* breath flags			    */
static st_Table_Pt attackTypeT_P;	/* attack type flags		    */
static st_Table_Pt attackDescT_P;	/* attack desc flags		    */
static st_Table_Pt classT_P;		/* class templates		    */
static st_Table_Pt creatureT_P;		/* creature definitions		    */

/*
 * Function declarations
 */

extern void AddDefense ();
extern void NegDefense ();
extern void AddMove ();
extern void NegMove ();
extern void AddTreasure ();
extern void NegTreasure ();
extern void AddSpecial ();
extern void NegSpecial ();
extern void AddSpell ();
extern void NegSpell ();
extern void AddBreath ();
extern void AddFreq ();
extern void NegBreath ();
extern void AddResist ();
extern void NegResist ();
extern void AddAttack ();
extern void AddUnusedAttack ();
extern void WriteCreature ();
extern void PutClassTemplate ();
extern template_t GetClassTemplate ();
extern int MergeClassTemplate (char *s, template_t *t1);
extern void PutCreature ();
extern int FindAttackCount (int8u *);

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

%token CLASS CREATURE UNUSED NAMED HD MOVE SPELL BREATH DEFENSE XP CCHAR SLEEP
%token RADIUS SPEED ATTACK FOR AC LEVEL TREASURE SPECIAL OF IN NOTHING
%token DESCRIPTION RESIST

%{
static symInit_t 
keywordInit[] = 
{
    { "class", CLASS },
    { "creature", CREATURE },
    { "unused", UNUSED},
    { "named", NAMED },
    { "hd", HD },
    { "move", MOVE },
    { "spell", SPELL },
    { "breath", BREATH },
    { "defense", DEFENSE },
    { "exp", XP },
    { "letter", CCHAR },
    { "sleep", SLEEP },
    { "radius", RADIUS },
    { "speed", SPEED },
    { "attack", ATTACK },
    { "for", FOR },
    { "ac", AC },
    { "level", LEVEL },
    { "treasure", TREASURE },
    { "special", SPECIAL },
    { "of", OF },
    { "in", IN },
    { "none", NOTHING },
    { "description", DESCRIPTION},
    { "resist", RESIST},
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


%start	creatures


/*
 * THE PARSER
 */

%%

creatures	:	class_def ';' creatures
		|	creature_def ';' creatures
                |       unused_def ';' creatures
		|	comment_def  creatures
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

class_def	:	CLASS IDENTIFIER parent_classes '{' features '}'
				{ PutClassTemplate($<sval>2, &tmpTemplate); }
		;

unused_def      :       UNUSED '{' unusedfeatures '}'
                ;

parent_classes	:	':' parent_class more_classes
		|	/* empty */
			{ tmpTemplate = blankTemplate;
			  creatureAttacks = 0; }
		;

parent_class	:	IDENTIFIER
				{ MergeClassTemplate ($<sval>1, &tmpTemplate);
				  creatureAttacks = 
				    FindAttackCount (tmpTemplate.val.damage); }
		|	/* empty */
				{ tmpTemplate = blankTemplate;
				  creatureAttacks = 0; }
		;


more_classes	:	',' parent_class more_classes
		|	/* empty */
		;

creature_def	:	CREATURE STRING_LIT parent_classes
			'{' features '}'
				{ tmpTemplate.val.name =
				    (char *) malloc(strlen($<sval>2) + 1);
				  strcpy(tmpTemplate.val.name, $<sval>2);
				  PutCreature($<sval>2, &tmpTemplate,
					      arguments.mc.consistency_check);
				  tmpTemplate = blankTemplate;
				}
		;

unusedfeatures	:	unusedfeature ';' unusedfeatures
		|	/* empty */
		;

unusedfeature	:	ATTACK ':' unusedattacks
                ;

features	:	feature ';' features
		|	/* empty */
		;

feature		:	LEVEL ':' INT_LIT
				{ tmpTemplate.val.level = $<ival>3;
				  tmpTemplate.def.level = TRUE; }
		|	HD ':' INT_LIT '|' INT_LIT
				{ tmpTemplate.val.hd[0] = $<ival>3;
				  tmpTemplate.val.hd[1] = $<ival>5;
				  tmpTemplate.def.hd = TRUE; }
		|	XP ':' INT_LIT
				{ tmpTemplate.val.mexp = $<ival>3;
				  tmpTemplate.def.mexp = TRUE; }
		|	CCHAR ':' STRING_LIT
				{ tmpTemplate.val.cchar = $<sval>3[0];
				  tmpTemplate.def.cchar = TRUE; }
		|	AC ':' INT_LIT
				{ tmpTemplate.val.ac = $<ival>3;
				  tmpTemplate.def.ac = TRUE; }
		|	SLEEP ':' INT_LIT
				{ tmpTemplate.val.sleep = $<ival>3;
				  tmpTemplate.def.sleep = TRUE; }
		|	RADIUS ':' INT_LIT
				{ tmpTemplate.val.aaf = $<ival>3;
				  tmpTemplate.def.aaf = TRUE; }
		|	SPEED ':' INT_LIT
				{ tmpTemplate.val.speed = $<ival>3 + 10;
				  tmpTemplate.def.speed = TRUE; }
		|	ATTACK ':' attacks
		|	MOVE ':' moves
		|	SPELL ':' spells
		|	SPELL INT_LIT '/' INT_LIT ':' spells
				{ 
                                  int i = $<ival>3;
                                  int j = $<ival>5;
				  AddFreq (i, j, "spell");
				}
  		|	BREATH ':' breaths
		|	BREATH INT_LIT '/' INT_LIT ':' breaths
				{ 
                                  int i = $<ival>3;
                                  int j = $<ival>5;
				  AddFreq (i, j, "breath");
				}
		|	RESIST ':' resists
		|	DEFENSE ':' defenses
		|	TREASURE ':' carries
		|	SPECIAL ':' specials
		|	DESCRIPTION ':' description
		;

description	:	STRING_LIT
		|	NOTHING
		;

unusedattacks	:	unusedattack more_unusedattacks
		;

unusedattack	:	IDENTIFIER FOR INT_LIT '|' INT_LIT OF IDENTIFIER
			{ AddUnusedAttack($<sval>1, $<ival>3, $<ival>5, $<sval>7); }
		|	NOTHING 
		;

more_unusedattacks	:	',' unusedattack more_unusedattacks
		|	/* empty */
		;

attacks		:	attack more_attacks
		;

attack		:	IDENTIFIER FOR INT_LIT '|' INT_LIT OF IDENTIFIER
			{ AddAttack($<sval>1, $<ival>3, $<ival>5, $<sval>7); }
		|	NOTHING 
				{
				  tmpTemplate.val.damage[0] = 0;
				  tmpTemplate.val.damage[1] = 0;
				  tmpTemplate.val.damage[2] = 0;
				  tmpTemplate.val.damage[3] = 0;
				  creatureAttacks = 0;
				  tmpTemplate.def.damage = TRUE; 
				}
		;

more_attacks	:	',' attack more_attacks
		|	/* empty */
		;

moves		:	move more_moves
		;

move		:	IDENTIFIER { AddMove($<sval>1); }
		|	'~' IDENTIFIER { NegMove($<sval>2); }
		|	NOTHING /* empty */
		;

more_moves	:	',' move more_moves
		|	/* empty */
		;

spells		:	spell more_spells
		|	/* empty */
		;

spell		:	IDENTIFIER { AddSpell($<sval>1); }
		|	'~' IDENTIFIER { NegSpell($<sval>2); }
		|	NOTHING /* empty */
		;

more_spells	:	',' spell more_spells
		|	/* empty */
		;

resists		:	resist more_resists
		;

resist		:	IDENTIFIER { AddResist($<sval>1); }
		|	'~' IDENTIFIER { NegResist($<sval>2); }
		|	NOTHING /* empty */
		;

more_resists	:	',' resist more_resists
		|	/* empty */
		;

breaths		:	breath more_breaths
		;

breath		:	IDENTIFIER { AddBreath($<sval>1); }
		|	'~' IDENTIFIER { NegBreath($<sval>2); }
		|	NOTHING /* empty */
		;

more_breaths	:	',' breath more_breaths
		|	/* empty */
		;

defenses	:	defense more_defenses
		;

defense		:	IDENTIFIER { AddDefense($<sval>1); }
		|	'~' IDENTIFIER { NegDefense($<sval>2); }
		|	NOTHING { tmpTemplate.def.defense = TRUE; }
		;

more_defenses	:	',' defense more_defenses
		|	/* empty */
		;

carries		:	carry more_carries
		;

carry		:	IDENTIFIER { AddTreasure($<sval>1); }
		|	'~' IDENTIFIER { NegTreasure($<sval>2); }
		|	NOTHING { tmpTemplate.def.treasure = TRUE; }
		;

more_carries	:	',' carry more_carries
		|	/* empty */
		;

specials	:	special more_specials
		;

special		:	IDENTIFIER { AddSpecial($<sval>1); }
		|	'~' IDENTIFIER { NegSpecial($<sval>2); }
		|	NOTHING /* empty */
		;

more_specials	:	',' special more_specials
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

void 
AddSpell (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (spellT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown spell '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      if (tmpTemplate.def.resist)
	{
	  sprintf (s1, "Setting spell '%s' when a resist is already set causes the resist to turn into breath which probably isn't want you want.", s);
	  ErrMsg (s1);
	}
      else
	{
	  tmpTemplate.val.spells |= (1 << gval.i);
	  tmpTemplate.def.spell = TRUE;
	}
    }
  return;
}


void 
NegSpell (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (spellT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown spell '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      tmpTemplate.val.spells &= ~(1 << gval.i);
      tmpTemplate.def.spell = TRUE;
    }
  return;
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

  if (strcmp (kind, "defense") == 0)
    table = defenseT_P;
  else if (strcmp (kind, "move") == 0)
    table = moveT_P;
  else if (strcmp (kind, "special") == 0)
    table = specialT_P;
  else if (strcmp (kind, "treasure") == 0)
    table = treasureT_P;
  else if (strcmp (kind, "spell") == 0)
    table = spellT_P;
  else if (strcmp (kind, "breath") == 0)
    table = breathT_P;
  else if (strcmp (kind, "resist") == 0)
    table = breathT_P;
  else if (strcmp (kind, "attacktype") == 0)
    table = attackTypeT_P;
  else if (strcmp (kind, "attackdesc") == 0)
    table = attackDescT_P;
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
AddResist (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (breathT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown resist '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      if ((tmpTemplate.def.breath) && 
	  ((tmpTemplate.val.spells & (1 << gval.i))) == 0)
	{
	  sprintf (s1, "4. Setting resist '%s' when non-identical breath already set causes %s-breath to be enabled which probably isn't want you want.", s, s);
	  ErrMsg (s1);
	}
      else if ((tmpTemplate.def.spell) && (tmpTemplate.def.breath == 0))
	{
	  sprintf (s1, "5. Setting resist '%s' when a spell frequency is already set causes %s-breath to be enabled which probably isn't want you want.", s, s);
	  ErrMsg (s1);
	}
      else
	{
	  tmpTemplate.val.spells |= (1 << gval.i);
	  tmpTemplate.def.resist = TRUE;
	}
    }
  return;
}


void 
NegResist (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (breathT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown resist '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      tmpTemplate.val.spells &= ~(1 << gval.i);
      tmpTemplate.def.resist = TRUE;
    }
  return;
}

void 
AddBreath (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (breathT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown breath '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      if ((tmpTemplate.def.resist) && 
	  ((tmpTemplate.val.spells & (1 << gval.i)) == 0))
	{
	  sprintf (s1, "6. Setting breath '%s' when non-identical resist was already set causes the resist to become a breath which probably isn't want you want.", s);
	  ErrMsg (s1);
	}
      else
	{
	  tmpTemplate.val.spells |= (1 << gval.i);
	  tmpTemplate.def.breath = TRUE;
	}
    }
  return;
}


void 
NegBreath (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (breathT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown breath '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      tmpTemplate.val.spells &= ~(1 << gval.i);
      tmpTemplate.def.breath = TRUE;
    }
  return;
}


void 
AddSpecial (char *s)
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
      tmpTemplate.val.cmove |= (1 << gval.i);
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
      tmpTemplate.val.cmove &= ~(1 << gval.i);
      tmpTemplate.def.special = TRUE;
    }
  return;
}

void AddMove(char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (moveT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown move '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      tmpTemplate.val.cmove |= (1 << gval.i);
      tmpTemplate.def.move = TRUE;
    }
  return;
}


void 
NegMove (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (moveT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown move '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      tmpTemplate.val.cmove &= ~(1 << gval.i);
      tmpTemplate.def.move = TRUE;
    }
  return;
}

void 
AddTreasure (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (treasureT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown treasure '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      tmpTemplate.val.cmove |= (1 << gval.i);
      tmpTemplate.def.treasure = TRUE;
    }
  return;
}


void 
NegTreasure (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (treasureT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown treasure '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      tmpTemplate.val.cmove &= ~(1 << gval.i);
      tmpTemplate.def.treasure = TRUE;
    }
  return;
}


void 
AddDefense (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (defenseT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown defense '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      tmpTemplate.val.cdefense |= (1 << gval.i);
      tmpTemplate.def.defense = TRUE;
    }
  return;
}


void 
NegDefense (char *s)
{
  generic_t gval;
  int type;
  char s1[256];

  if (St_GetSym (defenseT_P, s, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s1, "unknown defense '%s'", s);
      ErrMsg (s1);
    } 
  else 
    {
      tmpTemplate.val.cdefense &= ~(1 << gval.i);
      tmpTemplate.def.defense = TRUE;
    }
  return;
}


int 
PutAttack (m_attack_type attack)
{
  register int i;

  for (i = 0; i < attackCt; i++) 
    {
      if ((attack.attack_type == attackList[i].attack_type) &&
	  (attack.attack_desc == attackList[i].attack_desc) &&
	  (attack.attack_dice == attackList[i].attack_dice) &&
	  (attack.attack_sides == attackList[i].attack_sides)) 
	{
	  return i;
	}
    }

  if (attackCt == MAX_ATTACK) 
    {
      fprintf (stderr, "fatal error: too many different attacks.\n");
      fprintf (stderr, "increase MAX_ATTACK.\n");
      exit (1);
    }

  attackList[attackCt].attack_type = attack.attack_type;
  attackList[attackCt].attack_desc = attack.attack_desc;
  attackList[attackCt].attack_dice = attack.attack_dice;
  attackList[attackCt].attack_sides = attack.attack_sides;

  attackCt++;
  return attackCt - 1;
}

void 
AddUnusedAttack (char *s1, int dice, int sides, char *s2)
{
  generic_t gval;
  int type, aDesc;
  m_attack_type attack;
  char s[256];

  if (St_GetSym (attackDescT_P, s1, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s, "unknown attack description '%s'", s1);
      ErrMsg (s);
      return;
    } 
  else 
    {
      aDesc = gval.i;
    }

  if (St_GetSym (attackTypeT_P, s2, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s, "unknown attack type '%s'", s2);
      ErrMsg (s);
    } 
  else 
    {
      attack.attack_type = gval.i;
      attack.attack_dice = dice;
      attack.attack_desc = aDesc;
      attack.attack_sides = sides;

      PutAttack (attack);
    }
  return;
}

void 
AddAttack (char *s1, int dice, int sides, char *s2)
{
  generic_t gval;
  int type, aDesc;
  m_attack_type attack;
  char s[256];

  if (St_GetSym (attackDescT_P, s1, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s, "unknown attack description '%s'", s1);
      ErrMsg (s);
      return;
    } 
  else 
    {
      aDesc = gval.i;
    }

  if (St_GetSym (attackTypeT_P, s2, &type, &gval) != ST_SYM_FOUND) 
    {
      sprintf (s, "unknown attack type '%s'", s2);
      ErrMsg (s);
    } 
  else 
    {
      if (creatureAttacks > 3) 
	{
	  sprintf (s, "creature limited to 4 attacks");
	  ErrMsg (s);
	  return;
	}
      attack.attack_type = gval.i;
      attack.attack_dice = dice;
      attack.attack_desc = aDesc;
      attack.attack_sides = sides;

      tmpTemplate.val.damage[creatureAttacks++] = PutAttack (attack);
      tmpTemplate.def.damage = TRUE;
    }
  return;
}

int
FindAttackCount (int8u *damage)
{
  int max = 4;
  int i;
  for (i = 0; i < max; i++)
    {
      if (damage[i] == 0)
	return i;
    }
  return max;
}

void
AddFreq (int i, int chance, char *kind)
{
  char s1[256];
  if (((tmpTemplate.def.breath) || (tmpTemplate.def.spell)) &&
      (tmpTemplate.val.spells & CS_FREQ) && 
      ((tmpTemplate.val.spells & CS_FREQ) != chance))
    {
      sprintf (s1, "Setting new %s frequency causes previous spells or breaths to happen at this new rate which probably isn't want you want.", kind);
      ErrMsg (s1);
    }
  else if (i != 1 || (chance < 0 || chance > 15))
    {
      sprintf (s1, "%s frequency must be between 1/1 and 1/15.", kind);
      ErrMsg (s1);
    }
  else
    {
      tmpTemplate.val.spells &= ~(CS_FREQ);
      tmpTemplate.val.spells |= chance;
      tmpTemplate.def.spell = TRUE; 
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
  defenseT_P = InitTable ("defense", defenseInit);
  spellT_P = InitTable ("spell", spellInit);
  moveT_P = InitTable ("move", moveInit);
  specialT_P = InitTable ("special", specialInit);
  breathT_P = InitTable ("breath", breathInit);
  treasureT_P = InitTable ("treasure", treasureInit);
  attackTypeT_P = InitTable ("attackType", attackTypeInit);
  attackDescT_P = InitTable ("attackDesc", attackDescInit);

  classT_P = St_NewTable ("class", 40);
  creatureT_P = St_NewTable ("creature", 200);

  return;
}

void 
WriteCreature (template_t *tmpl_P)
{
  char s[256];
  strcpy (s, "\"");
  strcat (s, tmpl_P->val.name);
  strcat (s, "\"");
  fprintf (arguments.mc.outfile, "{%-28s, 0x%08XL,0x%08XL,0x%04X,%5d,%3d,\n",
	   s, (unsigned int) tmpl_P->val.cmove, 
	   (unsigned int) tmpl_P->val.spells, tmpl_P->val.cdefense, 
	   tmpl_P->val.mexp, tmpl_P->val.sleep);
  fprintf (arguments.mc.outfile, 
	   " %2d, %3d, %2d, '%c', {%3d,%2d}, {%3d,%3d,%3d,%3d}, %3d},\n",
	   tmpl_P->val.aaf, tmpl_P->val.ac, tmpl_P->val.speed,
	   tmpl_P->val.cchar,
	   tmpl_P->val.hd[0], tmpl_P->val.hd[1],
	   tmpl_P->val.damage[0], tmpl_P->val.damage[1],
	   tmpl_P->val.damage[2], tmpl_P->val.damage[3],
	   tmpl_P->val.level);
  return;
}

void 
WriteCreaturesHdr ()
{
  fprintf (arguments.mc.outfile, "\n\
/* Following are creature arrays and variables			*/\n\
	/* Creatures must be defined here                               */\n\
	/*      See types.h under creature_type for a complete list\n\
	   of all variables for creatures.       Some of the less obvious\n\
	   are explained below.\n\
\n\
	   Hit points:  #1, #2: where #2 is the range of each roll and\n\
	   #1 is the number of added up rolls to make.\n\
	   Example: a creature with 5 eight-sided hit die\n\
	   is given {5,8}.\n\
\n\
	   Attack types:\n\
	   1    Normal attack\n\
	   2    Poison Strength\n\
	   3    Confusion attack\n\
	   4    Fear attack\n\
	   5    Fire attack\n\
	   6    Acid attack\n\
	   7    Cold attack\n\
	   8    Lightning attack\n\
	   9    Corrosion attack\n\
	   10   Blindness attack\n\
	   11   Paralysis attack\n\
	   12   Steal Money\n\
	   13   Steal Object\n\
	   14   Poison\n\
	   15   Lose dexterity\n\
	   16   Lose constitution\n\
	   17   Lose intelligence\n\
	   18   Lose wisdom\n\
	   19   Lose experience\n\
	   20   Aggravation\n\
	   21   Disenchants\n\
	   22   Eats food\n\
	   23   Eats light\n\
	   24   Eats charges\n\
	   99   Blank\n\
\n\
	   Attack descriptions:\n\
	   1    hits you.\n\
	   2    bites you.\n\
	   3    claws you.\n\
	   4    stings you.\n\
	   5    touches you.\n\
	   6    kicks you.\n\
	   7    gazes at you.\n\
	   8    breathes on you.\n\
	   9    spits on you.\n\
	   10   makes a horrible wail.\n\
	   11   embraces you.\n\
	   12   crawls on you.\n\
	   13   releases a cloud of spores.\n\
	   14   begs you for money.\n\
	   15   You've been slimed.\n\
	   16   crushes you.\n\
	   17   tramples you.\n\
	   18   drools on you.\n\
	   19   insults you.\n\
	   99   is repelled.\n\
\n\
	   Example:  For a creature which bites for 1d6, then stings for\n\
	   2d4 and loss of dex you would use:\n\
	   {1,2,1,6},{15,4,2,4}\n\
\n\
	   CMOVE flags:\n\
	   Movement.    00000001        Move only to attack\n\
	   .    00000002        Move, attack normal\n\
	   .    00000008        20% random movement\n\
	   .    00000010        40% random movement\n\
	   .    00000020        75% random movement\n\
	   Special +    00010000        Invisible movement\n\
	   +    00020000        Move through door\n\
	   +    00040000        Move through wall\n\
	   +    00080000        Move through creatures\n\
	   +    00100000        Picks up objects\n\
	   +    00200000        Multiply monster\n\
	   Carries =    01000000        Carries objects.\n\
	   =    02000000        Carries gold.\n\
	   =    04000000        Has 60% of time.\n\
	   =    08000000        Has 90% of time.\n\
	   =    10000000        1d2 objects/gold.\n\
	   =    20000000        2d2 objects/gold.\n\
	   =    40000000        4d2 objects/gold.\n\
	   Special ~    80000000        Win-the-Game creature.\n\
\n\
	   SPELL Flags:\n\
	   Frequency    000001    1     These add up to x.  Then\n\
	   (1 in x).    000002    2     if RANDINT(X) = 1 the\n\
	   .    000004    4     creature casts a spell.\n\
	   .    000008    8\n\
	   Spells       =       000010  Teleport short (blink)\n\
	   =    000020  Teleport long\n\
	   =    000040  Teleport player to monster\n\
	   =    000080  Cause light wound\n\
	   =    000100  Cause serious wound\n\
	   =    000200  Hold person (Paralysis)\n\
	   =    000400  Cause blindness\n\
	   =    000800  Cause confusion\n\
	   =    001000  Cause fear\n\
	   =    002000  Summon monster\n\
	   =    004000  Summon undead\n\
	   =    008000  Slow Person\n\
	   =    010000  Drain Mana\n\
	   =    020000  Not Used\n\
	   =    040000  Not Used\n\
	   Breath/      +       080000  Breathe/Resist Lightning\n\
	   Resist       +       100000  Breathe/Resist Gas\n\
	   +    200000  Breathe/Resist Acid\n\
	   +    400000  Breathe/Resist Frost\n\
	   +    800000  Breathe/Resist Fire\n\
\n\
	   CDEFENSE flags:\n\
	   0001 Hurt by Slay Dragon.\n\
	   0002 Hurt by Slay Animal.\n\
	   0004 Hurt by Slay Evil.\n\
	   0008 Hurt by Slay Undead.\n\
	   0010 Hurt by Frost.\n\
	   0020 Hurt by Fire.\n\
	   0040 Hurt by Poison.\n\
	   0080 Hurt by Acid.\n\
	   0100 Hurt by Light-Wand.\n\
	   0200 Hurt by Stone-to-Mud.\n\
	   0400 Not used.\n\
	   0800 Not used.\n\
	   1000 Cannot be charmed or slept.\n\
	   2000 Can be seen with infra-vision.\n\
	   4000 Max Hit points.\n\
	   8000 Not used.\n\
\n\
\n\
	   Sleep (sleep)        :       A measure in turns of how fast creature\n\
	   will notice player (on the average).\n\
	   Area of affect (aaf) :       Max range that creature is able to \"notice\"\n\
	   the player.\n\
	 */\n\n");
}

void 
WriteCreatures ()
{
  char **s_A, **sp;
  int level, type;
  generic_t gval;
  int i;

  fprintf(arguments.mc.outfile, "#include \"constant.h\"\n");
  fprintf(arguments.mc.outfile, "#include \"types.h\"\n\n");
  WriteCreaturesHdr();
  s_A = St_SListTable (creatureT_P);

  fprintf (arguments.mc.outfile, "creature_type c_list[MAX_CREATURES] = {\n");
  for (i = 0; i < St_TableSize (creatureT_P); i++)
    {
      for (sp = s_A; *sp; sp++) 
	{
	  if (St_GetSym (creatureT_P, *sp, &type, &gval) != ST_SYM_FOUND) 
	    {
	      fprintf (stderr, "internal err. in WriteCreatures\n");
	      exit (1);
	    }
	  if ((*(template_t *) gval.v).idx == i) 
	    {
	      WriteCreature ((template_t *) gval.v);
	    }
	}
    }

  fprintf (arguments.mc.outfile, "};\n\n");

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
  if (t2.def.move == TRUE)
    {
      t1->val.cmove |= (t2.val.cmove & CM_ALL_MV_FLAGS);
      t1->def.move = TRUE;
    }
  if (t2.def.special == TRUE)
    {
      t1->val.cmove |= (t2.val.cmove & CM_SPECIAL & CM_WIN);
      t1->def.special = TRUE;
    }
  if (t2.def.treasure == TRUE)
    {
      t1->val.cmove |= (t2.val.cmove & CM_TREASURE);
      t1->def.treasure = TRUE;
    }
  if (t2.def.spell == TRUE)
    {
      t1->val.spells = (t2.val.spells & CS_SPELLS & CS_FREQ);
      t1->def.spell = TRUE;
    }
  if (t2.def.breath == TRUE)
    {
      t1->val.spells |= (t2.val.spells & CS_BREATHE & CS_FREQ);
      t1->def.breath = TRUE;
    }
  if (t2.def.resist == TRUE)
    {
      t1->val.spells |= (t2.val.spells & CS_BREATHE);
      t1->def.resist = TRUE;
    }
  if (t2.def.defense == TRUE)
    {
      t1->val.cdefense |= t2.val.cdefense;
      t1->def.defense = TRUE;
    }
  if (t2.def.mexp == TRUE)
    {
      t1->val.mexp = t2.val.mexp;
      t1->def.mexp = TRUE;
    }
  if (t2.def.sleep == TRUE)
    {
      t1->val.sleep = t2.val.sleep;
      t1->def.sleep = TRUE;
    }
  if (t2.def.aaf == TRUE)
    {
      t1->val.aaf = t2.val.aaf;
      t1->def.aaf = TRUE;
    }
  if (t2.def.ac == TRUE)
    {
      t1->val.ac = t2.val.ac;
      t1->def.ac = TRUE;
    }
  if (t2.def.speed == TRUE)
    {
      t1->val.speed = t2.val.speed;
      t1->def.speed = TRUE;
    }
  if (t2.def.cchar == TRUE)
    {
      t1->val.cchar = t2.val.cchar;
      t1->def.cchar = TRUE;
    }
  if (t2.def.hd == TRUE)
    {
      t1->val.hd[0] = t2.val.hd[0];
      t1->val.hd[1] = t2.val.hd[1];
      t1->def.hd = TRUE;
    }
  if (t2.def.damage == TRUE)
    {
      int i, j;
      int t2attackcount;
      int found = 0;
      t2attackcount = FindAttackCount (t2.val.damage);
      for (i = 0; i < t2attackcount; i++)
	{
	  /* do i have this one already? */
	  for (j = 0; j < creatureAttacks; j++)
	    {
	      if (t1->val.damage[j] == t2.val.damage[i])
		{
		  found = 1;
		  break;
		}
	    }
	  /* no?  great. now add it to our attack list */
	  if (!found)
	    {
	      //add it, and increment.
	      if (creatureAttacks > 3) 
		{
		  ErrMsg ("creature limited to 4 attacks");
		  return -1;
		}
	      else
		{
		  creatureAttacks++;
		  t1->val.damage[creatureAttacks -1] = t2.val.damage[i];
		}
	      found = 0;
	    }
	}
      if (t2attackcount == 0)
	{
	  t1->val.damage[0] = 0;
	  creatureAttacks = 0;
	}
      t1->def.damage = TRUE;
    }
  if (t2.def.level == TRUE)
    {
      t1->val.level = t2.val.level;
      t1->def.level = TRUE;
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
  fprintf (arguments.mc.outfile, 
	   "Warning: %s not defined for \"%s\", line %d\n",
	   s, name, lineNo);
  return;
}


void 
PutCreature (char *s, template_t *tmpl_P, int consistency_check)
{
  static int idx;
  generic_t gval;
  char s1[256];

  gval.v = malloc (sizeof(template_t));
  *(template_t *) gval.v = *tmpl_P;

  if (!tmpl_P->def.move)
    NotDefined (tmpl_P->val.name, "MOVE");
  if (!tmpl_P->def.treasure)
    NotDefined (tmpl_P->val.name, "TREASURE");
  if (!tmpl_P->def.defense)
    NotDefined (tmpl_P->val.name, "DEFENSE");
  if (!tmpl_P->def.mexp)
    NotDefined (tmpl_P->val.name, "XP");
  if (!tmpl_P->def.sleep)
    NotDefined (tmpl_P->val.name, "SLEEP");
  if (!tmpl_P->def.aaf)
    NotDefined (tmpl_P->val.name, "RADIUS");
  if (!tmpl_P->def.ac)
    NotDefined (tmpl_P->val.name, "AC");
  if (!tmpl_P->def.speed)
    NotDefined (tmpl_P->val.name, "SPEED");
  if (!tmpl_P->def.cchar)
    NotDefined (tmpl_P->val.name, "CCHAR");
  if (!tmpl_P->def.hd)
    NotDefined (tmpl_P->val.name, "HD");
  if (!tmpl_P->def.damage)
    NotDefined (tmpl_P->val.name, "ATTACK");
  if (!tmpl_P->def.level)
    NotDefined (tmpl_P->val.name, "LEVEL");

  if (consistency_check)
    ConsistencyCheckCreature (&tmpl_P->val);

  (*(template_t *) gval.v).idx = idx;

  if (St_DefSym (creatureT_P, s, GEN_TYPE_TMPL, gval) == ST_SYM_FOUND) 
    {
      sprintf (s1, "attempt to redefine creature '%s'\n", s);
      ErrMsg (s1);
      free (gval.v);
      return;
    }

  if (tmpl_P->val.level > maxCreatureLevel)
    maxCreatureLevel = tmpl_P->val.level;

  idx++;
  return;
}

int 
compare_attacks(const void *lhs_attack, const void *rhs_attack)
{
  const int *lhs = lhs_attack;
  const int *rhs = rhs_attack;
  return ntohl(*lhs) - ntohl(*rhs);
}

void
SortAttacks ()
{
  int i = 0;
  int j = 0;
  for (i = 0; i < attackCt; i++) 
    sorted_attackList[i] = attackList[i];
  qsort (sorted_attackList, attackCt, sizeof (m_attack_type), compare_attacks);
int v = memcmp(attackList, sorted_attackList, attackCt * sizeof(m_attack_type));
  //now find the diffs.
  int diffs[MAX_ATTACK];
  memset (diffs, 0, sizeof (diffs));
  for (i = 0; i < attackCt; i++) 
    {
      m_attack_type attack = attackList[i];
      for (j = 0; j < attackCt; j++)
        {
          if (attack.attack_type == sorted_attackList[j].attack_type &&
              attack.attack_desc == sorted_attackList[j].attack_desc &&
              attack.attack_dice == sorted_attackList[j].attack_dice &&
              attack.attack_sides == sorted_attackList[j].attack_sides)
            {
              diffs[i] = j;
              break;
            }
        }
    }
  //now we change each of the creatures in order to point to their new attacks.
  char **s_A, **sp;
  int type;
  generic_t gval;

  s_A = St_SListTable (creatureT_P);

  for (i = 0; i < St_TableSize (creatureT_P); i++)
    {
      for (sp = s_A; *sp; sp++) 
	{
	  if (St_GetSym (creatureT_P, *sp, &type, &gval) != ST_SYM_FOUND) 
	    {
	      fprintf (stderr, "internal err. in WriteCreatures\n");
	      exit (1);
	    }
	  if ((*(template_t *) gval.v).idx == i) 
	    {
              creature_type *c = (creature_type*) &(*(template_t*)gval.v).val;
              for (j = 0; j < 4; j++)
                {
                  if (c->damage[j] == 0)
                    break;
                  c->damage[j] = diffs[c->damage[j]];
                }
	    }
	}
    }

  St_SListTable (NULL);
  for (i = 0; i < attackCt; i++) 
    attackList[i] = sorted_attackList[i];
}

void 
WriteAttacks ()
{
  int i;
  int record_count = 0;

  fprintf (arguments.mc.outfile, 
	   "struct m_attack_type monster_attacks[N_MONS_ATTS] = {\n");

  for (i = 0; i < attackCt; i++) 
    {

      if ((i % 4) == 0)
	{
	  if (i != 0)
	    fprintf (arguments.mc.outfile, "\n");
	  if ((record_count % 5) == 0)
	    fprintf (arguments.mc.outfile, "/*%3d */", i);
	  else
	    {
	      if (i > attackCt - 4)
		fprintf (arguments.mc.outfile, "/*%3d */", i);
	      else
		fprintf (arguments.mc.outfile, "        ");
	    }
	  record_count++;
	}

      fprintf (arguments.mc.outfile, "{%2d,%2d,%2d,%2d}", 
	       attackList[i].attack_type, attackList[i].attack_desc,
	       attackList[i].attack_dice, attackList[i].attack_sides);

      if (!(i == attackCt - 1))
	fprintf (arguments.mc.outfile, ",\t");

    };

  fprintf (arguments.mc.outfile, "\n};\n");
  return;
}

void 
WriteConstants ()
{
  fprintf (arguments.mc.outfile,
	   "\n#define MAX_CREATURES\t%d\n", St_TableSize (creatureT_P));
  fprintf (arguments.mc.outfile,
	   "#define N_MONS_ATTS\t%d\n\n", attackCt);
  return;
}

void WriteGenerationNotice()
{
  fprintf (arguments.mc.outfile,
	   "/* The following was generated by the %s monster compiler \n"
           "   (%s-mc %s) on %s. \n", 
           PACKAGE_NAME, GAME_NAME, VERSION, __DATE__);
  fprintf (arguments.mc.outfile,"\n\
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
  fprintf (arguments.mc.outfile,
	   "*/\n\n");
  return;
}

int
mc_main (char *inputFilename)
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

  WriteGenerationNotice();
  if (arguments.mc.only_generate_constants)
    WriteConstants ();
  else
    {
      SortAttacks();
      WriteCreatures ();
      WriteAttacks ();
    }

  return 0;
}
