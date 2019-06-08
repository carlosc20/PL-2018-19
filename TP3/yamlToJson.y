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



doc: "---" '\n' mapblock
   ;

mapblock: mapping '\n' mapblock
		| mapping
		;

mapping: key ': ' value	'\n'		{ /* pode ter vários \n antes de value */ }
	   | '? ' complexkey '\n' ": " value '\n'
	   ;

complexkey: key '\n' complexkey
   		  | key '\n' complexkey
		  | key
  		  ;

key: STR
   | NUM
   ;

value: flowentry
	 | "\n" mapblock
	 | "\n" seqblock
 	 | "|\n" literalblock
	 | ">\n" foldedblock
	 ;

scalar: STR
	  | NUM
	  | BOOL
	  | "'" STR "'"
	  | '"' STR '"'
	  |			{ /* null */ }
	  ;
 
seqblock: '- ' entry '\n' seqblock
		| '- ' entry
		;

entry: '{' mapflow '}'
	 | '[' seqflow ']'
 	 | mapblock
	 | scalar
	 ;

literalblock: STR '\n'
			| STR
			;

foldedblock: STR '\n'
		   | STR
		   ;

flowentry: '{' mapflow '}'
	 	 | '[' seqflow ']'
		 | scalar
		 ;

mapflow: flowmapping ',' mapflow 
	   | flowmapping
	   |
	   ;

seqflow: flowentry ',' seqflow
	   | flowentry
	   |
	   ; 

flowmapping: key ': ' flowentry
		   | key				{ /* valor é nulo */ }
		   ;



%%
#include "lex.yy.c"
int main(){
	yyparse();
}