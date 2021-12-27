from helper import junte_textos, texto, salve

def main():
	salve(
		'functions-procedures-bundle.sql',
		junte_textos([
			'DELIMITER //\n',
			texto('funcoes.sql'),
			texto('adicionar.sql'),
			texto('editar.sql'),
			texto('selecionar.sql'),
			'DELIMITER ;\n',
		])
	)

if __name__ == '__main__':
	main()
