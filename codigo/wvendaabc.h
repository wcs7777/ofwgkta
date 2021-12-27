#ifndef WVENDAABC_H
#define WVENDAABC_H

#include <QWidget>
#include <QStackedWidget>

namespace Ui {
class WVendaAbc;
}

class WVendaAbc : public QWidget
{
	Q_OBJECT

public:
	WVendaAbc(QStackedWidget *menu, QWidget *parent = nullptr);
	~WVendaAbc();

private slots:
	void voltar();

private:
	void showEvent(QShowEvent*) override;
	void tamanhoColunasTabela();

	Ui::WVendaAbc *ui;
	QStackedWidget *m_menu;
};

#endif // WVENDAABC_H
