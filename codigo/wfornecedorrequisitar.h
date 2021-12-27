#ifndef WFORNECEDORREQUISITAR_H
#define WFORNECEDORREQUISITAR_H

#include <QWidget>
#include <QStackedWidget>
#include "requisicao.h"

namespace Ui {
class WFornecedorRequisitar;
}

class WFornecedorRequisitar : public QWidget
{
	Q_OBJECT

public:
	WFornecedorRequisitar(
		Requisicao *requisicao,
		QStackedWidget *menu,
		QWidget *parent = 0
	);
	~WFornecedorRequisitar();

private slots:
	void adicionar();
	void voltar();
	void checarQuantidade();
	void checarPrevisao();

private:
	void uiInicial();

	Ui::WFornecedorRequisitar *ui;
	Requisicao *m_requisicao;
	QStackedWidget *m_menu;
};

#endif // WFORNECEDORREQUISITAR_H
