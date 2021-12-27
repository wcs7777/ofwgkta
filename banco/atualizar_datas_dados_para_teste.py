import re
from datetime import date

def main():
	arquivo = 'tudo-com-dados-para-teste-bundle.sql'
	salvar(atualizar_datas(texto(arquivo)), arquivo)

def atualizar_datas(script):
	diferenca = date.today().toordinal() - data_criacao(script).toordinal()
	script_atualizado = script
	for data_string in set(re.findall(r"\d{4}-\d{1,2}-\d{1,2}", script)):
		data_atualizada = adicionar_dias(
			date.fromisoformat(to_isoformat(data_string)),
			diferenca
		).isoformat()
		script_atualizado = script_atualizado.replace(
			f"'{data_string}'",
			f"'{data_atualizada}'"
		)
	return script_atualizado

def data_criacao(script):
	return date.fromisoformat(
		re.search(r"Criado em: '(\d{4}-\d{1,2}-\d{1,2})'", script).group(1)
	)

def to_isoformat(data):
	[year, month, day] = data.split('-')
	if len(month) < 2:
		month = f'0{month}'
	if len(day) < 2:
		day = f'0{day}'
	return f'{year}-{month}-{day}'

def adicionar_dias(data, dias):
	return date.fromordinal(data.toordinal() + dias)

def texto(arquivo):
	with open(arquivo, 'r', encoding='utf-8') as stream:
		return stream.read()

def salvar(texto, arquivo):
	with open(arquivo, 'w', encoding='utf-8') as stream:
		stream.write(texto)

if __name__ == '__main__':
	main()
