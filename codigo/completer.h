#ifndef COMPLETER_H
#define COMPLETER_H

#include <QCompleter>
#include <QLineEdit>

class Completer : public QCompleter
{
public:
	Completer(const QStringList &palavras, QLineEdit *lineEdit);
};

#endif // COMPLETER_H
