%{
#include <stdio.h>
int indentSize = 0;
%}
%option noyywrap
%option yylineno

%%
---\n+                 {return START; } /* inicio do doc */
:\ +                   {return MAP;}
-\ +                   {return SEQ;}
\ {2,}                 {int len = strlen(yytext);
                        if (len > indentSize){
                                indentSize=len;
                                return AUMENTA;}
                        else{ 
                            if(len == indentSize)
                                return IGUAL;
                            else{
                                indentSize=strlen(yytext);
                                return DIMINUI;
                                }
                            }
                        }
>\n                     {return FOLD;}
\|\n                    {return LIT;}
#[^\n]+\n               {}   /* comentario */
[?,[\]{}"'\n]           {return yytext[0];}  /* indicadores */
[+-]?[0-9]+(\.[0-9]+)?	{yylval.n=atof(yytext); return NUM;} 
(true)|(false)          {yylval.c=strdup(yytext); return BOOL; }         /* boolean */
([A-Za-z0-9_]+\ *)+     {yylval.c=strdup(yytext); return STR; } /* palavras com espaços */
[ \t]                   {}
. 			            {yyerror("Carater Inválido");}
%%