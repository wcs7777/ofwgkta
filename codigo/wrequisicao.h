#ifndef WREQUISICAO_H
#define WREQUISICAO_H

#include <QWidget>
#include <QHash>
#include <QStackedWidget>
#include "modeloproxy.h"

namespace Ui {
class WRequisicao;
}

class WRequisicao : public QWidget
{
	Q_OBJECT

public:
	WRequisicao(QStackedWidget *menu, QWidget *parent = nullptr);
	~WRequisicao();

private slots:
	void requisicao();
	void avulso();
	void voltar();
	void proximaTela();

private:
	void showEvent(QShowEvent*) override;
	void tamanhoColunasTabela();

	Ui::WRequisicao *ui;
	QStackedWidget *m_menu;
	ModeloProxy *modelo;
	QHash<QString, int> produtos;
};

#endif // WREQUISICAO_H
