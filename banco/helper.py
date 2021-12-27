from os import walk

def junte_textos(textos):
	return '\n'.join(textos)

def junte_arquivos_diretorios(diretorios):
	lista = []
	lista.append('DELIMITER $$\n')
	for diretorio in diretorios:
		lista.append(junte_arquivos_diretorio(diretorio))
	lista.append('DELIMITER ;\n')
	return '\n'.join(lista)

def junte_arquivos_diretorio(diretorio):
	lista = []
	for arquivo in arquivos(f'./{diretorio}'):
		lista.append(texto(f'./{diretorio}/{arquivo}'))
	return '\n'.join(lista)

def arquivos(caminho):
	for root, dirs, files in walk(caminho):
		return [f for f in files if f.endswith('.sql')]

def texto(arquivo):
	with open(arquivo, 'r') as stream:
		return stream.read()

def salve(arquivo, texto):
	with open(arquivo, 'w') as stream:
		stream.write(texto)
