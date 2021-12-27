#ifndef WFORNECEDORNOVO_H
#define WFORNECEDORNOVO_H

#include <QWidget>
#include <QHash>
#include <QStackedWidget>
#include "fornecedor.h"

namespace Ui {
class WFornecedorNovo;
}

class WFornecedorNovo : public QWidget
{
	Q_OBJECT

public:
	WFornecedorNovo(
		const QHash<QString, int> &produtos,
		QStackedWidget *menu,
		QWidget *parent = nullptr
	);
	WFornecedorNovo(
		Fornecedor *fornecedor,
		QStackedWidget *menu,
		QWidget *parent = nullptr
	);
	~WFornecedorNovo();

private slots:
	void adicionar();
	void editar();
	void voltar();
	void limparEntradas();
	void checarNome();
	void checarContato();
	void checarProduto(QString produto = QString());

private:
	void uiInicial();
	void uiInicial(
		const QString &fornecedor,
		const QString &contato,
		const QString &produto
	);
	void connectionsAdicionar();
	void connectionsEditar();

	Ui::WFornecedorNovo *ui;
	QStackedWidget *m_menu;
	QHash<QString, int> m_produtos;
	Fornecedor *m_fornecedor;
};

#endif // WFORNECEDORNOVO_H
