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
//[’–] 8090
%}
%option yylineno
%option noyywrap

D 		('|\*|«|»|’|”|“|\"|&quot;|\{|\})
P 		[^\ \&,.?"!\n\[]+
%{
FILE *cit, *prov, *iCit, *iProv, *geral;
FILE *current;

int currentCtx;
char* title;

int alt = 0;
int g = 0;

int redirect = 0;
int provCount = 0;
int citCount = 0;
int count = 0;
int words = 0;
int big = 0;
int small = 256;
int totalWords = 0;

void beginCit(FILE* file) {
	fprintf(file,"<li>“");
}

void endCit(FILE* file) {
	fprintf(file,"”</li>\n");
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
  fprintf(cit,"%d - %s", *value->c, value->pal);
  fprintf(cit,"<br>");
  return 0;
}

void printAndFree( ){
    fprintf(cit,"<h3>Palavras ordenadas por número de ocorrências:</h3>");
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
%x PAGE PROVLIST PROVTITLE PROVHEADER PROV AUTOR QUOTE DIALOG LINK INSIDEL NAME CITACOES
%%

\<page\>     									{BEGIN PAGE;}

<PAGE>{
\<title\>Provérbios\ 							{BEGIN PROVTITLE;}
\<text\ xml:.*Autor  							{g=0; BEGIN AUTOR;}
\*\ ?('*(&quot;)+'*\ ?|\“)        {current = geral; g=1; BEGIN QUOTE;}
}

<PROVTITLE>{
.*/\<\/title\>                                  {BEGIN PROVHEADER; title = strdup(yytext);}
}

<PROVHEADER>{
\<redirect										{BEGIN PAGE; redirect++; free(title);}
\<revision										{
                                                char filename[256];
                                                sprintf(filename,"proverbios/tipos/%s.html",title);
                                                prov = fopen(filename,"w");
                                                g_ptr_array_add(regioes,title);
                                                beginPage(prov, title);
                                                count = 0; totalWords = 0; big = 0; small = 256;
                                                BEGIN PROVLIST;
                                                }
}

<PROVLIST>{
^\*.*\[http										{}
^\*+\ *\n										{}
^\*\*\ '''Alternativos:'''				        {if(alt) {fprintf(prov, "</ul>");}; fprintf(prov, "Alternativos:\n<ul>"); alt = 1;}
^\*\*\ '''Adulteração:'''					    {if(alt) {fprintf(prov, "</ul>");}; fprintf(prov, "Adulteração:\n<ul>"); alt = 1;}
^\*+|:*'+	   										{BEGIN PROV; beginCit(prov); words = 0;}
^\*\ \[\[.*\]\]\n								{}
^\*												{BEGIN PROV; if(alt) {fprintf(prov, "</ul>"); alt = 0;}; beginCit(prov); words = 0;}
\<\/page\>                       	            {
                                                BEGIN PAGE; 
                                                if(count > 0) {
                                                    fprintf(prov, "<h3>Provérbios: %d<br>\n \
                                                    Número de palavras:<ul>\n \
                                                    <li>total-> %d</li>\n \
                                                    <li>médio-> %g</li>\n \
                                                    <li>maior-> %d</li>\n \
                                                    <li>menor-> %d</li>\n</ul></h3>",
                                                    count, totalWords, (float)totalWords/count, big, small); 
                                                    provCount += count;
                                                } 
                                                endPage(prov);
                                                fclose(prov);
                                                }
}

<PROV>{
&quot;										{}												
\n												{
                                                BEGIN PROVLIST; 
                                                endCit(prov); 
                                                count++; 
                                                totalWords += words;
                                                if(words > big) big = words;
                                                if(words < small) small = words;
                                                }
\[\[											{currentCtx = PROV; current = prov; BEGIN LINK;}
{P}												{fprintf(prov,"%s",yytext); words++;}
[\ ,.?!]*        								{fprintf(prov,"%s",yytext);}
}

<AUTOR>{
\|\ *Wikipedia\ *=\ *	 													{BEGIN NAME;}
\<\/page\>                                      {BEGIN PAGE;}
}

<NAME>{
.*/\n											{
                                                palavras = g_hash_table_new_full(g_str_hash,g_str_equal, &freeStr, &freeCounter);
                                                char filename[256];
                                                char* name = strdup(yytext);
                                                g_ptr_array_add(autores,name);
                                                sprintf(filename,"citacoes/autores/%s.html",name);
                                                cit = fopen(filename,"w");
                                                beginPage(cit, name);
                                                count = 0; totalWords = 0; big = 0; small = 256;
                                                current = cit;
                                                BEGIN CITACOES;
                                                }
}

<CITACOES>{
\*\ ?('*(&quot;)+'*\ ?|\“)      	            {BEGIN QUOTE; beginCit(current); words = 0;}
\<\/page\>                                      {
                                                BEGIN PAGE; 
                                                if(count > 0 && g==0) {
                                                    fprintf(cit, "<h3>Citações: %d<br>\n \
                                                    Número de palavras:<ul>\n \
                                                    <li>total-> %d</li>\n \
                                                    <li>médio-> %g</li>\n \
                                                    <li>maior-> %d</li>\n \
                                                    <li>menor-> %d</li>\n</ul></h3>",
                                                    count, totalWords, (float)totalWords/count, big, small); 
                                                    printAndFree();
                                                    citCount += count;
                                                    endPage(cit); 
                                                    fclose(cit);
                                                  } 
                                                }
}

<QUOTE>{
\n\ *:\ +										{BEGIN DIALOG; fprintf(current,"<br>");}
\n		 										{
                                                BEGIN CITACOES;
                                                endCit(current); 
                                                count++; 
                                                totalWords += words;
                                                if(words > big) big = words;
                                                if(words < small) small = words;
                                                }
&quot;|{D}										{}
\[\[											{currentCtx = QUOTE ; BEGIN LINK;}
{P}												{fprintf(current,"%s",yytext); if(g==0) incrCounter(yytext); words++;}
[\ ,-.?!']*        								{fprintf(current,"%s",yytext);}
}

<DIALOG>{
(\n\ *:+\ *)-+|'*&quot;		 {endCit(current); BEGIN CITACOES;}
{P} 											{fprintf(current,"%s",yytext);}
[\ ,-.?!']*								{fprintf(current,"%s",yytext); if(g==0) incrCounter(yytext); words++;}
\n 												{fprintf(current,"</br>");}
}

<LINK>{
\]\]											  {BEGIN currentCtx;}
[^\ ]*\|									  {}
[^\ \|\]]+									{fprintf(current,"%s",yytext); if(currentCtx == QUOTE && g==0) incrCounter(yytext);}
}

<*>.|\n 										{}

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

int printGeral(){
  fprintf(iCit, "<li><a href=\"autores/geral.html\">geral</a></li>\n");
}

int main(int argc, char* argv[]){
	if(argc == 1){ 
		yylex();
	}
	else{
		yyin = fopen(argv[1], "r");
		iCit = fopen ("citacoes/index.html","w"); 
		iProv = fopen ("proverbios/index.html","w");
    geral = fopen ("citacoes/autores/geral.html","w");
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
		fprintf(iCit, "<h3>%d citações de %d autores.</h3>\n", citCount, autores->len);
    printGeral();
		printIndex(iCit, autores, printRefsCits);
		fprintf(iCit, "</body>\n");
		fclose(iCit);
    fclose(geral);

		fprintf(iProv, "<head>\n\t<meta charset='UTF-8'>\n</head>\n<body>\n<h1>Provérbios</h1>\n");
		fprintf(iProv, "<h3>%d provérbios de %d línguas/regiões.</h3>\n", provCount, regioes->len);
		printIndex(iProv, regioes, printRefsProv);
		fprintf(iProv, "</body>\n");
		fclose(iProv);
		
		printf("%d páginas de provérbios redirecionam para outras.\n", redirect);	
	}
	return 0;
}


