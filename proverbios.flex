%option yylineno
%option noyywrap

%x PAGE AUTOR 
%%

<*>\<page\>     							  {BEGIN PAGE;}
<*>.|\n 										{}
<PAGE>{					
.*\<text\ xml:.*Autor  				      	  {BEGIN AUTOR;}
.*|\n										  {}

}

<AUTOR>{
\|\ *Wikipedia\ *=.*\n 			{int i = 0;
									while(yytext[i] != '=')
										i++;
									while(yytext[i+1] == ' ')
										i++;
								printf("%d %s\n",yylineno,yytext+i+1);}
\*\ ?&quot.*&quot                {printf("%d %s\n",yylineno,yytext);}
\<\/page\>                        {BEGIN PAGE;}
} 
%%
int main(int argc, char* argv[]){
	if(argc == 1) 
		yylex();
	else{
		yyin = fopen(argv[1], "r");
		yylex();
		fclose(yyin);
	}
	return 0;
}
