#include "requisicao.h"
#include "mensagemerro.h"
#include <QDebug>

Requisicao::Requisicao(Fornecedor *fornecedor, QObject *parent) :
	Validacao(2, parent),
	m_fornecedor(fornecedor),
	m_quantidade(-1),
	m_previsto(QDate::currentDate().addDays(-2))
{
}

Requisicao::~Requisicao()
{
	delete m_fornecedor;
}

bool Requisicao::quantidadeValida(int quantidade)
{
	bool valido = false;
	m_quantidade = quantidade;

	if (quantidade > 0)
		valido = true;
	else
		err = vazio("a quantidade");

	atualizar(0, valido);

	return valido;
}

bool Requisicao::previsaoValida(const QDate &previsto)
{
	bool valido = false;
	m_previsto = previsto;

	if (QDate::currentDate() <= previsto)
		valido = true;
	else
		err = vazio("a previsão");

	atualizar(1, valido);

	return valido;
}
