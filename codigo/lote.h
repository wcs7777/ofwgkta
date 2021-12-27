#ifndef LOTE_H
#define LOTE_H

#include "validacao.h"
#include <QDate>
#include <QHash>

class Lote : public Validacao
{
public:
	Lote(const QHash<QString, int> &produtos, QObject *parent = nullptr);
	Lote(
		const QHash<QString, int> &produtos,
		int requisicao,
		const QString &nomeProduto,
		int quantidade,
		QObject *parent = nullptr
	);
	int requisicao() const { return m_requisicao; }
	const QString& nomeProduto() const { return m_produto; }
	int quantidade() const { return m_quantidade; }
	const QDate& validade() const { return m_validade; }
	int idProduto() const;
	bool produtoValido(const QString &produto);
	bool quantidadeValida(int quantidade);
	bool validadeValida(const QDate &validade);

private:
	QHash<QString, int> m_produtos;
	int m_requisicao;
	QString m_produto;
	int m_quantidade;
	QDate m_validade;
};

#endif // LOTE_H
