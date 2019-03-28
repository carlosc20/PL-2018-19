%{
#include <string.h>
#include <glib.h>
GPtrArray* autores;
GPtrArray* regioes;
%}
%option yylineno
%option noyywrap
%{
FILE *cit, *prov, *iCit, *iProv;
FILE *current;

char linkP[128];
int size = 0;

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
\<redirect							{BEGIN PAGE; red++; free(title);}
\<revision							{
									provCatCount++;
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
^\*\*\ '''Alternativos:'''			{fprintf(prov, "Alternativos:<br>");}
^\*\*\ '''Adulteração:'''			{fprintf(prov, "Adulteração:<br>");}
^\*\*\*								{BEGIN PROV; fprintf(prov, "-> "); beginCit(prov);}
^\*									{BEGIN PROV; beginCit(prov);}
\<\/page\>                       	{BEGIN PAGE; fclose(prov);}
}

<PROV>{
\*|'|&quot;							{}
\n									{BEGIN PROVLIST; endCit(prov); provCount++;}
\[\[								{currentCont = PROV; current = prov; size = 0; BEGIN LINK;}
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
\<\/page\>                        	{BEGIN PAGE; fclose(cit);}
}

<QUOTE>{
\n\ *:\ +							{BEGIN DIALOG; fprintf(cit,"<br>");}
\n		 							{BEGIN CITACOES; endCit(cit); citCount++;}
&quot;|\”|\“|'|\*|«|»|’				{}
\[\[								{currentCont = QUOTE; current = cit; size = 0; BEGIN LINK;}
.|\n								{fprintf(cit,"%s",yytext);}
}

<DIALOG>{
(\n\ *:+\ *)-+|'*&quot;		  		{endCit(cit); BEGIN AUTOR;}
. 									{fprintf(cit,"%s",yytext);} 
\n 									{fprintf(cit,"</br>");}
}

<LINK>{
\]\]								{linkP[size] = '\0'; fprintf(current,"%s\n",linkP); BEGIN currentCont;}
\| 									{size=0;}
.|\n								{linkP[size] = yytext[0]; size++;}
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
		printIndex(iProv, regioes, printRefsProv);
		printIndex(iCit, autores, printRefsCits);
		fclose(yyin);
		fclose(iCit);
		fclose(iProv);
		printf("Páginas de provérbios que redirecionam para outra: %d.\n", red);
		printf("Foram encontradas %d citações.\n", citCount);
		printf("Foram encontrados %d provérbios divididos em %d categorias.\n", provCount, provCatCount);
	//}
	return 0;
}


