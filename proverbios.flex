%{
		
%}
%option yylineno
%option noyywrap

A 			(á|à|â|ã|é|ê|ô|ç|[a-z])
PM			([A-Z]{A}+|[A-Z]\.)
Conect 		(d[eao]|de\ los|dos|von)
E 			\ + 
PF			([.!?]\n?|\n\n){E}?
%%
{PM}({E}{Conect}{E}{PM}|{E}{PM})*	{printf("%d %s\n",yylineno,yytext);}
{PF}{PM}							{}
.|\n								{}

%%
int main(int argc,char* argv[]){
	if(argc==1){
		yylex();
	}else{
		yyin=fopen(argv[1],"r");
		yylex();
		fclose(yyin);
	}
	return 0;
}