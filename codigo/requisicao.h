#ifndef REQUISICAO_H
#define REQUISICAO_H

#include "validacao.h"
#include "fornecedor.h"
#include <QDate>

class Requisicao : public Validacao
{
public:
	Requisicao(Fornecedor *fornecedor, QObject *parent = nullptr);
	~Requisicao();
	const Fornecedor* fornecedor() const { return m_fornecedor; }
	int quantidade() const { return m_quantidade; }
	const QDate& previsto() const { return m_previsto; }
	bool quantidadeValida(int quantidade);
	bool previsaoValida(const QDate &previsto);

private:
	Fornecedor *m_fornecedor;
	int m_quantidade;
	QDate m_previsto;
};

#endif // REQUISICAO_H
