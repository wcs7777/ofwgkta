#ifndef WSTATUSVALIDADE_H
#define WSTATUSVALIDADE_H

#include <QWidget>
#include <QStackedWidget>

namespace Ui {
class WStatusValidade;
}

class WStatusValidade : public QWidget
{
	Q_OBJECT

public:
	WStatusValidade(QStackedWidget *menu, QWidget *parent = nullptr);
	~WStatusValidade();

private slots:
	void voltar();

private:
	void showEvent(QShowEvent*) override;
	void tamanhoColunasTabela();

	Ui::WStatusValidade *ui;
	QStackedWidget *m_menu;
};

#endif // WSTATUSVALIDADE_H
