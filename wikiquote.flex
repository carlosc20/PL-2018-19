%{
#include <string.h>
#include <glib.h>
GPtrArray* autores;
GPtrArray* regioes;
GHashTable* palavras;

typedef struct count{
  char* pal;
  int* c;
} *Counter;

%}
%option yylineno
%option noyywrap

D 		('|\*|«|»|’|”|“|\"|&quot;)
P 		[^\ \t&,-.?”“"’!'\n\[D]+
%{
FILE *cit, *prov, *iCit, *iProv;
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

void freeStr(gpointer data){
	char* str = (char*) data;
	free(str);
}

void freeCounter (gpointer data){
  Counter count = (Counter) data;
  free(count->c);
  free(count);
}

int counterCmp (gconstpointer p1, gconstpointer p2){
    Counter c1 = (Counter) p1;
    Counter c2 = (Counter) p2;
    return *c2->c - *c1->c ;
}

int printEntry(Counter value) {
  fprintf(cit,"%s --> %d", value->pal, *value->c);
  fprintf(cit,"<br>");
  return 0;
}

void printAndFree(){
	GList* l = g_hash_table_get_values(palavras);  
    l = g_list_sort (l, (GCompareFunc) counterCmp);
    g_list_foreach(l,(GFunc) printEntry, NULL);
	
	g_hash_table_destroy(palavras);
	g_list_free(l);
}

void incrCounter(char* text){
	char* palavra = strdup(text);
	Counter count = g_hash_table_lookup(palavras,palavra);
	if(count==NULL){
    	Counter count = malloc (sizeof(struct count));
		count -> c = g_new0 (gint, 1);
    	*count -> c = 1;
    	count -> pal = palavra;
		g_hash_table_insert(palavras, palavra, count);
	}
	else{ 
		++*(count->c); 
	}
}
%}
%x PAGE PROVLIST PROVTITLE PROVHEADER PROV AUTOR QUOTE DIALOG LINK NAME CITACOES
%%

\<page\>     											{BEGIN PAGE;}

<PAGE>{
\<title\>Provérbios\ 							{BEGIN PROVTITLE;}
\<text\ xml:.*Autor  							{BEGIN AUTOR;}
}

<PROVTITLE>{
.*/\<\/title\>                    {BEGIN PROVHEADER; title = strdup(yytext);}
}

<PROVHEADER>{
\<redirect												{BEGIN PAGE; redirect++; free(title);}
\<revision												{
																	char filename[256];
																	sprintf(filename,"proverbios/tipos/%s.html",title);
																	prov = fopen(filename,"w");
																	g_ptr_array_add(regioes,title);
																	beginPage(prov, title);
																	BEGIN PROVLIST;
									}
}

<PROVLIST>{
^\*.*\[http												{}
^\*+\ *\n													{}
^\*\*\ '''Alternativos:'''				{if(alt) {fprintf(prov, "</ul>");}; fprintf(prov, "Alternativos:\n<ul>"); alt = 1;}
^\*\*\ '''Adulteração:'''					{if(alt) {fprintf(prov, "</ul>");}; fprintf(prov, "Adulteração:\n<ul>"); alt = 1;}
^\*\*															{BEGIN PROV; beginCit(prov);}
^\*\*\*														{BEGIN PROV; beginCit(prov);}
^'''															{BEGIN PROV; beginCit(prov);}
^:'''															{BEGIN PROV; beginCit(prov);}
^::''															{BEGIN PROV; beginCit(prov);}
^\*\ \[\[.*\]\]\n									{}
^\*																{BEGIN PROV; if(alt) {fprintf(prov, "</ul>"); alt = 0;}; beginCit(prov);}
\<\/page\>                       	{BEGIN PAGE;  endPage(prov); fclose(prov);}
}

<PROV>{
{D}																{}
\n																{BEGIN PROVLIST; endCit(prov); provCount++;}
\[\[															{currentCtx = PROV; current = prov; BEGIN LINK;}
.|\n															{fprintf(prov,"%s",yytext);}
}

<AUTOR>{
\|\ *Wikipedia\ *=\ *	 						{BEGIN NAME;}
\<\/page\>                        {BEGIN PAGE;}
}

<NAME>{
.*/\n															{
																	palavras = g_hash_table_new_full(g_str_hash,g_str_equal, &freeStr, &freeCounter);
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
\<\/page\>                        {BEGIN PAGE; printAndFree(); endPage(cit); fclose(cit);}
}

<QUOTE>{
\n\ *:\ +													{BEGIN DIALOG; fprintf(cit,"<br>");}
\n		 														{BEGIN CITACOES; endCit(cit); citCount++;}
&quot;|{D}												{}
\[\[															{currentCtx = QUOTE; current = cit; BEGIN LINK;}
{P}																{fprintf(cit,"%s",yytext); incrCounter(yytext);}
[\ ,-.?!']*        								{fprintf(cit,"%s",yytext);}
}

<DIALOG>{
(\n\ *:+\ *)-+|'*&quot;		  			{endCit(cit); BEGIN AUTOR;}
{P} 															{fprintf(cit,"%s",yytext);}
[\ ,-.?!']*												{fprintf(cit,"%s",yytext); incrCounter(yytext);}
\n 																{fprintf(cit,"</br>");}
}

<LINK>{
\]\]															{BEGIN currentCtx; }
[^\|\]]*\|												{}
[^\ \]]+													{fprintf(current,"%s",yytext); if(currentCtx == QUOTE) incrCounter(yytext);}
}

<*>.|\n 													{}

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
	fprintf(f, "<ul>\n");
	g_ptr_array_foreach(list, (GFunc) function, NULL); 
	fprintf(f, "</ul>\n");
}

int main(int argc, char* argv[]){
	if(argc == 1){ 
		yylex();
	}
	else{
		yyin = fopen(argv[1], "r");
		iCit = fopen ("citacoes/index.html","w"); 
		iProv = fopen ("proverbios/index.html","w");
		if(!yyin || !iCit || !iProv) {
			printf("Erro ao abrir/criar os ficheiros necessários.\n");
			return 1;
		}
		autores = g_ptr_array_new();
		regioes = g_ptr_array_new(); 
		yylex();
		fclose(yyin);
		g_ptr_array_sort(autores,(GCompareFunc) strcompare);
		g_ptr_array_sort(regioes,(GCompareFunc) strcompare);

		fprintf(iCit, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>\n<h1>Citações</h1>\n");
		fprintf(iCit, "%d citações de %d autores.\n", citCount, autores->len);
		printIndex(iCit, autores, printRefsCits);
		fprintf(iCit, "</body>\n");
		fclose(iCit);

		fprintf(iProv, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>\n<h1>Provérbios</h1>\n");
		fprintf(iProv, "%d provérbios de %d línguas/regiões.\n", provCount, regioes->len);
		printIndex(iProv, regioes, printRefsProv);
		fprintf(iProv, "</body>\n");
		fclose(iProv);
		
		printf("%d páginas de provérbios redirecionam para outras.\n", redirect);	
	}
	return 0;
}


