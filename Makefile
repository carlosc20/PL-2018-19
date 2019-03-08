proverbios: proverbios.flex
	flex proverbios.flex
	cc -o proverbios lex.yy.c

install: proverbios
	cp -f proverbios /usr/local/bin/

clean:
	rm -f lex.yy.c