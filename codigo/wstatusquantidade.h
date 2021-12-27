#ifndef WSTATUSQUANTIDADE_H
#define WSTATUSQUANTIDADE_H

#include <QWidget>
#include <QStackedWidget>

namespace Ui {
class WStatusQuantidade;
}

class WStatusQuantidade : public QWidget
{
	Q_OBJECT

public:
	WStatusQuantidade(QStackedWidget *menu, QWidget *parent = nullptr);
	~WStatusQuantidade();

private slots:
	void voltar();

private:
	void showEvent(QShowEvent*) override;
	void tamanhoColunasTabela();

	Ui::WStatusQuantidade *ui;
	QStackedWidget *m_menu;
};

#endif // WSTATUSQUANTIDADE_H
