%option yylineno
%option noyywrap
%{
 FILE * cit, *prov;
%}
%x PAGE PROV CIT AUTOR 
%%

<*>\<page\>     							  {BEGIN PAGE;}
<*>.|\n 									  {}

<PAGE>{
.*\<title\>Provérbios.*\<\/title\>			  {BEGIN PROV;}
.*\<title\>.*\<\/title\>                      {BEGIN CIT;}
}

<PROV>{
\ ?\*.*										 {fprintf(prov,"%d %s\n",yylineno,yytext);}
\<\/page\>                       			 {BEGIN PAGE;}
}

<CIT>{
.*\<text\ xml:.*Autor  				      	  {BEGIN AUTOR;}
.*|\n										  {}
}

<AUTOR>{
\|\ *Wikipedia\ *=.*\n 			{int i = 0;
									while(yytext[i] != '=')
										i++;
									while(yytext[i+1] == ' ')
										i++;
									fprintf(cit,"%d %s\n",yylineno,yytext+i+1);}
\*\ ?&quot.*&quot                {fprintf(cit,"%d %s\n",yylineno,yytext);}
\<\/page\>                       {BEGIN PAGE;}
} 
%%
int main(int argc, char* argv[]){
	if(argc == 1) 
		yylex();
	else{
		cit = fopen ("citacoes.cit","w");
		prov = fopen ("proverbios.prov","w");
		yyin = fopen(argv[1], "r");
		yylex();
		fclose(yyin);
	}
	return 0;
}
