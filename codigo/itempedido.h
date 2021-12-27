#ifndef ITEMPEDIDO_H
#define ITEMPEDIDO_H

#include <QObject>
#include <QDoubleSpinBox>
#include <QIcon>
#include <QLineEdit>
#include <QMap>
#include <QPushButton>
#include <QSpinBox>
#include <QTableWidget>

class ItemPedido : public QObject
{
	Q_OBJECT
public:
	ItemPedido(
		QTableWidget *tabela,
		const QMap<QString, int> &produtos_nomeId,
		const QMap<int, int> &produtos_idQuantidade
	);

	QPushButton* carrinho() const { return pbCarrinho; }
	int quantidade() const { return inQuantidade->value(); }

	int idProduto() const
	{
		return m_produtos_nomeId.value(inProduto->text(), 0);
	}

	bool valido() const { return (idProduto() != 0); }

	double precoTotal() const
	{
		return outTotal->value();
	}

	void adicionarProdutos(int quantidade);

private slots:
	void checarProduto(QString produto = QString());
	void atualizarTotal(int quantidade);
	void desativar();

private:
	void alinhamentos();
	void inserirLinha(QTableWidget *tabela);
	void uiInicial();
	void connections();

	const QIcon iconeAdicionar;
	const QIcon iconeRemover;
	QMap<QString, int> m_produtos_nomeId;
	QMap<int, int> m_produtos_idQuantidade;
	QLineEdit *inProduto;
	QDoubleSpinBox *outPreco;
	QSpinBox *inQuantidade;
	QDoubleSpinBox *outTotal;
	QPushButton *pbCarrinho;
};

#endif // ITEMPEDIDO_H
