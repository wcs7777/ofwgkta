#ifndef WRELATORIO_H
#define WRELATORIO_H

#include <QWidget>
#include <QStackedWidget>

namespace Ui {
class WRelatorio;
}

class WRelatorio : public QWidget
{
	Q_OBJECT

public:
	WRelatorio(QStackedWidget *menu, QWidget *parent = nullptr);
	~WRelatorio();

private slots:
	void statusQuantidade();
	void statusValidade();
	void estoqueAbc();
	void vendaAbc();
	void proximaTela();

private:
	Ui::WRelatorio *ui;
	QStackedWidget *m_menu;
};

#endif // WRELATORIO_H
