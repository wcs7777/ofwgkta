#ifndef WESTOQUENOVO_H
#define WESTOQUENOVO_H

#include <QWidget>
#include <QStackedWidget>
#include "produto.h"

namespace Ui {
class WEstoqueNovo;
}

class WEstoqueNovo : public QWidget
{
	Q_OBJECT

public:
	WEstoqueNovo(QStackedWidget *menu, QWidget *parent = nullptr);
	WEstoqueNovo(
		Produto *produto,
		QStackedWidget *menu,
		QWidget *parent = nullptr
	);
	~WEstoqueNovo();

private slots:
	void adicionar();
	void editar();
	void voltar();
	void limparEntradas();
	void checarNome();
	void checarPreco();

private:
	void uiInicial();
	void uiInicial(const QString &nome, double preco);
	void connectionsAdicionar();
	void connectionsEditar();

	Ui::WEstoqueNovo *ui;
	Produto *m_produto;
	QStackedWidget *m_menu;
};

#endif // WESTOQUENOVO_H
