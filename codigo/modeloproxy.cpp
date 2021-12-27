#include "modeloproxy.h"
#include <QSqlRecord>
#include <QDebug>

ModeloProxy::ModeloProxy(ModeloCustomizavel *modelo, QObject *parent) :
	QSortFilterProxyModel(parent),
	m_modelo(modelo)
{
	setSourceModel(m_modelo);
}

ModeloProxy::ModeloProxy(
	ModeloCustomizavel *modelo,
	int colunaFiltrada,
	QObject *parent
) :
	ModeloProxy(modelo, parent)
{
	setFilterKeyColumn(colunaFiltrada);
	setFilterCaseSensitivity(Qt::CaseInsensitive);
}

QVariant ModeloProxy::valor(const QModelIndex &index) const
{
	return m_modelo->valor(mapToSource(index));
}

QVariant ModeloProxy::valor(int linha, int coluna) const
{
	return valor(index(linha, coluna));
}
