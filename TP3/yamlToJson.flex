%{
#include <stdio.h>

%}
%option noyywrap

%%
#[^\n]*             { return COMMENT; }
[^:]*               { return KEY; }
true                { return TRUE; }
false               { return FALSE; }
[0-9]+(\.[0-9]+)?	{ yylval.n=atof(yytext); return NUM; }
[:-\n]              { return yytext[0]; }



[a-zA-Z]+			{ return STRING;}

. 			{yyerror("Carater Inválido");}

%%