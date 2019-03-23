%option yylineno
%option noyywrap
%{
 FILE * cit, *prov;
%}
%x PAGE PROV CIT AUTOR QUOTE NAME DIALOG LINK INSIDEL 
%%
			//»
			//ver aquilo de ter &quot. --> ponto final só no fim
			//linha 1007 --> discurso ??
		
\<page\>     						{BEGIN PAGE;}

<PAGE>{
\<title\>Provérbios.*\<\/title\>	{BEGIN PROV;}
\<title\>.*\<\/title\>              {BEGIN CIT;}
}

<PROV>{
\ ?\*.*								{fprintf(prov,"%d %s\n",yylineno,yytext);}
\<\/page\>                       	{BEGIN PAGE;}
}

<CIT>{
\<text\ xml:.*Autor  				{BEGIN AUTOR;}
}

<AUTOR>{
\|\ *Wikipedia\ *=\ * 				{BEGIN NAME;fprintf(cit,"\n");}
\*\ ?('*(&quot;)+'*\ ?)|(\“)        {BEGIN QUOTE;fprintf(cit,"“");}
\<\/page\>                        	{BEGIN PAGE;}
}

<NAME>{
\n 									{BEGIN AUTOR;fprintf(cit,"\n");}
.									{fprintf(cit,"%s",yytext);}
}

<QUOTE>{
('*(&quot;)+)|\”|\n		 			{BEGIN AUTOR; fprintf(cit,"”");fprintf(cit,"\n");}
\n\ *:\ +							{BEGIN DIALOG;fprintf(cit,"\n");}
\[\[								{BEGIN LINK;}
.|\n								{fprintf(cit,"%s",yytext);}
}

<DIALOG>{
(\n\ *:+\ *)-+|'*&quot;		  		{fprintf(cit,"”");fprintf(cit,"\n");BEGIN AUTOR;}
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

<*>.|\n 							{}

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


