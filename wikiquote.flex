%{
#include <string.h>
#include <glib.h>
GPtrArray* autores;
GPtrArray* regioes;
GHashTable* palavras;
%}
%option yylineno
%option noyywrap

D 		('|\*|«|»|’|”|“|\"|&quot;)
P 		[^\ \t&,.?!'\n\[D]+
%{
FILE *cit, *prov, *iCit, *iProv, *beta;
FILE *current;

int currentCtx;
char* title;

int alt = 0;

int redirect = 0;
int provCount = 0;
int citCount = 0;

 /* 
 '''
 * ''&quot;Provérbio em português moderno.&quot;
::- '''Alternativos:'''
:::- &quot;Provérbio alternativo 1.&quot;
:::- &quot;Provérbio alternativo 2.&quot;
::- Notas sobre o contexto, informações adicionais caso o significado não esteja claro, etc.
(\[\[[^\|(\[\[)]*\|)|\[\[ ---> ver para o caso em que spama muitos [[][][]]

*/

void beginCit(FILE* file) {
	fprintf(file,"<li>“");
}

void endCit(FILE* file) {
	fprintf(file,"”</li>");
}

void beginPage(FILE* file, const char* t) {
	fprintf(file, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>\n<h1>%s</h1>\n<ul>\n", t);
}

void endPage(FILE* file) {
	fprintf(file, "</ul>\n</body>");
}
%}
%x PAGE PROVLIST PROVTITLE PROVHEADER PROV AUTOR QUOTE DIALOG LINK NAME CITACOES
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
\<redirect							{BEGIN PAGE; redirect++; free(title);}
\<revision							{
									char filename[256];
									sprintf(filename,"proverbios/tipos/%s.html",title);
									prov = fopen(filename,"w");
									g_ptr_array_add(regioes,title);
									beginPage(prov, title);
									BEGIN PROVLIST;
									}
}

<PROVLIST>{
^\*.*\[http							{}
^\*+\ *\n							{}
^\*\*\ '''Alternativos:'''			{if(alt) {fprintf(prov, "</ul>");}; fprintf(prov, "Alternativos:\n<ul>"); alt = 1;}
^\*\*\ '''Adulteração:'''			{if(alt) {fprintf(prov, "</ul>");}; fprintf(prov, "Adulteração:\n<ul>"); alt = 1;}
^\*\*								{BEGIN PROV; beginCit(prov);}
^\*\*\*								{BEGIN PROV; beginCit(prov);}
^'''								{BEGIN PROV; beginCit(prov);}
^:'''								{BEGIN PROV; beginCit(prov);}
^::''								{BEGIN PROV; beginCit(prov);}
^\*\ \[\[.*\]\]\n					{}
^\*									{BEGIN PROV; if(alt) {fprintf(prov, "</ul>"); alt = 0;}; beginCit(prov);}
\<\/page\>                       	{BEGIN PAGE;  endPage(prov); fclose(prov);}
}

<PROV>{
{D}									{}
\n									{BEGIN PROVLIST; endCit(prov); provCount++;}
\[\[								{currentCtx = PROV; current = prov; BEGIN LINK;}
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
									g_ptr_array_add(autores,name);
									sprintf(filename,"citacoes/autores/%s.html",name);
									cit = fopen(filename,"w");
									beginPage(cit, name);
									BEGIN CITACOES;
									}
}

<CITACOES>{
\*\ ?('*(&quot;)+'*\ ?|\“)      	{BEGIN QUOTE; beginCit(cit);}
\<\/page\>                        	{BEGIN PAGE;  endPage(cit); fclose(cit);}
}

<QUOTE>{
\n\ *:\ +							{BEGIN DIALOG; fprintf(cit,"<br>");}
\n		 							{BEGIN CITACOES; endCit(cit); citCount++;}
&quot;|{D}							{}
\[\[								{currentCtx = QUOTE; current = cit; BEGIN LINK;}
{P}									{fprintf(cit,"%s",yytext);}
[\ ,.?!']*        					{fprintf(cit,"%s",yytext);}
}

<DIALOG>{
(\n\ *:+\ *)-+|'*&quot;		  		{endCit(cit); BEGIN AUTOR;}
{P} 								{fprintf(cit,"%s",yytext);}
[\ ,.?!']*							{fprintf(cit,"%s",yytext);}
\n 									{fprintf(cit,"</br>");}
}

<LINK>{
\]\]								{BEGIN currentCtx; }
[^\|\]]*\|							{}
[^\ \]]+							{fprintf(current,"%s",yytext);}
}

<*>.|\n 							{}

%%

gint strcompare(gconstpointer fst, gconstpointer snd){
    char* f = *((char**)fst);
    char* s = *((char**)snd);
    return strcmp(f,s);
}

int printRefsCits(char* value){
	if(strlen(value)!=0)
		fprintf(iCit, "<li><a href=\"autores/%s.html\">%s</a></li>\n", value, value); 
} 

int printRefsProv(char* value){
	if(strlen(value)!=0)
		fprintf(iProv, "<li><a href=\"tipos/%s.html\">%s</a></li>\n", value, value); 
} 

int printIndex(FILE* f, GPtrArray* list, int (*function) ()){
	fprintf(f, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>\n<ul>");
	g_ptr_array_foreach(list, (GFunc) function, NULL); 
	fprintf(f, "</ul>\n</body>");
}

int main(int argc, char* argv[]){
	//if(argc == 1){ 
	//	yylex();
	//}
	//else{
		yyin = fopen("ptwikiquote-20190301-pages-articles.xml", "r");
		iCit = fopen ("citacoes/index.html","w"); 
		iProv = fopen ("proverbios/index.html","w");
		autores = g_ptr_array_new();
		regioes = g_ptr_array_new(); 
		yylex();
		g_ptr_array_sort(autores,(GCompareFunc) strcompare);
		g_ptr_array_sort(regioes,(GCompareFunc) strcompare);
		printIndex(iCit, autores, printRefsCits);
		printIndex(iProv, regioes, printRefsProv);
		fclose(yyin);
		fclose(iCit);
		fclose(iProv);
		printf("Foram encontradas %d citações de %d autores.\n", citCount, autores->len);
		printf("Foram encontrados %d provérbios de %d línguas/regiões.\n", provCount, regioes->len);
		printf("%d páginas de provérbios redirecionam para outras.\n", redirect);
	//}
	return 0;
}


