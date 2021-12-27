#include "fornecedor.h"
#include "conectarbancodados.h"
#include "mensagemerro.h"
#include "minusculosemacento.h"
#include <QSqlQuery>
#include <QVariant>

Fornecedor::Fornecedor(const QHash<QString, int> &produtos, QObject *parent) :
	Validacao(3, parent),
	m_produtos(produtos),
	m_fornecedores(Fornecedor::nomeIdFornecedores()),
	m_id(0),
	m_nome("0"),
	m_contato("0"),
	m_produto("0")
{
}

Fornecedor::Fornecedor(
	const QHash<QString, int> &produtos,
	int id,
	const QString &nome,
	const QString &contato,
	const QString &produto,
	QObject *parent
) :
	Fornecedor(produtos, parent)
{
	m_id = id;
	nomeValido(nome);
	contatoValido(contato);
	produtoValido(produto);
}

int Fornecedor::idProduto() const
{
	return m_produtos.value(minusculoSemAcento(m_produto), 0);
}

bool Fornecedor::nomeValido(const QString &nome)
{
	bool valido = false;
	m_nome = nome;

	if (!nome.isEmpty())
	{
		if (unico(minusculoSemAcento(nome)))
			valido = true;
		else
			err = repetido("O fornecedor");
	}
	else
		err = vazio("o fornecedor");

	atualizar(0, valido);

	return valido;
}

bool Fornecedor::contatoValido(const QString &contato)
{
	bool valido = false;
	m_contato = contato;

	if (!contato.isEmpty())
		valido = true;
	else
		err = vazio("o contato");

	atualizar(1, valido);

	return valido;
}

bool Fornecedor::produtoValido(const QString &produto)
{
	bool valido = false;
	m_produto = produto;

	if (!produto.isEmpty())
	{
		if (m_produtos.contains(minusculoSemAcento(produto)))
			valido = true;
		else
			err = inexistente("O produto");
	}
	else
		err = vazio("o produto");

	atualizar(2, valido);

	return valido;
}

bool Fornecedor::unico(const QString &nome) const
{
	if (m_fornecedores.contains(nome))
		return (m_fornecedores.value(nome) == m_id);
	else
		return true;
}

QHash<QString, int> Fornecedor::nomeIdFornecedores()
{
	QSqlQuery q("CALL NomeIdFornecedores", conectarBancoDados());
	q.setForwardOnly(true);
	QHash<QString, int> lista;
	while (q.next()) lista.insert(q.value(0).toString(), q.value(1).toInt());

	return lista;
}
