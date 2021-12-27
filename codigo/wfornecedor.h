#ifndef WFORNECEDOR_H
#define WFORNECEDOR_H

#include <QWidget>
#include <QHash>
#include <QStackedWidget>
#include "modeloproxy.h"

namespace Ui {
class WFornecedor;
}

class WFornecedor : public QWidget
{
	Q_OBJECT

public:
	WFornecedor(QStackedWidget *menu, QWidget *parent = nullptr);
	~WFornecedor();

private slots:
	void requisitar();
	void novo();
	void editar();
	void proximaTela();

private:
	void showEvent(QShowEvent*) override;
	void tamanhoColunasTabela();

	Ui::WFornecedor *ui;
	QStackedWidget *m_menu;
	ModeloProxy *modelo;
	QHash<QString, int> produtos;
};

#endif // WFORNECEDOR_H
