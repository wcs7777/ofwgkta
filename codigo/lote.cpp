#include "lote.h"
#include "mensagemerro.h"
#include "minusculosemacento.h"

Lote::Lote(const QHash<QString, int> &produtos, QObject *parent) :
	Validacao(3, parent),
	m_produtos(produtos),
	m_requisicao(0),
	m_produto("0"),
	m_quantidade(-1),
	m_validade(QDate::currentDate().addDays(-1))
{
}

Lote::Lote(
	const QHash<QString, int> &produtos,
	int requisicao,
	const QString &nomeProduto,
	int quantidade,
	QObject *parent
) :
	Lote(produtos, parent)
{
	m_requisicao = requisicao;
	produtoValido(nomeProduto);
	quantidadeValida(quantidade);
}

int Lote::idProduto() const
{
	return m_produtos.value(minusculoSemAcento(m_produto), 0);
}

bool Lote::produtoValido(const QString &produto)
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

	atualizar(0, valido);

	return valido;
}

bool Lote::quantidadeValida(int quantidade)
{
	bool valido = false;
	m_quantidade = quantidade;

	if (quantidade > 0)
		valido = true;
	else
		err = vazio("a quantidade");

	atualizar(1, valido);

	return valido;
}

bool Lote::validadeValida(const QDate &validade)
{
	bool valido = false;
	m_validade = validade;

	if (QDate::currentDate() < validade)
		valido = true;
	else
		err = vazio("a validade");

	atualizar(2, valido);

	return valido;
}
