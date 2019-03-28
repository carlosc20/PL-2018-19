ptwikiquote: wikiquote.flex
	flex wikiquote.flex
	gcc -o wikiquote lex.yy.c `pkg-config --cflags --libs glib-2.0` -lglib-2.0

install: wikiquote
	cp -f wikiquote /usr/local/bin/

clean:
	rm -f lex.yy.c

cleanout:
	rm -f citacoes/index.html citacoes/autores/* proverbios/index.html proverbios/tipos/*
