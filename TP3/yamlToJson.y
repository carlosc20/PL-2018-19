%code{
	#define _GNU_SOURCE 
	#include <stdio.h>
	int yylineno;
	int yyerror(const char *s){fprintf(stderr,"Erro:%s -> %d\n",s,yylineno);}
	int yylex();
}
%define parse.lac full
%define parse.error verbose
%token STR NUM NULL BOOL START SEQ MAP FOLD LIT AUMENTA DIMINUI IGUAL
%union{
	double n;
	char * c;
}
%type <n>  NUM 
%type <c>  START STR BOOL SEQ MAP
%type <c>  AUMENTA DIMINUI IGUAL
%type <c>  doc mapblock value seqblock entry collection block key
%type <c>  scalar //folded literal
%type <c>  flowentry seqflow mapflow flowmapping
%%

doc: START AUMENTA collection 					{printf("%s", $3);}									
   ;

collection: block								{$$=$1;}
	 	  | '{' mapflow '}'						{asprintf(&$$, "{\n%s\n}", $2);}
		  | '[' seqflow ']'						{asprintf(&$$, "[\n%s\n]", $2);}
	 	  ;


block: mapblock									{asprintf(&$$, "{\n%s\n}", $1);}
	 | seqblock									{asprintf(&$$, "[\n%s\n]", $1);}
	 ;

	/* mapping block */
mapblock: key entry		       							{asprintf(&$$, "{%s%s}", $1, $2);}
		| key '\n' AUMENTA block      					{asprintf(&$$, "{\n%s\n}", $4);}
		| key '\n' AUMENTA block '\n' DIMINUI block		{asprintf(&$$, "{\n%s\n},\n%s", $4, $7);}
		| mapblock '\n' IGUAL mapblock					{asprintf(&$$, "%s,\n%s", $1, $4);}
		;

key: scalar MAP 								{asprintf(&$$, "%s: ", $1);}
   ;

	/* sequence block */
seqblock: SEQ entry										{asprintf(&$$, "%s", $2);}
		| SEQ '\n' AUMENTA block      					{asprintf(&$$, "[\n%s\n]", $4);}
		| SEQ '\n' AUMENTA block '\n' DIMINUI block		{asprintf(&$$, "[\n%s\n],\n%s", $4, $7);}
		| seqblock '\n' IGUAL seqblock					{asprintf(&$$, "%s,\n%s", $1, $4);}
		;

entry: scalar									{$$=$1;}
	 | '{' mapflow '}'							{asprintf(&$$, "{\n%s\n}", $2);}
	 | '[' seqflow ']'							{asprintf(&$$, "[\n%s\n]", $2);} 
	 ;

scalar: STR	 									{asprintf(&$$, "\"%s\"", $1);}		
	  | NUM  									{asprintf(&$$, "%f", $1);}
	  | BOOL 									{$$=$1;}
	  | "'" STR "'" 							{$$=$2;}
	  | '"' STR '"'								{$$=$2;}
	  ;




flowentry: '{' mapflow '}'						{asprintf(&$$, "{\n%s\n}", $2);}
	 	 | '[' seqflow ']'						{asprintf(&$$, "[\n%s\n]", $2);}
		 | scalar								{$$=$1;}
		 | scalar MAP flowentry					{asprintf(&$$, "{\n\"%s\": %s\n}", $1, $3);}
		 ;

seqflow: flowentry								{$$=$1;}		
	   | seqflow ',' flowentry					{asprintf(&$$, "%s,\n%s", $1, $3);}	
	   ; 

mapflow: flowmapping							{$$=$1;}
 	   | mapflow ',' flowmapping				{asprintf(&$$, "%s,\n%s", $1, $3); /* pôr "" nas chaves todas mesmo numeros */ } 
	   ;

flowmapping: scalar MAP flowentry				{asprintf(&$$, "%s: %s", $1, $3);}
		   | scalar  							{asprintf(&$$, "%s: null", $1);}
		   ;

/*
folded  : STR '\n'                               {asprintf(&$$, "%s", $1);}
        | folded STR '\n'                        {asprintf(&$$, "%s%s", $1,$2);}
        | folded '\n'                            {asprintf(&$$, "%s\\n", $1);}

literal : STR '\n'                                {asprintf(&$$, "%s\\n", $1);}
        | literal STR '\n'                        {asprintf(&$$, "%s\\n%s", $1,$2);}
        | literal '\n'                            {asprintf(&$$, "%s\\n", $1);}


*/
%%
#include "lex.yy.c"
int main(){
	yyparse();
}