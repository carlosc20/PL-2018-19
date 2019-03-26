%option yylineno
%option noyywrap
%{
 FILE *cit, *prov, *iCit, *iProv;

 FILE *current;
 int inProv = 0;

%}
%x PAGE PROVERBIOS PROVTITLE AUTOR QUOTE DIALOG LINK INLINK NAME PROV CITACOES
%%

			//linha 1007 --> discurso ??  fprintf(ind,".hmtl");fprintf(ind,"</a></li>\n");
			//Angelis Borges,,,,Vasyl Slipak,,,,,Banks
			// ver redirects nos provérbios? 50024

\<page\>     						{BEGIN PAGE;}

<PAGE>{
\<title\>Provérbios\ 				{BEGIN PROVTITLE;}
\<text\ xml:.*Autor  				{BEGIN AUTOR;}
}

<PROVTITLE>{
.*/\<\/title\>                      {
	 								char filename[256];
									char* name = strdup(yytext);
									sprintf(filename,"proverbios/tipos/%s.html",name);
									prov = fopen(filename,"w");
									fprintf(iProv, '<li><a href="tipos/%s.html">%s</a></li>\n',name, name);
									fprintf(prov, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>");
									fprintf(prov, "<h1>%s</h1>\n",name);
									BEGIN PROVERBIOS;
									}
}

<PROVERBIOS>{
\#redirect 							{fprintf(prov,"Redireciona<br>"); printf("Fiz coisas %d\n", yylineno);}
\*\s?								{BEGIN PROV; fprintf(prov,"“");}
\<\/page\>                       	{BEGIN PAGE; fprintf(prov, "</body>"); fclose(prov);}
}

<PROV>{
\n									{BEGIN PROVERBIOS; fprintf(prov,"”<br>");}
\*|'|&quot;							{}
\[\[								{inProv = 1; current = prov; BEGIN LINK;}
.|\n								{fprintf(prov,"%s",yytext);}
}

<AUTOR>{
\|\ *Wikipedia\ *=\ *	 			{BEGIN NAME;}
\<\/page\>                        	{BEGIN PAGE;}
}

<NAME>{
.*/\n								{
	 								char filename[256];
									char* name = strdup(yytext);
									sprintf(filename,"citacoes/autores/%s.html",name);
									cit = fopen(filename,"w");
									fprintf(iCit, '<li><a href="autores/%s.html">%s</a></li>\n',name, name);
									fprintf(cit, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>");
									fprintf(cit, "<h1>%s</h1>\n",name); 
									BEGIN CITACOES;
									}
}

<CITACOES>{
\*\ ?('*(&quot;)+'*\ ?|\“)      	{BEGIN QUOTE; fprintf(cit,"“");}
\<\/page\>                        	{BEGIN PAGE; fprintf(cit, "</body>"); fclose(cit);}
}

<QUOTE>{
\n\ *:\ +							{BEGIN DIALOG; fprintf(cit,"<br>");}
\n		 							{BEGIN CITACOES; fprintf(cit,"”<br>");}
&quot;|\”|\“|'|\*|«|»				{}
\[\[								{inProv = 0; current = cit; BEGIN LINK;}
.|\n								{fprintf(cit,"%s",yytext);}
}

<DIALOG>{
(\n\ *:+\ *)-+|'*&quot;		  		{fprintf(cit,"”"); fprintf(cit,"</br>"); BEGIN AUTOR;}
. 									{fprintf(cit,"%s",yytext);} 
\n 									{fprintf(cit,"</br>");}
}

<LINK>{
\]\]								{if(inProv) BEGIN PROV; else BEGIN QUOTE;}
\| 									{BEGIN INLINK;}
.|\n								{fprintf(current,"%s",yytext);}
}

<INLINK>{
\]\]								{if(inProv) BEGIN PROV; else BEGIN QUOTE;}
}

<*>.|\n 							{}

%%

int main(int argc, char* argv[]){
	//if(argc == 1){ 
	//	yylex();
	//}
	//else{
		yyin = fopen("ptwikiquote-20190301-pages-articles.xml", "r");
		iCit = fopen ("citacoes/index.html","w"); 
		iProv = fopen ("proverbios/index.html","w"); 
		fprintf(iCit, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>");
		fprintf(iProv, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>");
		yylex();
		fprintf(iCit, "</body>");
		fprintf(iProv, "</body>");

		fclose(yyin);
		fclose(iCit);
		fclose(iProv);
	//}
	return 0;
}


