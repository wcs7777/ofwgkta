#ifndef WESTOQUE_H
#define WESTOQUE_H

#include <QWidget>
#include <QStackedWidget>
#include "modeloproxy.h"

namespace Ui {
class WEstoque;
}

class WEstoque : public QWidget
{
	Q_OBJECT

public:
	WEstoque(QStackedWidget *menu, QWidget *parent = nullptr);
	~WEstoque();

private slots:
	void entrada();
	void novo();
	void editar();
	void proximaTela();

private:
	void showEvent(QShowEvent*) override;
	void tamanhoColunasTabela();

	Ui::WEstoque *ui;
	QStackedWidget *m_menu;
	ModeloProxy *modelo;
};

#endif // WESTOQUE_H
