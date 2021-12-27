#ifndef WESTOQUEABC_H
#define WESTOQUEABC_H

#include <QWidget>
#include <QStackedWidget>

namespace Ui {
class WEstoqueAbc;
}

class WEstoqueAbc : public QWidget
{
	Q_OBJECT

public:
	WEstoqueAbc(QStackedWidget *menu, QWidget *parent = nullptr);
	~WEstoqueAbc();

private slots:
	void voltar();

private:
	void showEvent(QShowEvent*) override;
	void tamanhoColunasTabela();

	Ui::WEstoqueAbc *ui;
	QStackedWidget *m_menu;
};

#endif // WESTOQUEABC_H
