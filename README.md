<p align="center" border-bottom="none">
	<img width="150" src="https://user-images.githubusercontent.com/79942050/147503882-13af0079-6a0d-4429-bdf5-cb9f531b62ca.png">
</p>
<h1 align="center" border-bottom="none">OFWGKTA</h1>
<h2 align="center" border-bottom="none"><em>Sistema Gerenciador de Estoque</em></h2>

## Tabela de conteúdos
1. [Sobre o projeto](#sobre-o-projeto)
2. [Tecnologias](#tecnologias)
3. [Funcionalidades](#funcionalidades)
4. [Como rodar](#como-rodar)
5. [Demonstração](#demonstração)
6. [Autor](#autor)

***

## Sobre o projeto
OFWGKTA é um sistema gerenciador de estoque para mercados com o foco em administrar a validade dos produtos para evitar o desperdício dos mesmos.

***

## Propósito
O projeto foi feito como conclusão do **curso técnico de informática da ETEC no ano de 2017**. Como poderia ser escolhida qualquer tecnologia para o projeto, escolhi [C++][1] para tal pois na época estava estudando-a por conta própria e queria consolidar meus conhecimentos na linguagem com um projeto. **Usei os conhecimentos que possuía na época, e hoje acredito que escrevo códigos melhores do que este.**

***

## Funcionalidades
- Cadastro de produtos
- Cadastro de lotes
- Cadastro de fornecedores
- Cadastro de requisições de produtos
- Venda de produtos
- Relatório com status de validade dos produtos
- Relatório com status de quantidade dos produtos
- Relatório com a [curva ABC][2] da venda dos produtos
- Relatório com a [curva ABC][2] dos produtos em estoque

***

## Tecnologias
- [C++][1]
- [Qt (4.5)][3]
- [MySQL][4]

***

## Como rodar
Para testar o projeto é necessário criar o banco de dados no [MySQL][4] com o arquivo [banco/tudo-bundle.sql](banco/tudo-bundle.sql) ou [banco/tudo-com-dados-para-teste-bundle.sql](banco/tudo-com-dados-para-teste-bundle.sql) se quiser popular o banco com dados para teste. Há um script em python para atualizar as datas dos dados de teste em [banco/atualizar_datas_dados_para_teste.py](banco/tudo-com-dados-para-teste-bundle.sql), basta executá-lo para atualizar as datas no arquivo banco/tudo-com-dados-para-teste-bundle.sql.  
Para executar o sistema, caso esteja utilizando o SO Windows há um executável em [deploy/ofwgkta.exe](deploy/ofwgkta.exe).
Para compilar o sistema a partir do código fonte é necessário baixar o [Qt Creator 5.x.x][5] ou 4.x.x caso o encontre, e abrir o arquivo em /codigo/ofwgkta.pro.

***

## Demonstração
[![Demonstração do sistema](https://img.youtube.com/vi/6fJX_y2OGMU/hqdefault.jpg)](https://www.youtube.com/watch?v=6fJX_y2OGMU)

***

## Autor
Willian Carlos  
<wcs7777git@gmail.com>  
<https://www.linkedin.com/in/williancarlosdasilva/>

[1]: https://www.cplusplus.com/
[2]: https://pt.wikipedia.org/wiki/Curva_ABC
[3]: https://wiki.qt.io/About_Qt
[4]: https://www.mysql.com/
[5]: https://www.qt.io/download-qt-installer?hsCtaTracking=99d9dd4f-5681-48d2-b096-470725510d34%7C074ddad0-fdef-4e53-8aa8-5e8a876d6ab4
