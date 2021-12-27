#ifndef PRODUTO_H
#define PRODUTO_H

#include "validacao.h"
#include <QHash>
#include <QStringList>

class Produto : public Validacao
{
public:
	explicit Produto(QObject *parent = nullptr);
	Produto(
		int id,
		const QString &nome,
		double preco,
		QObject *parent = nullptr
	);
	int id() const { return m_id; }
	const QString& nome() const { return m_nome; }
	double preco() const { return m_preco; }
	bool nomeValido(const QString &nome);
	bool precoValido(double preco);
	static QHash<QString, int> nomeIdProdutos();
	static QStringList nomeProdutos();
private:
	bool unico(const QString &nome) const;

	QHash<QString, int> m_nomes;
	int m_id;
	QString m_nome;
	double m_preco;
};

#endif // PRODUTO_H
