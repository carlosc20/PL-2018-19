%{
#include <stdio.h>

%}
%option noyywrap
%option yylineno

%%
---                 {}
#[^\n]+\n           {} /* comentario */


[-?:,[\]{}>|]         {return yytext[0];}
[0-9]+(\.[0-9]+)?	{yylval.n=atof(yytext); return NUM;} 
                    /* numero notação cientifica */
(true)|(false)                    /* boolean */
                  /* null */

([A-Za-z]+\ *)+     {yylval.c=strdup(yytext); return STRING; }
[ \t\n]             {}
. 			        {yyerror("Carater Inválido");}

%%
