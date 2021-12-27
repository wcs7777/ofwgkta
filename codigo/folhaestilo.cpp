#include "folhaestilo.h"
#include <QDebug>
#include <QFile>

QString folhaEstilo()
{
	QString folha("");
	QFile file("estilo_externo.css");

	if (!file.exists())
		file.setFileName(":/icones/estilo.css");

	if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text))
		folha = file.readAll();

	if (folha.isEmpty())
		qDebug() << "Nenhuma folha de estilo encontrada para o app!";

	return folha;
}

QString folhaEstiloVenda()
{
	QString folha("");
	QFile file("venda_estilo_externo.css");

	if (!file.exists())
		file.setFileName(":/icones/venda_estilo.css");

	if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text))
		folha = file.readAll();

	if (folha.isEmpty())
		qDebug() << "Nenhuma folha de estilo encontrada para Venda!";

	return folha;
}
