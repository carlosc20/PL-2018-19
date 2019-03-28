%option yylineno
%option noyywrap
%{
FILE *cit, *prov, *iCit, *iProv;
FILE *current;
int currentCont;
char* title;

int red = 0;
int provCount = 0;
int provCatCount = 0;
int citCount = 0;

 /* 
 '''
 * ''&quot;Provérbio em português moderno.&quot;
::- '''Alternativos:'''
:::- &quot;Provérbio alternativo 1.&quot;
:::- &quot;Provérbio alternativo 2.&quot;
::- Notas sobre o contexto, informações adicionais caso o significado não esteja claro, etc.


quantos formatos existem
*/

void beginCit(FILE* file) {
	fprintf(file,"“");
}

void endCit(FILE* file) {
	fprintf(file,"”<br>");
}

void beginPage(FILE* file, const char* t) {
	fprintf(file, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>\n<h1>%s</h1>\n", t);
}

%}
%x PAGE PROVLIST PROVTITLE PROVHEADER PROV AUTOR QUOTE DIALOG LINK INLINK NAME CITACOES 
%%

\<page\>     						{BEGIN PAGE;}

<PAGE>{
\<title\>Provérbios\ 				{BEGIN PROVTITLE;}
\<text\ xml:.*Autor  				{BEGIN AUTOR;}
}

<PROVTITLE>{
.*/\<\/title\>                      {BEGIN PROVHEADER; title = strdup(yytext);}
}

<PROVHEADER>{
\<redirect							{BEGIN PAGE; red++;}
\<revision							{
									provCatCount++;
									char filename[256];
									sprintf(filename,"proverbios/tipos/%s.html",title);
									prov = fopen(filename,"w");
									fprintf(iProv, "<li><a href=\"tipos/%s.html\">%s</a></li>\n",title, title);
									beginPage(prov, title);
									free(title);
									BEGIN PROVLIST;
									}
}

<PROVLIST>{
^\*.*\[http							{}
^\*\*\ '''Alternativos:'''			{fprintf(prov, "Alternativos:<br>");}
^\*\*\ '''Adulteração:'''			{fprintf(prov, "Adulteração:<br>");}
^\*\*\*								{BEGIN PROV; fprintf(prov, "-> "); beginCit(prov);}
^\*									{BEGIN PROV; beginCit(prov);}
\<\/page\>                       	{BEGIN PAGE; fclose(prov);}
}

<PROV>{
\*|'|&quot;							{}
\n									{BEGIN PROVLIST; endCit(prov); provCount++;}
\[\[								{currentCont = PROV; current = prov; BEGIN LINK;}
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
									fprintf(iCit, "<li><a href=\"autores/%s.html\">%s</a></li>\n",name, name);
									beginPage(cit, name);
									BEGIN CITACOES;
									}
}

<CITACOES>{
\*\ ?('*(&quot;)+'*\ ?|\“)      	{BEGIN QUOTE; beginCit(cit);}
\<\/page\>                        	{BEGIN PAGE; fclose(cit);}
}

<QUOTE>{
\n\ *:\ +							{BEGIN DIALOG; fprintf(cit,"<br>");}
\n		 							{BEGIN CITACOES; endCit(cit); citCount++;}
&quot;|\”|\“|'|\*|«|»|’				{}
\[\[								{currentCont = QUOTE; current = cit; BEGIN LINK;}
.|\n								{fprintf(cit,"%s",yytext);}
}

<DIALOG>{
(\n\ *:+\ *)-+|'*&quot;		  		{endCit(cit); BEGIN AUTOR;}
. 									{fprintf(cit,"%s",yytext);} 
\n 									{fprintf(cit,"</br>");}
}

<LINK>{
\]\]								{BEGIN currentCont;}
\| 									{BEGIN INLINK;}
.|\n								{fprintf(current,"%s",yytext);}
}

<INLINK>{
\]\]								{BEGIN currentCont;}
.|\n								{fprintf(current,"%s",yytext);}
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
		fprintf(iCit, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>\n<ul>");
		fprintf(iProv, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>\n<ul>");
		yylex();
		fprintf(iCit, "</ul>\n</body>");
		fprintf(iProv, "</ul>\n</body>");

		fclose(yyin);
		fclose(iCit);
		fclose(iProv);
		printf("Páginas de provérbios que redirecionam para outra: %d.\n", red);
		printf("Foram encontradas %d citações.\n", citCount);
		printf("Foram encontrados %d provérbios divididos em %d categorias.\n", provCount, provCatCount);
	//}
	return 0;
}


