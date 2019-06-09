%code{
	#define _GNU_SOURCE 
	#include <stdio.h>
	int yylineno;
	int yyerror(char *s){fprintf(stderr,"Erro:%s -> %d\n",s,yylineno);}
	int yylex();
}
%define parse.lac full
%define parse.error verbose
%token STR NUM NULL BOOL START DOTS
%union{
	double n;
	char * c;
}
%type <n>  NUM 
%type <c>  START STR BOOL DOTS
%type <c>  mapblock mapping key value complexkey flowentry mapflow
%type <c>  flowmapping foldedblock scalar seqblock seqflow entry literalblock 
%%

doc: START mapblock 							{printf("{%s}", $2);}											
   ;

mapblock: mapping '\n' mapblock					{asprintf(&$$, "%s,\n%s", $1, $3);}
		| mapping								{$$=$1;}
		;

mapping: key DOTS value	'\n'					{asprintf(&$$, "%s: %s", $1,$3); /* pode ter vários \n antes de value */ }
	   | "? " complexkey '\n' DOTS value '\n'   {asprintf(&$$, "%s\n%s", $2,$5);}
	   ;

complexkey: key '\n' complexkey 				{asprintf(&$$, "%s,\n%s", $1,$3);}
		  | 									{$$=""; /* tirei o key que dava conflito*/ }
  		  ;

key: STR  										{asprintf(&$$, "%s", $1);}			
   | NUM  										{asprintf(&$$, "%f", $1);}
   ;

value: flowentry								{$$=$1;}
	 | "\n" mapblock							{asprintf(&$$, "\n%s", $2);}
	 | "\n" seqblock							{asprintf(&$$, "\n%s", $2);}
 	 | "|\n" literalblock						{asprintf(&$$, "\n%s", $2);}
	 | ">\n" foldedblock						{asprintf(&$$, "\n%s", $2);}
	 ;

scalar: STR	 									{$$=$1;}			
	  | NUM  									{asprintf(&$$, "%f", $1);}
	  | BOOL 									{$$=$1;}
	  | "'" STR "'" 							{$$=$2;}
	  | '"' STR '"'								{$$=$2;}
	  |											{$$="null";}
	  ;
 
seqblock: '-' entry '\n' seqblock				{asprintf(&$$, "%s,\n%s", $2, $4);}
		| 										{$$=""; /* tirei o entry porque dava conflito*/ }
		;

entry: '{' mapflow '}'							{$$=$2;}
	 | '[' seqflow ']'							{$$=$2;}
 	 | mapblock									{$$=$1;}
	 | scalar									{$$=$1;}
	 ;

literalblock: STR '\n'							{$$=$1;}
			| STR								{$$=$1;}
			;

foldedblock: STR '\n'							{$$=$1;}
		   | STR								{$$=$1;}
		   ;

flowentry: '{' mapflow '}'						{$$=$2;}
	 	 | '[' seqflow ']'						{$$=$2;}
		 | scalar								{$$=$1;}
		 ;

mapflow: flowmapping ',' mapflow 				{asprintf(&$$, "%s,\n%s", $1, $3);}
	   | flowmapping							{$$=$1; /* tirei o vazio*/ }
	   ;

seqflow: flowentry ',' seqflow					{asprintf(&$$, "%s,\n%s", $1, $3);}
	   | flowentry								{$$=$1; /* tirei o vazio */ }					
	   ; 

flowmapping: key DOTS flowentry					{asprintf(&$$, "%s,\n%s", $1, $3);}
		   | key								{$$="null";}
		   ;



%%
#include "lex.yy.c"
int main(){
	yyparse();
}