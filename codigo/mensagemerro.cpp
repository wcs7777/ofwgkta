#include "mensagemerro.h"

QString vazio(const QString &campo)
{
	return QString("Por favor, informe %1.").arg(campo);
}

QString repetido(const QString &campo)
{
	return QString("%1 informado já está cadastrado!").arg(campo);
}

QString inexistente(const QString &campo)
{
	return QString("%1 informado não está cadastrado!").arg(campo);
}
