%{
#include <stdio.h>

%}
%option noyywrap
%option yylineno

%%
---                 { } /* inicio do doc */
#[^\n]+\n           {}   /* comentario */


[-?:,[\]{}>|"'\n]       {return yytext[0];}  /* indicadores */
[+-]?[0-9]+(\.[0-9]+)?	{yylval.n=atof(yytext); return NUM;} 
(true)|(false)          {yylval.c=strdup(yytext); return BOOL; }         /* boolean */
([A-Za-z0-9_]+\ *)+     {yylval.c=strdup(yytext); return STR; } /* palavras com espaços */
[ \t]                   {}
. 			            {yyerror("Carater Inválido");}

%%
