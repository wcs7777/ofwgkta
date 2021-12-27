#include "validacao.h"

Validacao::Validacao(int totalCampos, QObject *parent) :
	QObject(parent),
	err(""),
	m_camposValidos(0),
	m_totalCampos(totalCampos)
{
	campoEstado.reserve(m_totalCampos);
	for (int i = 0; i < m_totalCampos; i++) campoEstado.insert(i, false);
	emit validar(false);
}

void Validacao::atualizar(int campo, bool estado)
{
	if (campoEstado.value(campo) != estado)
	{
		campoEstado.insert(campo, estado);
		m_camposValidos = (estado)? m_camposValidos + 1 : m_camposValidos - 1;
		emit validar(m_camposValidos == m_totalCampos);
	}
}
