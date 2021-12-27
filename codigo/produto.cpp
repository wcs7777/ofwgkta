#include "produto.h"
#include "conectarbancodados.h"
#include "mensagemerro.h"
#include "minusculosemacento.h"
#include <QSqlQuery>
#include <QVariant>

Produto::Produto(QObject *parent) :
	Validacao(2, parent),
	m_nomes(Produto::nomeIdProdutos()),
	m_id(0),
	m_nome("0"),
	m_preco(-1.0)
{
}

Produto::Produto(int id, const QString &nome, double preco, QObject *parent) :
	Produto(parent)
{
	m_id = id;
	nomeValido(nome);
	precoValido(preco);
}

bool Produto::nomeValido(const QString &nome)
{
	bool valido = false;
	m_nome = nome;

	if (!nome.isEmpty())
	{
		if (unico(minusculoSemAcento(nome)))
			valido = true;
		else
			err = repetido("O produto");
	}
	else
		err = vazio("o produto");

	atualizar(0, valido);

	return valido;
}

bool Produto::precoValido(double preco)
{
	bool valido = false;
	m_preco = preco;

	if (preco > 0.00)
		valido = true;
	else
		err = vazio("o preço");

	atualizar(1, valido);

	return valido;
}

bool Produto::unico(const QString &nome) const
{
	if (m_nomes.contains(nome))
		return (m_nomes.value(nome) == m_id);
	else
		return true;
}

QHash<QString, int> Produto::nomeIdProdutos()
{
	QSqlQuery q("CALL NomeIdProdutos", conectarBancoDados());
	q.setForwardOnly(true);
	QHash<QString, int> lista;
	while (q.next()) lista.insert(q.value(0).toString(), q.value(1).toInt());

	return lista;
}

QStringList Produto::nomeProdutos()
{
	QSqlQuery q("CALL NomeProdutos", conectarBancoDados());
	q.setForwardOnly(true);
	QStringList lista;
	while (q.next()) lista.append(q.value(0).toString());

	return lista;
}
