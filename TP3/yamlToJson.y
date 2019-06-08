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
%type <c>  STRING collections collection list OBJ
%%

//no máximo aceita 2 tabs para nesting (espaços tbm)

prog : collections {printf("{\n%s\n}",$1);}
     ;

collections : collections collection {asprintf(&$$, "%s,\n%s", $1, $2);} 
		    | collection 			 {asprintf(&$$, "%s", $1);}
		    ;

collection  : STRING OBJ list       {asprintf(&$$, "\"%s\"%s [\n%s]", $1,$2,$3);}
			| STRING OBJ collection {asprintf(&$$, "\"%s\"%s {\n%s}", $1,$2,$3);}
			| STRING OBJ STRING     {asprintf(&$$,"\"%s\"%s \"%s\"", $1, $2, $3);}
			;


list : list '-' STRING 			    {asprintf(&$$,"%s,\n\"%s\"", $1, $3);}
	 | list '-' collection          {asprintf(&$$,"%s,\n\"{\n %s\n}", $1,$3);}
	 | '-' STRING 					{asprintf(&$$,"\"%s\"", $2);}
	 | '-' collection				{asprintf(&$$,"%s", $2);}
	 ;


%%
#include "lex.yy.c"
int main(){
	yyparse();
}