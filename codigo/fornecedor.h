#ifndef FORNECEDOR_H
#define FORNECEDOR_H

#include "validacao.h"
#include <QHash>

class Fornecedor : public Validacao
{
public:
	Fornecedor(const QHash<QString, int> &produtos, QObject *parent = nullptr);
	Fornecedor(
		const QHash<QString, int> &produtos,
		int id,
		const QString &nome,
		const QString &contato,
		const QString &produto,
		QObject *parent = nullptr
	);
	int id() const { return m_id; }
	const QString& nome() const { return m_nome; }
	const QString& contato() const { return m_contato; }
	const QString& nomeProduto() const { return m_produto; }
	int idProduto() const;
	bool nomeValido(const QString &nome);
	bool contatoValido(const QString &contato);
	bool produtoValido(const QString &produto);
	static QHash<QString, int> nomeIdFornecedores();

private:
	bool unico(const QString &nome) const;

	QHash<QString, int> m_produtos;
	QHash<QString, int> m_fornecedores;
	int m_id;
	QString m_nome;
	QString m_contato;
	QString m_produto;
};

#endif // FORNECEDOR_H
