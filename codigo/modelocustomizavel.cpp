#include "modelocustomizavel.h"
#include <QPersistentModelIndex>
#include <QSqlRecord>

ModeloCustomizavel::ModeloCustomizavel(
	const QSqlQuery &query,
	QObject *parent,
	const QList<QVariant> &alinhamentos,
	const CampoCondicaoCor &colors
) :
	QAbstractTableModel(parent),
	m_query(query),
	m_alinhamentos(alinhamentos),
	m_cores(colors)
{
	popular();
	int colunas = columnCount();

	for (int i = m_alinhamentos.size(); i < colunas; i++)
		m_alinhamentos.append(QVariant(Qt::AlignCenter));
}

QVariant ModeloCustomizavel::data(const QModelIndex &index, int role) const
{
	if (index.isValid())
	{
		switch (role)
		{
			case Qt::DisplayRole:
				return registros[index.row()].value(index.column());

			case Qt::TextAlignmentRole:
				return m_alinhamentos[index.column()];

			case Qt::TextColorRole:
				if (m_cores.first == index.column())
					return m_cores.second.value(
						registros[index.row()]
							.value(m_cores.first)
							.toString()
					);
		}
	}

	return QVariant();
}

QVariant ModeloCustomizavel::headerData(
	int section,
	Qt::Orientation orientation,
	int role
) const
{
	if (0 <= section && section < columnCount()
	&& orientation == Qt::Horizontal)
	{
		switch (role)
		{
			case Qt::DisplayRole:
				return registros.first().fieldName(section);

			case Qt::TextAlignmentRole:
				return m_alinhamentos[section];
		}
	}

	return QVariant();
}

int ModeloCustomizavel::columnCount(const QModelIndex &) const
{
	return (rowCount() > 0)? registros.first().count() : 0;
}

int ModeloCustomizavel::rowCount(const QModelIndex&) const
{
	return (!registros.isEmpty())? registros.size() : 0;
}

QVariant ModeloCustomizavel::valor(const QModelIndex &index) const
{
	if (index.isValid())
		return registros[index.row()].value(index.column());
	else
		return QVariant();
}

QVariant ModeloCustomizavel::valor(int row, int column) const
{
	return valor(index(row, column));
}

void ModeloCustomizavel::atualizar()
{
	emit layoutAboutToBeChanged();
	popular();
	emit layoutChanged();
}

int ModeloCustomizavel::indiceCampo(const QString &campo) const
{
	return (!registros.isEmpty())? registros.first().indexOf(campo) : -1;
}

void ModeloCustomizavel::popular()
{
	m_query.exec();
	m_query.setForwardOnly(true);
	registros.clear();
	while (m_query.next()) registros.append(m_query.record());
}
