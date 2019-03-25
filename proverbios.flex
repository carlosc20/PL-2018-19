%option yylineno
%option noyywrap
%{
 FILE * cit, *prov, *ind;
 char filename[200];
 char *name;
 int toOpen = 0;
%}
%x PAGE PROVERBIOS AUTOR QUOTE DIALOG LINK INSIDEL NAME
%%
			//»
			//ver aquilo de ter &quot. --> ponto final só no fim
			//linha 1007 --> discurso ??  fprintf(ind,".hmtl");fprintf(ind,"</a></li>\n");
			//Angelis Borges,,,,Vasyl Slipak,,,,,Banks

\<page\>     						{BEGIN PAGE;}

<PAGE>{
\<title\>Provérbios.*\<\/title\>	{BEGIN PROVERBIOS;}
\<text\ xml:.*Autor  				{BEGIN AUTOR;}
}

<PROVERBIOS>{
\ ?\*.*								{fprintf(prov,"%d %s\n",yylineno,yytext);}
\<\/page\>                       	{BEGIN PAGE;}
}



<AUTOR>{
\|\ *Wikipedia\ *=\ *	 			{BEGIN NAME;}

\*\ ?('*(&quot;)+'*\ ?)|(\“)        {BEGIN QUOTE; fprintf(cit,"</br>"); fprintf(cit,"“");}
\<\/page\>                        	{BEGIN PAGE;
										if(toOpen == 1){
											fclose(cit); fprintf(cit, "</body>"); toOpen = 0;}
									}
}

<NAME>{
.*/\n								{int i = 0; toOpen = 1;
									name = strdup(yytext);

									sprintf(filename,"cithtml/%s.html",name);
									cit = fopen (filename,"w");
									fprintf(ind,"<li><a href='%s'>%s</a></li>\n",filename, name);
									fprintf(cit, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>");
									fprintf(cit,"<h1>%s</h1>\n",name); 
									BEGIN AUTOR;
									}
}

<QUOTE>{
('*(&quot;)+)|\”|\n		 			{BEGIN AUTOR; fprintf(cit,"”"); fprintf(cit,"</br>");}
\n\ *:\ +							{BEGIN DIALOG; fprintf(cit,"</br>"); fprintf(cit,"</br>");}
\[\[								{BEGIN LINK;}
.|\n								{fprintf(cit,"%s",yytext);}
}

<DIALOG>{
(\n\ *:+\ *)-+|'*&quot;		  		{fprintf(cit,"”"); fprintf(cit,"</br>"); BEGIN AUTOR;}
. 									{fprintf(cit,"%s",yytext);} 
\n 									{fprintf(cit,"</br>");}
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
		cit = fopen ("citacoes.txt","w");
		ind = fopen ("index.html","w"); 
		fprintf(ind, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>");
		prov = fopen ("proverbios.txt","w");
		yyin = fopen(argv[1], "r");
		yylex();
		fprintf(ind, "</body>");
		fclose(yyin);
		fclose(ind);
	}
	return 0;
}


