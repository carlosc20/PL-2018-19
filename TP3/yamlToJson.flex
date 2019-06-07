%{
#include <stdio.h>

%}
%option noyywrap
%option yylineno

%%
(:)                 {yylval.c=strdup(&yytext[0]); return OBJ;}
(-)                 {return yytext[0];}
[0-9]+(\.[0-9]+)?	{yylval.n=atof(yytext); return NUM; }
#[^\n]+             {}

([A-Za-z]+\ *)+     {yylval.c=strdup(yytext); return STRING; }
[ \t\n]               {}
. 			        {yyerror("Carater Inválido");}

%%
