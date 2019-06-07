%code{
	#define _GNU_SOURCE 
	#include <stdio.h>
	int yylineno;
	int yyerror(char *s){fprintf(stderr,"Erro:%s\n",s);}
	int yylex();
}
//%define parse.lac full
//%define parse.error verbose
%token STRING NUM OBJ 
%union{
	double n;
	char * c;
}
%type <n>  NUM
%type <c>  STRING collections collection decls OBJ
%%

//no máximo aceita 2 tabs para nesting (espaços tbm)

prog : collections {printf("{\n%s\n}",$1);}
     ;

collections : collections collection {asprintf(&$$,"\t%s,\n%s",$2, $1);} 
		    | collection {asprintf(&$$,"\t%s", $1);}
		    ;

collection  : STRING OBJ decls {asprintf(&$$,"\"%s\"%s [\n%s\t]", $1,$2,$3);}
	        ;

decls : decls '-' STRING {asprintf(&$$,"\t\t\"%s\",\n%s", $3,$1);}
	  | '-' STRING {asprintf(&$$,"\t\t\"%s\"\n", $2);}
	  ;

//asprintf(&$$,"\"%s\"%s [\n%s\t]", $1,$2,$3);
%%
#include "lex.yy.c"
int main(){
	yyparse();
}