%code{
	#define _GNU_SOURCE 
	#include <stdio.h>
	int yylineno;
	int yyerror(char *s){fprintf(stderr,"Erro:%s\n",s);}
	int yylex();
}
//%define parse.lac full
//%define parse.error verbose
%token STR NUM NULL
%union{
	double n;
	char * c;
}
%type <n>  NUM
%type <c>  STR collections collection list OBJ
%%

//no máximo aceita 2 tabs para nesting (espaços tbm)



prog: "---" '\n' rootmap
	;

rootmap: mapping rootmap
		|
		;

mapping: key ':' value
		;

key: STR
	| NUM
	;

value: '{' mapflow '}' '\n'
	| '[' seqflow ']' '\n'
	| '\n' block
	| STR
	| NUM
	| NULL
	;
 
block: mapblock
	| seqblock
	;

seqblock: '-' value '\n' seqblock
		| 
		;

mapblock: mapping '\n' mapblock
		| '?' key '\n' value
		|
		;

mapflow: mapping ',' mapflow
		|
		;


seqflow: value ',' seqflow
		| 
		; 



%%
#include "lex.yy.c"
int main(){
	yyparse();
}