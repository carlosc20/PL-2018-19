%option yylineno
%option noyywrap
%{
 FILE * cit, *prov;
%}
%x PAGE PROV CIT AUTOR QUOTE DIALOG LINK INSIDEL 
%%
			//»
			//ver aquilo de ter &quot. --> ponto final só no fim
			//linha 1007 --> discurso ??
			//:\ *								{BEGIN DIALOG;} --_> problema sério
\<page\>     							  {BEGIN PAGE;}

<PAGE>{
\<title\>Provérbios.*\<\/title\>			  {BEGIN PROV;}
\<title\>.*\<\/title\>                      {BEGIN CIT;}
}

<PROV>{
\ ?\*.*										 {fprintf(prov,"%d %s\n",yylineno,yytext);}
\<\/page\>                       			 {BEGIN PAGE;}
}

<CIT>{
\<text\ xml:.*Autor  				      	  {BEGIN AUTOR;}
}

<AUTOR>{
\|\ *Wikipedia\ *=.*\n 				{int i = 0;
									while(yytext[i] != '=')
										i++;
									while(yytext[i+1] == ' ')
										i++;
									fprintf(cit,"%d %s\n",yylineno,yytext+i+1);}
\*\ ?('*(&quot;)+'*\ ?)|(\“)        {BEGIN QUOTE;fprintf(cit,"“");}
\<\/page\>                        	{BEGIN PAGE;}
}

<QUOTE>{
'*(&quot;)+|\”|\n  					{BEGIN AUTOR; fprintf(cit,"”");fprintf(cit,"\n");}
\[\[								{BEGIN LINK;}
.|\n								{fprintf(cit,"%s",yytext);}
}

<DIALOG>{
:-									{BEGIN AUTOR;}
.|\n 								{fprintf(cit,"%s",yytext);} 
}

<LINK>{
\]\]								{BEGIN QUOTE;}
\| 									{BEGIN INSIDEL;}
.|\n								{fprintf(cit,"%s",yytext);}
}

<INSIDEL>{
\]\]								{BEGIN QUOTE;}
.|\n								{fprintf(cit,"%s",yytext);}
}

<*>.|\n 									  {}

%%
int main(int argc, char* argv[]){
	if(argc == 1){ 
		yylex();
	}
	else{
		cit = fopen ("citacoes.cit","w");
		prov = fopen ("proverbios.prov","w");
		yyin = fopen(argv[1], "r");
		yylex();
		fclose(yyin);
	}
	return 0;
}


