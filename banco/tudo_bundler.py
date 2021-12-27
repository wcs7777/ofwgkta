from helper import salve, junte_textos, texto
import functions_procedures_bundler

def main():
	functions_procedures_bundler.main()
	salve(
		'tudo-bundle.sql',
		junte_textos([
			texto('banco.sql'),
			texto('usuario.sql'),
			texto('functions-procedures-bundle.sql'),
		]),
	)

if __name__ == '__main__':
	main()
