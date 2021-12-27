#-------------------------------------------------
#
# Project created by QtCreator 2017-09-24T02:01:51
#
#-------------------------------------------------

QT       += core gui sql

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = ofwgkta
TEMPLATE = app

# The following define makes your compiler emit warnings if you use
# any feature of Qt which as been marked as deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if you use deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0


SOURCES += \
        main.cpp \
        wprincipal.cpp \
    westoque.cpp \
    westoquenovo.cpp \
    wrequisicao.cpp \
    wrequisicaoentrada.cpp \
    wvenda.cpp \
    wfornecedor.cpp \
    wfornecedornovo.cpp \
    wfornecedorrequisitar.cpp \
    wrelatorio.cpp \
    wstatusquantidade.cpp \
    wstatusvalidade.cpp \
    westoqueabc.cpp \
    wvendaabc.cpp \
    conectarbancodados.cpp \
    mensagemerro.cpp \
    minusculosemacento.cpp \
    validacao.cpp \
    produto.cpp \
    lote.cpp \
    fornecedor.cpp \
    requisicao.cpp \
    completer.cpp \
    modeloproxy.cpp \
    modelocustomizavel.cpp \
    itempedido.cpp \
    folhaestilo.cpp

HEADERS += \
        wprincipal.h \
    westoque.h \
    westoquenovo.h \
    wrequisicao.h \
    wrequisicaoentrada.h \
    wvenda.h \
    wfornecedor.h \
    wfornecedornovo.h \
    wfornecedorrequisitar.h \
    wrelatorio.h \
    wstatusquantidade.h \
    wstatusvalidade.h \
    westoqueabc.h \
    wvendaabc.h \
    conectarbancodados.h \
    mensagemerro.h \
    minusculosemacento.h \
    validacao.h \
    produto.h \
    lote.h \
    fornecedor.h \
    requisicao.h \
    completer.h \
    modeloproxy.h \
    modelocustomizavel.h \
    itempedido.h \
    parametros.h \
    folhaestilo.h

FORMS += \
        wprincipal.ui \
    westoque.ui \
    westoquenovo.ui \
    wrequisicao.ui \
    wrequisicaoentrada.ui \
    wvenda.ui \
    wfornecedor.ui \
    wfornecedornovo.ui \
    wfornecedorrequisitar.ui \
    wrelatorio.ui \
    wstatusquantidade.ui \
    wstatusvalidade.ui \
    westoqueabc.ui \
    wvendaabc.ui

RESOURCES += \
    imagens.qrc

RC_FILE = ofwgkta.rc
