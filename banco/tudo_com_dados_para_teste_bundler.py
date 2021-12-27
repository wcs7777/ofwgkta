from helper import salve, junte_textos, texto
import tudo_bundler

def main():
	tudo_bundler.main()
	salve(
		'tudo-com-dados-para-teste-bundle.sql',
		junte_textos([
			texto('tudo-bundle.sql'),
			texto('dados-para-teste.sql'),
		]),
	)

if __name__ == '__main__':
	main()
